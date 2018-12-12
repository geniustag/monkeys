HOSTS = {
  production: {
    # asset: "https://www.xnodes.pro",
    asset: "http://www.xnodes.pro",
    ether: "http://18.217.51.208:9000",
    btc: "http://tagqxnodes:tagqxnodes2017@47.105.98.63:8311",
    usdt: "http://tagqxnodes:tagqxnodes2017@47.105.98.63:8311",
    eth_address: '0x11c6f67bd3fe7426d0545daea073c124d1a9938b',
    # global: "https://www.xnodes.pro",
    global: "http://www.xnodes.pro",
    # keystore: "47.104.211.46",
    keystore: "18.217.51.208",
    amqp: "18.219.164.156",
    redis: "redis://xnodes.ivarmd.ng.0001.use2.cache.amazonaws.com:6379"
  },
  dev: {
    asset: "http://18.217.134.192",
    ether: "http://18.217.134.192:8545",
    btc: "http://admin:123456@18.218.137.162:18332",
    usdt: "http://admin:123456@18.218.137.162:18332",
    eth_address: '0xc3b46cd396337a4b4e4d8aa87dd2db16b22397ae',
    global: "http://18.218.137.162",
    keystore: "localhost",
    amqp: "18.218.137.162",
    redis: "redis://18.218.137.162:6379"
  },
  development: {
    asset: "http://localhost:3000",
    ether: "http://101.37.89.246:8545",
    eth_address: '0xc3b46cd396337a4b4e4d8aa87dd2db16b22397ae',
    btc: "http://admin:123456@localhost:18332",
    usdt: "http://admin:123456@localhost:18332",
    global: "http://localhost:3000",
    keystore: "101.37.89.246",
    amqp: "localhost",
    redis: "redis://127.0.0.1:6379"
  }
}[Rails.env.to_sym]

MIX_PASSWD_KEY = Rails.env.production? ? File.read("/home/deploy/tkeys/mix_passwd_key") : "123456"
ETH_PASSWD = Rails.env.production? ? File.read("/home/deploy/tkeys/eth_pwd").strip : ""

AssetHost =  HOSTS[:asset] || "/"
GlobalHost =  HOSTS[:global] || "/"

def ether_password(chars = "XNodes")
  Digest::MD5.hexdigest(MIX_PASSWD_KEY + chars.to_s)
end

