
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

var address = "0xb4c132df16ea4ae3d50203df13e52ce21036f59a",
    GameContract = web3.eth.contract(abi),
    Game = GameContract.at(address),
    KeyPrice = 0,
    defaultBuyGas = 100000,
    defaultGasPrice = 3000000000,
    currentPlayerAddress = 0;

Game.rID_.call(function(error, roundId){
  Game.roundKeyPrices.call(roundId,function(error, kprice){
    KeyPrice = kprice;
  });
});

var events = Game.allEvents(["lastest"], function(error, event){

if (!error)
    var args = res.args;
    if (res.event === "onBuyKeyEnd") {
      KeyPrice = args.nextKeyPrice;
      currentPlayerAddress = argsplayerAddress;
    }
});

var buyParams  = {
  from: web3.eth.coinbase, 
  to: address, 
  data: "0xa6f2ae3a", 
  value: KeyPrice
}

function buyKey() {
  web3.eth.estimateGas(buyParams, function(err, gasLimit){
    web3.eth.getGasPrice(function(err, gasPrice){
      console.info("GAS: " + gasLimit, "GASPRICE" + gasPrice);
      Game.buy({value: KeyPrice, gas: gasLimit, gasPrice: gasPrice}, function(err, result){
         console.info(result);
      });
    });
  })
}
