E = EthereumRpc
ROUND_ID = 1
AffID = 1

def wow_address
  lambda {"0xb02d421c38c62dcac5f0c1dc1a4d2954993807f1"}
end

KEY_PRICE = lambda {E.eth_call([{to: wow_address.call, data: "0xb1cd2608000000000000000000000000000000000000000000000000000000000000000#{ROUND_ID}"}])}

BasePS = {
  from: E.eth_coinbase,
  to: wow_address.call,
  gasPrice: "0x4A817C800",
  gas: "0xf4240"
}

BUY_PS = BasePS.merge(data: "0xa6f2ae3a")
BUY_BY_AFFID_PS = BasePS.merge(data: "0x1b11c111000000000000000000000000000000000000000000000000000000000000000#{AffID}")

def rand_buy(num = 200)
  1.upto(num).map do |i|
    aff_id = rand(9) + 1
    addr = E.new_account ""
    puts "#{addr} " + "*" * 10
    E.unlock_account(addr,"")
    _ps = BUY_BY_AFFID_PS.dup
    _ps[:from] = addr
    _ps[:data] = "0x1b11c111000000000000000000000000000000000000000000000000000000000000000#{aff_id.to_s(16)}"
    Ea.transfer(addr, 0.05)
    E.eth_sendTransaction([_ps.merge(value: KEY_PRICE.call)])
  end
end

def calc_profits(address)
  _ps = BasePS.merge(data: "0x541ebca8", from: address)
  E.eth_sendTransaction([_ps])
end


