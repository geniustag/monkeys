E = EthereumRpc
wow_address = "0x988f6b9358be8a22d4a231da861971c090b8bc4d"
round_id = 1
aff_id = 1

key_price = lambda {E.eth_call([{to: wow_address, data: "0xb1cd2608000000000000000000000000000000000000000000000000000000000000000#{round_id}"}])}

buy_ps = {
  from: "0x3ab3b6cf8a47add1a03e9372c0e3077ca5baf33c",
  to: wow_address,
  data: "0xa6f2ae3a",
  gasPrice: "0x4A817C800",
  gas: "0xf4240"
}

buy_by_affid_ps = buy_ps.merge(data: "0x1b11c111000000000000000000000000000000000000000000000000000000000000000#{aff_id}")

ps = buy_by_affid_ps

100.times { E.eth_sendTransaction([ps.merge(value: key_price.call)]) }


16.upto(30).each do |i|
  aff_id = i
  addr = E.new_account ""
  puts "#{addr} " + "*" * 10
  E.unlock_account(addr,"")
  _ps = buy_by_affid_ps.dup
  _ps[:from] = addr
  _ps[:data] = "0x1b11c11100000000000000000000000000000000000000000000000000000000000000#{aff_id.to_s(16)}"
  ea.transfer(addr, 0.05)
  E.eth_sendTransaction([_ps.merge(value: key_price.call)])
end