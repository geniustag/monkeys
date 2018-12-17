class Etransaction < ActiveRecord::Base

  STATUS_TEXT = {
    pending: "执行中",
    fail: "失败",
    success: "成功",
    exception: "异常"
  }

  enum tran_type: {
    buy: 0,
    buyByAff: 1,
    withdraw: 2,
    withdrawAll: 3
  }

  enum status: {
    pending: -1,
    fail: 0,
    success: 1,
    exception: 2
  }

  scope :revert, -> {order("created_at DESC")}

  def self.create_with_txid(tx_hash, ps = {})
    Etransaction.find_by(tx_hash: tx_hash) and return "Alreay Exsit"
    tx_ps = EthereumRpc.eth_getTransactionByHash([tx_hash])
    tx_ps.try(:symbolize_keys!)
    return "invalid Game Address" if Rails.env.production? && tx_ps[:to].to_s.downcase != "{{wowwin_contract_address}}"
    e = create({efrom: tx_ps[:from], eto: tx_ps[:to], amount: tx_ps[:value], meth: ps[:tran_type], parent_id: tx_ps[:parent_id] || 0,
               extra_info: tx_ps.to_json, tx_hash: tx_hash, token: "eth", tran_type: ps[:tran_type] || "buy"}.merge(ps))
    e.created_at = Time.now
    e.save
    e
  end

  def from
    efrom.try(:downcase)
  end

  def to
    (eto || tx_data["to"]).try(:downcase)
  end

  def short_from
    [from[0, 8], from[-4,4]].join("...")
  end

  def short_to
    tt = to || tx_data["to"]
    [tt[0, 8], tt[-4,4]].join("...")
  end

  def gas
    tx_data["gas"].to_s.hex
  end

  def gas_price
    tx_data["gasPrice"].to_s.hex
  end

  def gas_price_gwei
    BigDecimal.new(gas_price.to_i) / BigDecimal.new(10 ** 9)
  end

  def check_status
    res = EthereumRpc.eth_getTransactionReceipt([tx_hash])
    res.nil? and return
    n = res["status"].hex
    !pending? and return
    if n == 1 
      success!
    elsif n == 0 
      self.fail!
    end
  end

  def status_text
    STATUS_TEXT[status.to_sym]
  end

  def format_data(address)
    {
      date: created_at.strftime('%d/%m/%Y'),
      type: category(address),
      amount: value,
      address: address.downcase == from ? to : from,
      status: status_text
    }
  end

  def self.special_display_attrs
    %w(tx_hash)
  end
end
