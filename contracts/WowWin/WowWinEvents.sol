pragma solidity ^0.4.23;

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
        uint256 buyerID,
        address buyerAddress,
        uint256 buyerEthIn,
        uint256 currentKeyPrice,
        uint256 nextKeyPrice,
        uint256 keysAmount,
        uint256 laffID,
        uint256 timeStamp
    );

    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );
    
    event onEndRound
    (
        address lastBuyer,
        uint256 rID,
        uint256 timeStamp
    );
    
}
