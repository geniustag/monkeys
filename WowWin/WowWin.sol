pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./PlayerDatasets.sol";
import "./PlayerBook.sol";

interface PlayerBookInterface {
    function registerPlayerID(address _addr, uint256 affID) external returns (uint256);
    function getMaxPID() external returns (uint256);
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getPlayerSubPlys(uint256 _pID) external view returns (uint256);
}

contract WowWin {
    
    using SafeMath for uint256;
    
    PlayerBookInterface constant private playerBook = PlayerBookInterface(0x23a56982df39d3ce9c5f64df365097b8232a52be);

    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (uint256 => PlayerDatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => PlayerDatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => PlayerDatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => mapping (uint256 => uint256)) public luckyPlayers_;
    
    uint256 public rID_;
    uint256 public maxAffDepth = 15;
    uint256 public maxLucyNumber = 15;
    PlayerDatasets.SplitRates public potSplit;

    constructor()
        public
    {
        potSplit = PlayerDatasets.SplitRates(40,35,18,2,2);
        for(uint256 j=1;j<=playerBook.getMaxPID();j++){
            plyr_[j].addr = playerBook.getPlayerAddr(j);
            plyr_[j].laff = playerBook.getPlayerLAff(j);
            plyr_[j].subPlys = playerBook.getPlayerSubPlys(j);
            pIDxAddr_[playerBook.getPlayerAddr(j)] = j;
            
        }
    }   
    
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
    
    function()
        isWithinLimits(msg.value)
        public
        payable
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        buyCore(_pID);
    }
    
    function buy()
        isWithinLimits(msg.value)
        public
        payable
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        
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
            plyr_[round_[_rID].plyr].addr                      //7
        );
    }
    
    function getCurrentRoundID()
        public
        returns(uint256)
    {
        if (false){
            rID_++;
        }
        if (rID_ == 0) rID_ = 1;
        
        return rID_;    
    }
    
    function buyCore(uint256 _pID)
        private
    {
        uint256 _eth = msg.value;
        uint256 _keys = 1;
        uint256 _rID = getCurrentRoundID();
         if (_eth > 1000000000) 
        {
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
            
            updateLucyPlayers(_rID, _pID);
            
            // call end tx function to fire end tx event.
            // endTx(_pID, _eth, _keys, _eventData_);
        }
    }
    
    function distributeETH(uint256 _rID, uint256 _pID, uint256 _eth)
        private
        returns(bool)
    {
        uint256 originEth = _eth;
        uint256 _aff = _eth / 10;
        uint256 _affID = plyr_[_pID].laff;
        for(uint256 i = 1;i<=maxAffDepth;i++){
            // reward generations 
            if (i > 1){
                _affID = plyr_[_affID].laff;
                
                if (i == 2){
                    // pay 5% to level 2
                    _aff = _eth / 20;
                } else {
                    // pay 0.3% to other levels
                    _aff = _eth.mul(3) / 1000;
                }
            }
            if (_affID != 0 && plyr_[_affID].addr != address(0)){
                plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
                _eth = _eth.sub(_aff);
            }
        }
        
        // 2% to initialTeams
        uint256 _initTeamReward = (originEth.mul(potSplit.initialTeams)) / 100;
        for(uint256 j=1;j<=9;j++){
            plyr_[j].gen = plyr_[j].gen.add(_initTeamReward / 9);
            _eth = _eth.sub(_initTeamReward / 9);
        }
        round_[_rID].pot = round_[_rID].pot.add(_eth);
        return(true);
    }
    
    uint256 public luckyStart = 0;
    function updateLucyPlayers(uint256 _rID, uint256 _pID)
        private
    {
        // uint256 step = 5;
        round_[_rID].luckyPlayers = 0;
        luckyPlayers_[_rID][luckyStart] = _pID;
        luckyStart++;
        // for(uint256 j = maxLucyNumber - 1; j>=0;j--){
        //     if ( j > 0) {
        //         luckyPlayers_[_rID][j] = luckyPlayers_[_rID][j - 1];
        //         round_[_rID].luckyPlayers = round_[_rID].luckyPlayers.add(luckyPlayers_[_rID][j] * 10 ** (step.mul(j)));
        //     }
        // }
        // luckyPlayers_[_rID][0] = _pID;
        // round_[_rID].luckyPlayers = round_[_rID].luckyPlayers.add(_pID);
    }
    
    function isInLuckyPot(uint256 _rID, uint256 _pID)
        private
        view
        returns(bool)
    {
        for(uint256 i = (maxLucyNumber - 1); i>=0;i--){
            if (luckyPlayers_[_rID][i] == _pID){
                return true;
            }
        }
        return false;
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
     
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        // grab time
        // uint256 _now = now;
        
        // // calculate time based on number of keys bought
        // uint256 _newTime;
        // if (_now > round_[_rID].end && round_[_rID].plyr == 0)
        //     _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        // else
        //     _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);
        
        // // compare to max and set new end time
        // if (_newTime < (rndMax_).add(_now))
        //     round_[_rID].end = _newTime;
        // else
        //     round_[_rID].end = rndMax_.add(_now);
    }
}