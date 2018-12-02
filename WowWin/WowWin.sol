pragma solidity ^0.4.23;

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
    
    PlayerBookInterface constant private playerBook = PlayerBookInterface(0x6ef52008f28009c55b57bc8682a5e126c66318e0);

    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (uint256 => PlayerDatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => PlayerDatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    mapping (uint256 => PlayerDatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => mapping (uint256 => PlayerDatasets.BuyRecordRounds)) public buyRecordsPlys_;
    mapping (uint256 => uint256) public roundKeyPrices;
    mapping (uint256 => uint256) public divisionNumer;
    
    // DATA for record buyTimes details
    mapping (uint256 => uint256) plyBuyTimes;
    mapping (uint256 => mapping (uint256 => PlayerDatasets.BuyRecordPlayers)) public buyHistoryPlyer_;
    
    uint256 public rID_;
    uint256 public maxAffDepth = 12;
    uint256 public maxLucyNumber = 15;
    uint256 public initKeyPrice = 10000000000000000;
    bool public activated_ = false;
    uint256 constant private rndInit_ = 8 hours;
    
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
    
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord"); 
        _;
    }
    
    /**
     * @dev prevents contracts from interacting with fomo3d 
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    function()
        isWithinLimits(msg.value)
        public
        payable
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID == 0 || plyr_[_pID].laff == 0, "you need to register a Player ID");
        
        buy();
    }
    
    function buy()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        require(plyr_[_pID].laff > 0 ||  _pID == 0, "Regsiter First..."); 
        buyCore(_pID);
    }
    
    function buyByAff(uint256 affId)
        isActivated()
        isHuman()
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
    
    function buyCore(uint256 _pID)
        private
    {
        uint256 _eth = msg.value;
        uint256 _keys = 1;
        uint256 _rID = rID_;
        
        require(_eth >= roundKeyPrices[_rID], "not enough ETH....");
        
        // set new leaders
        if (round_[_rID].plyr != _pID)
            round_[_rID].plyr = _pID;
            
        if (plyr_[_pID].lrnd != _rID)
            plyr_[_pID].lrnd = _rID;
        
        // update player 
        plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
        plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
        
        // update round
        round_[_rID].keys = _keys.add(round_[_rID].keys);
        round_[_rID].eth = _eth.add(round_[_rID].eth);

        // distribute eth
        distributeETH(_rID, _pID, _eth);
        
        recordPlayerBuy(_rID, _pID, _eth);
        
        // call end tx function to fire end tx event.
        endTx(_rID, _pID, _eth);
    }
    
    function distributeETH(uint256 _rID, uint256 _pID, uint256 _eth)
        private
    {
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
        
        round_[_rID].pot = round_[_rID].pot.add(_eth.mul(potSplit.bigPot) / 100);  // %8 to big reward pot
        
        // 2% to initialTeams
        uint256 _initTeamReward = (_eth.mul(potSplit.initialTeams)) / 100;
        for(uint256 j=1;j<=3;j++){
            plyr_[j].gen = plyr_[j].gen.add(_initTeamReward / 3);
        }
        
        round_[_rID].bonusPot = round_[_rID].bonusPot.add(_eth.mul(potSplit.allBonus)/100);
    }
    
    function endTx(uint256 _rID, uint256 _pID, uint256 _eth)
        private
    {
        uint256 currentPrice = roundKeyPrices[_rID];
        roundKeyPrices[_rID] = currentPrice.mul(10002) / 10000;
        updateTimer(_rID);
        
        // determine end conditions
        endRound();
        
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
    
        if (round_[_rID].ended) return false;
        
        if (now < (round_[_rID].strt + 8 * 3600)) {
            return false;
        }
        
        return true;
    }
    
    function fourceEndRound(uint256 _rID)
        public
    {
        if (round_[_rID].ended) return;
        doEndRound();
    }
    
    function doEndRound()
        private
    {
        uint256 _rID = rID_;
        uint256 keys = round_[_rID].keys;
        
        for(uint256 i = 0;i<15;i++){
            uint256 _pid = buyRecordsPlys_[_rID][round_[_rID].buyTimes - i].buyerPID;
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
        
        if (divisionNumer[_rID] == 0){
            if (keys >= 1000 && keys < 5000){
                divisionNumer[_rID] = keys.mul(60)/ 100; // first 60% buyers
            } else if (keys >= 5000 && keys < 10000){
                divisionNumer[_rID] = keys.mul(70)/ 100; // first 70% buyers
            } else if (keys >= 10000 && keys < 15000){
                divisionNumer[_rID] = keys.mul(75)/ 100; // first 75% buyers
            } else if (keys >= 15000){
                divisionNumer[_rID] = keys.mul(80)/ 100; // first 80% buyers
            }
        }
        
        rID_++;
        startRound(rID_);
    
        round_[_rID].ended = true;
        emit WowWinEvents.onEndRound
        (
            msg.sender,
            _rID,
            now
        );
    }
    
    function recordPlayerBuy(uint256 _rID, uint256 _pID, uint256 _eth)
        private
    {
        buyRecordsPlys_[_rID][round_[_rID].buyTimes].buyerPID = _pID;
        buyRecordsPlys_[_rID][round_[_rID].buyTimes].buyerEthIn = _eth;
        
        // round 1, player 12345 => 123450001
        uint256 roundPlayerKey = _rID + _pID * 10000;
        uint256 plyrBuyTimesNumber = plyBuyTimes[roundPlayerKey];
        buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].buyTimeNum = round_[_rID].buyTimes;
        buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].ethOut = _eth;
        
        plyBuyTimes[roundPlayerKey] = plyrBuyTimesNumber.add(1); // update count of player bought keys
        round_[_rID].buyTimes++;
    }
    
    function register(uint256 affId)
        isActivated()
        isHuman()
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
    
    function withdraw(uint256 amount)
        public
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 allAvalibleEth = calcAllProfits();
        
        require(allAvalibleEth > 0, "Have no eth to withdraw");
        require(allAvalibleEth >= amount.add(plyr_[_pID].withdraw), "not enough eths");
        
        msg.sender.transfer(amount);
        plyr_[_pID].withdraw = plyr_[_pID].withdraw.add(amount);
        
        emit WowWinEvents.onWithdraw
        (
            _pID,
            msg.sender,
            amount,
            now
        );
    }
    
    function calcAllProfits()
        public
        returns(uint256)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID > 0,"Invalid Player want to withdraw");
        
        uint256 roundsStaticWin = 0;
        for(uint256 i = 1;i<plyr_[_pID].lrnd;i++){
            uint256 _win = staticProfitForPID(i, _pID);
            if (plyrRnds_[i][_pID].staticWin == 0){
                plyrRnds_[i][_pID].staticWin = _win;
            }
            roundsStaticWin = roundsStaticWin.add(_win);
        }
        
        if (roundsStaticWin != plyr_[_pID].staticWin)
            plyr_[_pID].staticWin = roundsStaticWin;
            
        return roundsStaticWin.add(plyr_[_pID].win).add(plyr_[_pID].aff).add(plyr_[_pID].gen);
    }
    
    function staticProfitForPID(uint256 _rID, uint256 _pID)
        public
        view
        returns(uint256)
    {
        
        if (isRoundRunning(_rID)) return 0;
        
        uint256 _win = plyrRnds_[_rID][_pID].staticWin;
        
        if (_win > 0) return _win;
        
        uint256 roundPlayerKey = _rID + _pID * 10000;
        uint256 plyrBuyTimesNumber = plyBuyTimes[roundPlayerKey];
        uint256 encouragePot = round_[_rID].pot.mul(35).div(100);
        
        for(uint256 i = 0; i< plyrBuyTimesNumber;i++){
            uint256 _buyNum = buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].buyTimeNum;
            if (_buyNum < divisionNumer[_rID]){
                if (_buyNum > 10000 && _buyNum < 15000){
                    _win = _win.add(buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].ethOut.mul(10) / 100);

                } else if (_buyNum >= 15000 && _buyNum < 20000){
                    _win = _win.add(buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].ethOut.mul(15) / 100);

                } else if (_buyNum >= 20000 && _buyNum < 25000){
                    _win = _win.add(buyHistoryPlyer_[roundPlayerKey][plyrBuyTimesNumber].ethOut.mul(20) / 100);
                }
            }
            if (_buyNum >= (round_[_rID].keys.mul(85) / 100) && _buyNum < (round_[_rID].keys.mul(95) / 100)){
                _win = _win.add( encouragePot.div(round_[_rID].keys.div(10)) );
            }
        }
        
        return _win;
    }
    
    function isRoundRunning(uint256 _rID)
        public
        view
        returns(bool)
    {
        // TODO
        return round_[_rID].keys < 1000 || !round_[_rID].ended;
    }
    
    function activate()
        public
    {
        require(
            msg.sender == 0xafda8dAA256EABc84a30bCd415A0A9E2feE15945,
            "only admin just can activate"
        );
        
        // can only be ran once
        require(activated_ == false, "WowWin already activated");
        
        // activate the contract 
        activated_ = true;
        
        // lets start first round
        rID_ = 1;
        startRound(rID_);
    }
    
    function startRound(uint256 _rID)
        private
    {
        round_[_rID].strt = now;
        round_[_rID].end = now + rndInit_;
        round_[_rID].buyTimes = 0;
        roundKeyPrices[_rID] = initKeyPrice;
    }
    
    function updateTimer(uint256 _rID)
        private
    {
       // TODO
    }
}