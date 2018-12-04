E = EthereumRpc
wow_address = "0x6c079b05641154d1c84d78dab07a2d96799e4de1"
round_id = 1
aff_id = 1

key_price = lambda {E.eth_call([{to: wow_address, data: "0xb1cd2608000000000000000000000000000000000000000000000000000000000000000#{round_id}"}])}

BasePS = {
  from: E.eth_coinbase,
  to: wow_address,
  gasPrice: "0x4A817C800",
  gas: "0xf4240"
}

buy_ps = BasePS.merge(data: "0xa6f2ae3a")

buy_by_affid_ps = BasePS.merge(data: "0x1b11c111000000000000000000000000000000000000000000000000000000000000000#{aff_id}")

1.upto(150).map do |i|
  aff_id = rand(9) + 1
  addr = E.new_account ""
  puts "#{addr} " + "*" * 10
  E.unlock_account(addr,"")
  _ps = buy_by_affid_ps.dup
  _ps[:from] = addr
  _ps[:data] = "0x1b11c111000000000000000000000000000000000000000000000000000000000000000#{aff_id.to_s(16)}"
  ea.transfer(addr, 0.05)
  E.eth_sendTransaction([_ps.merge(value: key_price.call)])
end

def calc_profits(address)
  _ps = BasePS.merge(data: "0x541ebca8", from: address)
  E.eth_sendTransaction([_ps])
end
