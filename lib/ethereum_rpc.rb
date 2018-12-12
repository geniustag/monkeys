module EthereumRpc
  extend self
  PEER = URI.parse(HOSTS[:ether])
  HEADERS = {"Accept"=>"application/json", "Content-Type"=>"application/json;charset=utf-8"} 
  BASE_PARAMS = {jsonrpc:"2.0",method: "eth_getBalance", params: ["latest"], id: Time.now.to_f.to_s.split(".").join}
  FLOAT_ROUND = 8
  DEFAULT_GAS_PRICE = 9 * (10 ** 9)
  DEFAULT_GAS_LIMIT = 100000

  RPC_METHODS_WITH_NAMES = {
    eth_getBalance: "余额",
    eth_sendTransaction: "转账"
  }

  RPC_METHODS = File.read("config/rpc_eth_methods.txt").split.map(&:to_sym)

  def post(params)
    res = {}
    begin
      node_ps = BASE_PARAMS.deep_merge(params).to_json
      ap node_ps
      Timeout.timeout(10) { res = JSON.parse(UrlTool.http_post_request(PEER, node_ps)) }
    rescue 
      res["error"] = {code: "103", message: "请求失败，请稍后重试！"}
    end
    res["result"] || res["error"]
  end

  RPC_METHODS.each do |m|
    define_method m do |ps = []|
      EthereumRpc.post(method: m, params: ps.presence || [])
    end
  end

  def new_account(passwd)
    personal_newAccount([passwd.to_s])
  end

  def import_account(private_key, passwd)
    personal_importRawKey([private_key, passwd])
  end

  def keystore_content(address)
    TcpServer::Client.new(address[2,100]).get_keystore
  end

  def get_private_key(address, passwd)
    Eth::Key.decrypt(keystore_content(address), passwd).private_hex # rescue ""
  end

  def balance_of(address, symbol = "eth", origin_decimal = false)
    symbol = symbol.downcase
    b = 0
    if symbol != "eth"
      b = eth_call([contract_method_params(nil, symbol, :balanceOf, address), "latest"])
    else
      b = eth_getBalance([address, "latest"])
    end
    b_key = "#{address}:#{symbol}:balance"
    bal = b.is_a?(Hash)  ? (RedisHelper.get(b_key).presence || 0) : b
    RedisHelper.cache!(b_key, bal)
    origin_decimal ? bal : to_coin_number(bal)
  end

  alias :safe_getbalance :balance_of

  def balances
    %w(eth gst).map{|a| balance_of(geth_account, a) }
  end

  def call_contract(token, _method, *ps)
    invork_contract("", token, _method, *ps).last
  end

 def send_transaction(password, tx_ps = {}, token = "eth")
    token = token.downcase
    from = tx_ps[:from]
    res = nil 
     if token == "eth"
      ps = convert_tx_params(tx_ps)
    else
      ps = tx_ps = token_tx_params(token, tx_ps)
    end 
    ps[:gas].hex < 40000 and return [false, "当前以太坊网络拥堵，gas过低可能导致转账失败，请适当提高转账费用"]
    !unlock_account(from, password) and return [false, "密码错误"]                                                                                             
    EthereumRpc.start_send(ps, token, tx_ps)
  end 

  def start_send(ps, token, tx_ps)
    res = eth_sendTransaction([ps])
    Etransaction.create_with_tx(token, res, tx_ps) if res.is_a?(String)
  end 

  def unlock_account(address, password = nil)
    _address = address
    _address, password = address[:owner], address[:password] if address.is_a?(Hash)
    personal_unlockAccount([_address, password, 10]) == true
  end

  def invork_contract(password, token, _method, *ps)
    token = token.downcase
    res = nil
    if is_call?(token, _method)
      res = eth_call([contract_method_params(nil, token, _method, *ps), "latest"])
    else
      validate_passwd = false
      if password.is_a?(Hash)
        validate_passwd = unlock_account(password[:owner], password[:password]) 
      else
        validate_passwd = unlock_account(CONTRACT_OWNERS[token.to_s], password)
      end
      validate_passwd != true and return [false, "密码错误"]
      res = eth_sendTransaction([tx_ps = contract_method_params(password, token, _method, *ps)])
      Etransaction.create_with_contract_method(_method, token, res, tx_ps) if res.is_a?(String)
    end
    [res.is_a?(String), res]
  end

  def is_call?(token, _method)
    %w(paused balanceOf totalSupply allowance).include?(_method.to_s) and return true
    token.downcase == "gst" and return %w(owner frozenAccount frozenAccountTokens).include?(_method.to_s)
    false
  end

  def admin_send_tx(tx_ps = {})
    tx_ps.merge!(from: geth_account)
    res = eth_sendTransaction([convert_tx_params(tx_ps)])
    [res.is_a?(String), res]
  end

  def send_tokens(to, value, token = "eth", from = geth_account)
    send_transaction("", {from: from, to: to, value: value, ether: "0.004"}, token)
  end

  def accounts
    eth_accounts
  end

  def geth_account
    @geth_account ||= accounts[0]
  end

  def token_tx_params(token, ps)
    ps.merge!(contract_method_params_with_gas(nil, token, :transfer, ps, ps[:to], ps.delete(:value)))
  end

  def contract_method_params(owner_info, token, _method, *ps)
    contract_method_params_with_gas(owner_info, token, _method, {}, *ps)
  end

  def contract_method_params_with_gas(owner_info, token, _method, tx_ps, *ps)
    tx_ps = convert_gas_params(tx_ps)
    tx_ps[:from] ||= CONTRACT_OWNERS[token.to_s]
    tx_ps[:from] = owner_info[:owner] if owner_info.is_a?(Hash)
    tx_ps[:data] = Contract.rpc_data(_method, *ps)
    tx_ps[:to] =CONTRACT_ADDRESSES[token.to_s]
    tx_ps.merge!(ps.last) if ps.last.is_a?(Hash)
    tx_ps
  end

  def to_coin_number(n)
    to_number(n.to_s.hex)
  end

  def to_number(n)
    # (BigDecimal.new(n) / (10 ** 18)).round(FLOAT_ROUND)
    i, f = (BigDecimal.new(n) / (10 ** 18)).to_s.split(".")
    [i,f[0, FLOAT_ROUND]].join(".")
  end

  def total_balance(token = 'eth')
    @addresses ||= Account.ethereum.map(&:address).uniq
    to_number @addresses.map{|a| balance_of(a, token, true).hex}.sum
  end

  def get_transaction(tx_id)
    #eth_getTransactionByHash([tx_id])
    eth_getTransactionReceipt([tx_id])
  end

  private

  def convert_tx_params(ps)
    ps[:value] = to_rpc_num(ps[:value])
    convert_gas_params(ps)
  end

  def convert_gas_params(ps)
    if ether_amount = ps.delete(:ether).presence
      decimal_ether = BigDecimal.new(ether_amount) * 10 ** 18
      gas = (decimal_ether / DEFAULT_GAS_PRICE).to_i

      gas = gas > DEFAULT_GAS_LIMIT ? DEFAULT_GAS_LIMIT : gas
      ps[:gas] = to_rpc_num(gas, false)
      gas_price = (decimal_ether / gas).to_i
      ps[:gasPrice] = to_rpc_num(gas_price, false)
    else
      ps[:gas] = to_rpc_num(ps[:gas] || DEFAULT_GAS_LIMIT, false)
      ps[:gasPrice] = to_rpc_num(ps[:gasPrice].presence || DEFAULT_GAS_PRICE, false)
    end
    ps
  end

  def to_rpc_num(value, convert = true)
    value = convert ? (BigDecimal.new(value.to_s) * (10 ** 18)).to_i : value.to_i
    "0x" + value.to_s(16)
  end

  # EthereumRpc.eth_getBalance(["0x7e0d0b656e24a41b8abf2c87d5107467fde8063b", "latest"])
  # EthereumRpc.eth_getBlockByNumber(["0x1", true])
end
