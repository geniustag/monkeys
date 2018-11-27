pragma solidity ^0.4.24;

import "./SafeMath.sol";
library PlayerDatasets {
    struct Player {
        address addr;   // player address
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
        uint256[] subPlys;   // childPIDs
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask 
    }
    struct Round {
        mapping (uint256 => uint256) lastTenPIDs;
        uint256 plyr;   // pID of player in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
    }
}
