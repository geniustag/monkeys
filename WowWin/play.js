var abi = [];
var address = "",
    LucyDogContract = web3.eth.contract(abi),
    LucyDog = LucyDogContract.at(address),
    KeyPrice = 0,
    currentPlayerAddress = 0;

LucyDog.rID_.call(function(error, res){
  KeyPrice = res;
});

LucyDog.buy({value: 10000000000000000, gas: 1000000, gasPrice: 2000000000}, function(err, result){
   console.info(result);
});

var events = LucyDog.allEvents(["lastest"], function(error, event){
 if (!error)
    var args = res.args;
    if (res.event === "onBuyKeyEnd") {
      KeyPrice = args.nextKeyPrice;
      currentPlayerAddress = argsplayerAddress;
    }
});

