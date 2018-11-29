pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./PlayerDatasets.sol";
import "./PlayerBook.sol";
import "./WowWinEvents.sol";

interface PlayerBookInterface {
    function registerPlayerID(address _addr, uint256 affID) external returns (uint256);
    function getMaxPID() external returns (uint256);
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getPlayerSubPlys(uint256 _pID) external view returns (uint256);
}

contract WowWin is WowWinEvents {
    
    using SafeMath for uint256;
    
    PlayerBookInterface constant private playerBook = PlayerBookInterface(0x23a56982df39d3ce9c5f64df365097b8232a52be);

    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (uint256 => PlayerDatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => PlayerDatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => PlayerDatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => mapping (uint256 => PlayerDatasets.BuyRecordRounds)) public buyRecordsPlys_;
    mapping (uint256 => uint256) public roundKeyPrices;
    
    uint256 public rID_;
    uint256 public maxAffDepth = 12;
    uint256 public maxLucyNumber = 15;
    uint256 public initKeyPrice = 10000000000000000;
    PlayerDatasets.SplitRates public potSplit;

    constructor()
        public
    {
        potSplit = PlayerDatasets.SplitRates(72,18,8,2);
        for(uint256 j=1;j<=playerBook.getMaxPID();j++){
            plyr_[j].addr = playerBook.getPlayerAddr(j);
            plyr_[j].laff = playerBook.getPlayerLAff(j);
            plyr_[j].subPlys = playerBook.getPlayerSubPlys(j);
            pIDxAddr_[playerBook.getPlayerAddr(j)] = j;
            
        }
    }   
    
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 10000000000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "too much ");
        _;    
    }
    
    function()
        isWithinLimits(msg.value)
        public
        payable
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID == 0 || plyr_[_pID].laff == 0, "you need to register a Player ID");
        
        buy(plyr_[_pID].aff);
    }
    
    function buy(uint256 affId)
        isWithinLimits(msg.value)
        public
        payable
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        
        if (_pID == 0){
            register(affId);
        }
        
        buyCore(_pID);
    }
    
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, address)
    {
        uint256 _rID = rID_;
        
        return
        (
            _rID,                                               //1
            round_[_rID].keys,                                  //2
            round_[_rID].end,                                   //3
            round_[_rID].strt,                                  //4
            round_[_rID].pot,                                   //5
            round_[_rID].plyr,                                  //6
            plyr_[round_[_rID].plyr].addr                       //7
        );
    }
    
    function getCurrentRoundID()
        public
        returns(uint256)
    {
        if (false){
            rID_++;
        }
        if (rID_ == 0) {
            rID_ = 1;
        }
        if (roundKeyPrices[rID_] == 0){
            roundKeyPrices[rID_] = initKeyPrice;
        }
        
        return rID_;    
    }
    
    function buyCore(uint256 _pID)
        private
    {
        uint256 _eth = msg.value;
        uint256 _keys = 1;
        uint256 _rID = getCurrentRoundID();
        
        require(_eth >= roundKeyPrices[_rID], "not enough ETH....");
        
        updateTimer(_keys, _rID);
        // set new leaders
        if (round_[_rID].plyr != _pID)
            round_[_rID].plyr = _pID;
        
        // update player 
        plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
        plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
        
        // update round
        round_[_rID].keys = _keys.add(round_[_rID].keys);
        round_[_rID].eth = _eth.add(round_[_rID].eth);

        // distribute eth
        distributeETH(_rID, _pID, _eth);
        
        updateLucyPlayers(_rID, _pID, _eth);
        
        // call end tx function to fire end tx event.
        endTx(_rID, _pID, _eth, _keys);
    }
    
    function distributeETH(uint256 _rID, uint256 _pID, uint256 _eth)
        private
    {
        uint256 originEth = _eth;
        uint256 _aff = _eth / 10; // 10% to first level, 
        uint256 _affID = plyr_[_pID].laff;
        for(uint256 i = 1;i<=maxAffDepth;i++){
            // reward generations 
            if (i > 1){
                _affID = plyr_[_affID].laff;
                
                if (i == 2){
                    // pay 5% to level 2
                    _aff = _eth / 20; // %5 to second level
                } else {
                    // pay 0.3% to other levels
                    _aff = _eth.mul(3) / 1000; //%0.3 to other levels
                }
            }
            if (_affID != 0 && plyr_[_affID].addr != address(0)){
                plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            }
        }
        
        round_[_rID].pot = _eth.mul(potSplit.bigPot) / 100;  // %8 to big reward pot
        
        // 2% to initialTeams
        uint256 _initTeamReward = (originEth.mul(potSplit.initialTeams)) / 100;
        for(uint256 j=1;j<=9;j++){
            plyr_[j].gen = plyr_[j].gen.add(_initTeamReward / 9);
        }
        
        round_[_rID].bonusPot = round_[_rID].bonusPot.add(_eth.mul(potSplit.allBonus)/100);
    }
    
    function endTx(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _keys)
        private
    {
        uint256 currentPrice = roundKeyPrices[_rID];
        roundKeyPrices[_rID] = currentPrice.mul(10002) / 10000;
        
        emit WowWinEvents.onBuyKeyEnd
        (
            msg.sender,
            _eth,
            currentPrice,
            roundKeyPrices[_rID],
            round_[_rID].keys,
            plyr_[_pID].aff,
            now
        );
    }
    
    function endRound()
        private
        returns (bool)
    {
        uint256 _rID = rID_;
        uint256 _bigRewardPot = round_[_rID].pot.mul(65) / 100;
        uint256 _airdropTokenRewardPot = round_[_rID].pot.sub(_bigRewardPot);
        uint256 _bonusPot = round_[_rID].bonusPot;

        for(uint256 i = 0;i<15;i++){
            uint256 _pid = buyRecordsPlys_[_rID][buyTimes - i].buyerPID;
            uint256 _winPercent = 1;
            if (i == 0){
                 _winPercent = 35;
            } else if (i == 1){
                 _winPercent = 10;
            } else if (i == 2){
                 _winPercent = 5;
            } else if (i == 3){
                 _winPercent = 3;
            } else if (i == 4){
                 _winPercent = 2;
            }
            plyr_[_pid].win = plyr_[_pid].win.add(_winPercent.mul(_winPercent) / 100); //35% give to last player
        }
        
        rID_++;
        buyTimes = 0;
    }
    
    uint256 public buyTimes = 0;
    mapping (uint256 => uint256) plyBuyTimes;
    mapping (uint256 => mapping (uint256 => PlayerDatasets.BuyRecordPlayers)) public buyHistoryPlyer_;
    function updateLucyPlayers(uint256 _rID, uint256 _pID, uint256 _eth)
        private
    {
        buyRecordsPlys_[_rID][buyTimes].buyerPID = _pID;
        buyRecordsPlys_[_rID][buyTimes].buyerEthIn = _eth;
        
        // round 1, player 12345 => 123450001
        uint256 roundPlayerKey = _rID + _pID * 10000;
        uint256 plyrBuyTimesNumber = plyBuyTimes[roundPlayerKey];
        buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].buyTimeNum = buyTimes;
        buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].ethOut = _eth;
        plyBuyTimes[roundPlayerKey] = plyrBuyTimesNumber.add(1);
        
        buyTimes++;
    }
    
    function register(uint256 affId)
        // isActivated()
        // isHuman()
        public
        payable
    {
        address _addr = msg.sender;
        uint256 pid = playerBook.registerPlayerID(_addr, affId);
        if (pid != 0){
            plyr_[pid].addr = _addr;
            pIDxAddr_[_addr] = pid;
            plyr_[pid].laff = affId;
            plyr_[affId].subPlys = playerBook.getPlayerSubPlys(affId);
        }
    }
    
    function withdraw(uint _rID, uint256 amount)
        public
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID > 0,"Invalid Player want to withdraw");
        
        uint256 rewardRate = 10;
        uint256 standardNumber = round_[_rID].keys.mul(80)/ 100; // first 80% buyers
        
        uint256 roundPlayerKey = _rID + _pID * 10000;
        uint256 plyrBuyTimesNumber = plyBuyTimes[roundPlayerKey];
        for(uint256 i = 0; i< plyrBuyTimesNumber;i++){
            uint256 _buyNum = buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].buyTimeNum;
            if (_buyNum <= standardNumber){
                uint256 _ethOut = buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].ethOut;
                plyr_[_pID].win = plyr_[_pID].win.add(_ethOut.mul(rewardRate)/ 100);
            }
            
        }
    }
     
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
       // TODO
    }
}