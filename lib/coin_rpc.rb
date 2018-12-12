class CoinRPC
  def self.[](currency)
    case currency
      when 'usdt'
        UsdtRpc
      when 'btc'
        BitcoinRpc
      else
        EthereumRpc
    end
  end
  
  def self.balance_of(address, coin_name)
    %w(usdt btc).include?(c = coin_name.to_s.downcase) and return CoinRPC[c].balance_of(address)
    EthereumRpc.balance_of(address, c, true).hex / 10 ** 18
  end
end