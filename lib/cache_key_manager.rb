module CacheKeyManager
  extend self

  PREFIX = "xNodes"

  # for Kline and depth
  def k_line(trade_pair, period = 1)
    join(trade_pair, "k", period)
  end

  def k_line_last_point(trade_pair, period = 1)
    join(trade_pair, "k:last:point", period)
  end

  def h24_low(trade_pair)
    join(trade_pair, "h24", "low")
  end

  def h24_high(trade_pair)
    join(trade_pair, "h24", "high")
  end

  def depth(trade_pair, side)
    join(trade_pair, "depth", side)
  end

  def ticker(trade_pair)
    join(trade_pair, "ticker")
  end

  def ticker_open(trade_pair)
    join(trade_pair, "ticker:open")
  end

  def trades(trade_pair)
    join(trade_pair, "trades")
  end

  # for wallet
  def hotwallet_balance(coin_symbol)
    join("hotwallet", coin_symbol, "balance")
  end

  # for market
  def market_ticker(market)
    for_market(market, "ticker")
  end

  def market_trades(market)
    for_market(market, "trades")
  end

  def for_market(m, key_name)
    join(m.trade_pair, key_name)
  end

  # for stats
  def member_stats(period)
    stats("member", period)
  end

  def funds_stats(coin_symbol, period)
    stats("funds:#{coin_symbol}", period)
  end

  def wallet_stats(coin_symbol, period)
    stats("wallet:#{coin_symbol}", period)
  end

  def top_stats(trade_pair, period)
    stats("top:#{trade_pair}", period)
  end

  def trades_stats(trade_pair, period)
    stats("trades:#{trade_pair}", period)
  end

  def stats(type, period)
    join("stats", type, period)
  end

  # global
  def daemon_status
    join("daemons","statuses")
  end

  # session
  def session(*key_names)
    join("session", *key_names)
  end

  # robot
  def robot(trade_pair, key_name)
    join(trade_pair, "robot:trade", key_name)
  end

  # daemons
  def amqp_daemon(key_name)
    join("amqp", key_name)
  end

  def daemon(key_name)
    join("daemon", key_name)
  end
  
  def rpc_address(coin)
    join(coin, 'address')
  end
  
  def deposit_fail_txid(coin_platform)
    join('deposit', 'fail', coin_platform)
  end
  
  def eth_filter_id
    join('eth_filter_id')
  end

  private

  def join(*ks)
    ks.unshift(PREFIX).join(":")
  end

end
