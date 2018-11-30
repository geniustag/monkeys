contract WowWinEvents {
    event onNewPlayer
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        uint256 amountPaid,
        uint256 timeStamp
    );
    
    event onBuyKeyEnd
    (
        address buyerAddress,
        uint256 buyerEthIn,
        uint256 currentKeyPrice,
        uint256 nextKeyPrice,
        uint256 keysAmount,
        uint256 laffID,
        uint256 timeStamp
    );
    
}