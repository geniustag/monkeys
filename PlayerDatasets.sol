pragma solidity ^0.4.24;

library PlayerDatasets {
    struct EventReturns {
        address winnerAddr;         // winner address
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 TeamAmount;          // amount distributed to gen
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }
    struct Player {
        address addr;   // player address
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
        uint256 subPlys;   // childPIDs
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask 
    }
    struct Round {
        uint256 luckyPlayers;
        uint256 plyr;   // pID of player in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
    }
    struct SplitRates {
        uint256 allBonus;              // % of pot thats paid to key holders of current round
        uint256 affiliateBonus;        // % of pot thats paid to 9 parents
        uint256 bigPot;                // % of pot thats paid to final 10 winners
        uint256 airdrop;               // % of airdrop
        uint256 initialTeams;          // % of initial team
    }
}