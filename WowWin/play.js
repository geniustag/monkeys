
window.addEventListener('load', function() {
  if (!window.web3) {
    window.alert('Please install MetaMask first.');
    return;
  }
  if (!web3.eth.coinbase) {
    window.alert('Please activate MetaMask first.');
    return;
  }
  if (typeof web3 !== 'undefined') {
      web3.personal.sign(web3.fromUtf8("Please select your address to start"), web3.eth.coinbase, console.log);
  }
});

var abi = [];

var address = "0xc06375196666681f8c9fde843903a9ce4fdcab2a",
    GameContract = web3.eth.contract(abi),
    Game = GameContract.at(address),
    KeyPrice = 0,
    affId = 0,
    defaultBuyGas = 1000000,
    defaultGasPrice = 3000000000,
    currentPlayerAddress = 0;

Game.rID_.call(function(error, roundId){
  Game.roundKeyPrices.call(roundId,function(error, kprice){
    KeyPrice = kprice;
  });
});

var events = Game.allEvents(["lastest"], function(error, event){
  if (!error){
    var args = res.args;
    if (res.event === "onBuyKeyEnd") {
      KeyPrice = args.nextKeyPrice;
      currentPlayerAddress = argsplayerAddress;
    }
  }
});

var buyParams  = {
  from: web3.eth.coinbase, 
  to: address, 
  data: "0xa6f2ae3a", 
  value: KeyPrice
}

function buyKey() {
  web3.eth.estimateGas(buyParams, function(err, _gasLimit){
    if (_gasLimit == undefined) _gasLimit = defaultBuyGas;
    web3.eth.getGasPrice(function(err, _gasPrice){
      console.info("GAS: " + _gasLimit, "GASPRICE: " + _gasPrice);
      Game.buy({value: KeyPrice, gas: _gasLimit, gasPrice: _gasPrice}, function(err, result){
         console.info(result);
      });
    });
  })
}
