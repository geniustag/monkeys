module Contract
  extend self

  METHODS = {
    balanceOf: "address",
    transfer: "address,uint256",
    transferFrom: "address,address,uint256",
    approve: "address,uint256",
    allowance: "address,address",
    totalSupply: ""
  }

  METHOD_IDS = {
    balanceOf: "70a08231",
    transfer: "a9059cbb",
    transferFrom: "23b872dd",
    approve: "095ea7b3",
    allowance: "dd62ed3e",
    totalSupply: "18160ddd"
  }

  GST_METHODS = {
    transferAndFreezeTokens: "address,uint256",
    freezeAccount: "address,bool",
    freezeAccountWithToken: "address,uint256",
    frozenAccount: "address",
    frozenAccountTokens: "address",
    unfreezeAccountWithToken: "address,uint256",
    transferOwnership: "address",
    paused: "",
    pause: "",
    unpause: ""
  }

  GST_METHOD_IDS = {
    transferAndFreezeTokens: "da14e3b2",
    freezeAccount: "e724529c",
    freezeAccountWithToken: "5c142f2b",
    frozenAccount: "b414d4b6",
    frozenAccountTokens: "217ac0de",
    unfreezeAccountWithToken: "b29f9d3b",
    transferOwnership: "f2fde38b",
    paused: "5c975abb",
    pause: "8456cb59",
    unpause: "3f4ba83a"
  }

  def rpc_data(method, *params)
    data_converter(method, params).unshift("0x#{METHOD_IDS[method] || GST_METHOD_IDS[method]}").join
  end

  def data_converter(method, params)
    ps = []
    ms = METHODS[method] || GST_METHODS[method]
    ms.split(",").each_with_index do |type, index|
      param = params[index]
      param = address_to_data(param) if type == "address"
      param = int_to_data(param) if type =~ /^uint/
      param = bool_to_data(param) if type =~ /bool/
      ps << param
    end
    ps
  end

  def address_to_data(address)
    "#{"0" * 24}#{address[2, 100]}"
  end

  def int_to_data(value)
    value = (BigDecimal.new(value) * (10 ** 18)).to_i.to_s(16)
    "0" * (64 - value.size) + value
  end

  def bool_to_data(value)
    "#{"0" * 63}#{value ? 1 : 0}"
  end
end
