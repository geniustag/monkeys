class EtherAccount

  attr_accessor :token
  attr_reader :address, :password

  def initialize(address, password, token)
    @address = address.is_a?(EtherAccount) ? address.address : address
    @password = password
    raise "EtherAccountPasswordError" if !EthereumRpc.unlock_account(address, password)
    @token = token.downcase
  end

  Contract::METHODS.each do |gm, ps|
    define_method gm do |*pps|
      if token == 'eth' && (m = gm.to_s) =~ /transfer/
        from = m == "transfer" ? address : pps.shift
        EthereumRpc.send_transaction(password, from: from, to: pps[0], value: pps[1])
      else
        EthereumRpc.invork_contract({owner: address, password: password}, token, gm, *pps)
      end
    end
  end

  def balance(origin_value = false)
    EthereumRpc.balance_of(address, token, origin_value)
  end
end

# aa.approve(b, 100)
