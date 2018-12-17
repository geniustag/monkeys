HOSTS = {
  production: {
    asset: "http://www.xnodes.pro",
    ether: "http://18.217.51.208:9000",
    global: "http://www.xnodes.pro",
    redis: "redis://xnodes.ivarmd.ng.0001.use2.cache.amazonaws.com:6379"
  },
  dev: {
    asset: "http://18.217.134.192",
    ether: "http://18.217.134.192:8545",
    global: "http://18.218.137.162",
    redis: "redis://18.218.137.162:6379"
  },
  development: {
    asset: "http://localhost:3000",
    ether: "http://localhost:8545",
    global: "http://localhost:3000",
    redis: "redis://127.0.0.1:6379"
  }
}[Rails.env.to_sym]

