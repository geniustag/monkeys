pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./F3DKeysCalcLong.sol";

contract F3Devents {
    // fired whenever a player registers a name
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
    
    // fired at end of buy or reload
    event onEndTx
    (
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 TeamAmount,
        uint256 genAmount,
        uint256 potAmount,
        uint256 airDropPot
    );
    
    // fired whenever theres a withdraw
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );
    
    // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute
    (
        address playerAddress,
        uint256 ethOut,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 TeamAmount,
        uint256 genAmount
    );
    
    // (fomo3d long only) fired whenever a player tries a buy after round timer 
    // hit zero, and causes end round to be ran.
    event onBuyAndDistribute
    (
        address playerAddress,
        uint256 ethIn,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 TeamAmount,
        uint256 genAmount
    );
    
    // (fomo3d long only) fired whenever a player tries a reload after round timer 
    // hit zero, and causes end round to be ran.
    event onReLoadAndDistribute
    (
        address playerAddress,
        address winnerAddr,
        uint256 amountWon,
        uint256 newPot,
        uint256 TeamAmount,
        uint256 genAmount
    );
    
    // fired whenever an affiliate is paid
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
}

library F3Ddatasets {
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
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask 
    }
    struct Round {
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
contract PlayerBook {
    using SafeMath for uint256;

    uint256 public pID_;        // total number of players
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (uint256 => Player) public plyr_;               // (pID => data) player data

    struct Player {
        address addr;
        uint256 laff;
    }
    constructor()
        public
    {
        plyr_[1].addr = 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53;
        pIDxAddr_[0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53] = 1;
        
        plyr_[2].addr = 0x8b4DA1827932D71759687f925D17F81Fc94e3A9D;
        pIDxAddr_[0x8b4DA1827932D71759687f925D17F81Fc94e3A9D] = 2;
        
        plyr_[3].addr = 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C;
        pIDxAddr_[0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C] = 3;
        
        plyr_[4].addr = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C;
        pIDxAddr_[0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C] = 4;
        
        plyr_[5].addr = 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53;
        pIDxAddr_[0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53] = 5;
        
        plyr_[6].addr = 0x8b4DA1827932D71759687f925D17F81Fc94e3A9D;
        pIDxAddr_[0x8b4DA1827932D71759687f925D17F81Fc94e3A9D] = 6;
        
        plyr_[7].addr = 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C;
        pIDxAddr_[0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C] = 7;
        
        plyr_[8].addr = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C;
        pIDxAddr_[0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C] = 8;
        
        plyr_[9].addr = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C;
        pIDxAddr_[0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C] = 9;
        
        pID_ = 9;
    }

    //==============================================================================
    function determinePID(address _addr, uint256 affID)
        private
        returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;
            require (affID > 0 && plyr_[affID].addr != address(0), "Invalid affId");
            if (plyr_[pID_].laff != 0)
                plyr_[pID_].laff = affID;
            return (true);
        } else {
            return (false);
        }
    }

    //==============================================================================
    
    function registerPlayerID(address _addr, uint256 affID)
        external
        returns (bool)
    {
        return determinePID(_addr, affID);
    }
    
    function getPlayerID(address _addr)
        external
        view
        returns (uint256)
    {
        // bool isNew = determinePID(_addr, affID);
        return (pIDxAddr_[_addr]);
    }
    
    function getPlayerLAff(uint256 _pID)
        external
        view
        returns (uint256)
    {
        return (plyr_[_pID].laff);
    }
    function getPlayerAddr(uint256 _pID)
        external
        view
        returns (address)
    {
        return (plyr_[_pID].addr);
    }
    
    function getMaxPID() 
        external
        view
        returns (uint256 )
    {
        return pID_;
    }
        
}

interface PlayerBookInterface {
    function registerPlayerID(address _addr, uint256 affID) external returns (bool);
    function getMaxPID() external returns (uint256);
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
}

contract FoMoLike is F3Devents {
    using SafeMath for *;
    using F3DKeysCalcLong for uint256;
    
    // otherFoMo3D private otherF3D_;
    PlayerBookInterface constant private playerBook = PlayerBookInterface(0xD60d353610D9a5Ca478769D371b53CEfAA7B6E4c);
    //==============================================================================
    // (game settings)
    //=================_|===========================================================
    string constant public name = "Monkey";
    string constant public symbol = "MK";
    uint256 private rndExtra_ = 10 minutes;     // length of the very first ICO 
    uint256 private rndGap_ = 2 minutes;         // length of ICO phase, set to 1 year for EOS.
    uint256 constant private rndInit_ = 1 hours;                // round timer starts at this
    uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be
    uint256 constant private minPlayerCountForAirdrop = 30;     // need min 30 players to airdrop
    uint256 constant private airDropAmountLimit = 1e19;            // 10 eth 
    uint256 public initKeyPrice = 1e15;                         // 0.001 eth
    
    //==============================================================================
    // (data used to store game info that changes)
    //=============================|================================================
    uint256 public airDropPot_;                     // person who gets the airdrop wins part of this pot
    uint256 public airDropCountTracker_ = 0;        // incremented each time a "qualified" tx occurs.  used to determine winning air drop
    uint256 public rID_;                            // round id number / total rounds that have happened

    //****************
    // PLAYER DATA 
    //****************
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (uint256 => F3Ddatasets.Player) public plyr_;   // (pID => data) player data
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    // (pID => rID => data) player round data by player id & round id
    
    //****************
    // ROUND DATA 
    //****************
    mapping (uint256 => F3Ddatasets.Round) public round_;   // (rID => data) round data
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;      // (rID => tID => data) eth in per team, by round id and team id
    mapping (uint256 => uint256) public lastTenPIDs;
    
    F3Ddatasets.SplitRates public potSplit;
    
    // deploy
    constructor()
        public
    {
        // 40% to for all keys holders, 35% to affiliates, 18% to big reward pot, 2% to airdrop pot, 5% to initialTeams;    
        potSplit = F3Ddatasets.SplitRates(40,35,18,2,5);
    }
    
    //==============================================================================
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

    /**
     * @dev sets boundaries for incoming tx 
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
    
    modifier isHasAff(){
        address _addr = msg.sender;
        uint aff = plyr_[pIDxAddr_[_addr]].laff;
        require(pIDxAddr_[_addr] != aff && aff > 0 && plyr_[aff].addr != address(0), "you need set a valid aff");
        _;
    }
    
    //==============================================================================
    /**
     * @dev emergency buy uses last stored affiliate ID and team snek
     */
    function()
        isActivated()
        isHuman()
        isHasAff()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
            
        // fetch player id
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // buy core 
        buyCore(_pID, _eventData_);
    }
    
    function register(address _addr, uint256 affId)
        public
        payable
    {
        require(affId > 0 && pIDxAddr_[_addr] != affId && plyr_[affId].addr != address(0)); // need a valid affId
        
        playerBook.registerPlayerID(_addr, affId);
    }
    
    /**
     * @dev converts all incoming ethereum to keys.
     * -functionhash- 0x8f38f309 (using ID for affiliate)
     * -functionhash- 0x98a0871d (using address for affiliate)
     * -functionhash- 0xa65b37a1 (using name for affiliate)
     */
    function buyXid()
        isActivated()
        isHuman()
        isHasAff()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = pIDxAddr_[msg.sender];
        
        buyCore(_pID, _eventData_);
    }
    
    function buyXaddr()
        isActivated()
        isHuman()
        isHasAff()
        isWithinLimits(msg.value)
        public
        payable
    {
        // set up our tx event data and determine if player is new or not
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // buy core 
        buyCore(_pID, _eventData_);
    }

    
    /**
     * @dev essentially the same as buy, but instead of you sending ether 
     * from your wallet, it uses your unwithdrawn earnings.
     * -functionhash- 0x349cdcac (using ID for affiliate)
     * -functionhash- 0x82bfc739 (using address for affiliate)
     * -functionhash- 0x079ce327 (using name for affiliate)
     * @param _affCode the ID/address/name of the player who gets the affiliate fee
     * @param _eth amount of earnings to use (remainder returned to gen vault)
     */
    function reLoadXid(uint256 _affCode, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        // require (withdrawEarnings(_pID) > _eth, "You have to send a vaid amount eth ... ");
        
        // set up our tx event data
        F3Ddatasets.EventReturns memory _eventData_;
        
        // manage affiliate residuals
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == 0 || _affCode == _pID)
        {
            // use last stored affiliate code 
            _affCode = plyr_[_pID].laff;
        }

        // reload core
        reLoadCore(_pID,  _eth, _eventData_);
    }
    
    function reLoadXaddr(address _affCode, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        // require (withdrawEarnings(_pID) > _eth, "You have to send a vaid amount eth ... ");

        // set up our tx event data
        F3Ddatasets.EventReturns memory _eventData_;

        // manage affiliate residuals
        uint256 _affID;
        // if no affiliate code was given or player tried to use their own, lolz
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            // use last stored affiliate code
            _affID = plyr_[_pID].laff;
        }
        
        // reload core
        reLoadCore(_pID, _eth, _eventData_);
    }
    

    /**
     * @dev withdraws all of your earnings.
     * -functionhash- 0x3ccfd60b
     */
    function withdraw()
        isActivated()
        isHuman()
        public
    {
        // setup local rID 
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // fetch player ID
        uint256 _pID = pIDxAddr_[msg.sender];
        
        // setup temp var for player eth
        uint256 _eth;
        
        // check to see if round has ended and no one has run round end yet
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // set up our tx event data
            F3Ddatasets.EventReturns memory _eventData_;
            
            // end the round (distributes pot)
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
            
            // get their earnings
            _eth = withdrawEarnings(_pID);
            
            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);    
            
            // build event data
            
            // fire withdraw and distribute event
            emit F3Devents.onWithdrawAndDistribute
            (
                msg.sender, 
                _eth, 
                _eventData_.winnerAddr, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.TeamAmount, 
                _eventData_.genAmount
            );
            
        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_pID);
            
            // gib moni
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
            
            // fire withdraw event
            // emit F3Devents.onWithdraw(_pID, msg.sender, _eth, _now);
        }
    }

//==============================================================================
    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * -functionhash- 0x018a25e8
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( initKeyPrice ); // init
    }
    
    /**
     * @dev returns time left.  dont spam this, you'll ddos yourself from your node 
     * provider
     * -functionhash- 0xc7e284b8
     * @return time left in seconds
     */
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }
    
    /**
     * @dev returns player earnings per vaults 
     * -functionhash- 0x63066434
     * @return winnings vault
     * @return general vault
     * @return affiliate vault
     */
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // if round has ended.  but round end has not been run (so contract has not distributed winnings)
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            // if player is winner 
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(48)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   ),
                    plyr_[_pID].aff
                );
            // if player is not the winner
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }
            
        // if round is still going on, or round has ended and round end has been ran
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }
    
    /**
     * solidity hates stack limits.  this lets us avoid that hate 
     */
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit.allBonus)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }
    
    /**
     * @dev returns all current round info needed for front end
     * -functionhash- 0x747dff42
     * @return round id 
     * @return total keys for round 
     * @return time round ends
     * @return time round started
     * @return current pot 
     * @return current team ID & player ID in lead 
     * @return current player in leads address 
     * @return airdrop tracker # & airdrop pot
     */
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, address, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        return
        (
            _rID,                                               //1
            round_[_rID].keys,                                  //2
            round_[_rID].end,                                   //3
            round_[_rID].strt,                                  //4
            round_[_rID].pot,                                   //5
            round_[_rID].plyr,                                  //6
            plyr_[round_[_rID].plyr].addr,                      //7
            airDropCountTracker_ + (airDropPot_ * 10000)              //8
        );
    }

    /**
     * @dev returns player info based on address.  if no address is given, it will 
     * use msg.sender 
     * -functionhash- 0xee0b5d8b
     * @param _addr address of the player you want to lookup 
     * @return player ID 
     * @return player name
     * @return keys owned (current round)
     * @return winnings vault
     * @return general vault 
     * @return affiliate vault 
     * @return player round eth
     */
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        
        return
        (
            _pID,                                                                       //0
            plyrRnds_[_pID][_rID].keys,                                                 //2
            plyr_[_pID].win,                                                            //3
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),        //4
            plyr_[_pID].aff,                                                            //5
            plyrRnds_[_pID][_rID].eth                                                   //6
        );
    }

//==============================================================================
//  (this + tools + calcs + modules = our softwares engine)
//=====================_|=======================================================
    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not
     */
    // function buyCore(uint256 _pID, uint256 _affID, F3Ddatasets.EventReturns memory _eventData_)
    function buyCore(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // if round is active
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            // call core 
            core(_rID, _pID, msg.value, _eventData_);
        
        // if round is not active     
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false) 
            {
                // end the round (distributes pot) & start new round
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);
                
                // fire buy and distribute event 
                emit F3Devents.onBuyAndDistribute
                (
                    msg.sender, 
                    msg.value, 
                    _eventData_.winnerAddr, 
                    _eventData_.amountWon, 
                    _eventData_.newPot, 
                    _eventData_.TeamAmount, 
                    _eventData_.genAmount
                );
            }
            
            // put eth in players vault 
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    
    /**
     * @dev logic runs whenever a reload order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not 
     */
    function reLoadCore(uint256 _pID, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // if round is active
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            // get earnings from all vaults and return unused to gen vault
            // because we use a custom safemath library.  this will throw if player 
            // tried to spend more eth than they have.
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            
            // call core 
            core(_rID, _pID, _eth, _eventData_);
        
        // if round is not active and end round needs to be ran   
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
            // end the round (distributes pot) & start new round
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
                
            // fire buy and distribute event 
            emit F3Devents.onReLoadAndDistribute
            (
                msg.sender, 
                _eventData_.winnerAddr, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.TeamAmount, 
                _eventData_.genAmount
            );
        }
    }
    
    /**
     * @dev this is the core logic for any buy/reload that happens while a round 
     * is live.
     */
    function core(uint256 _rID, uint256 _pID, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // if player is new to round
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        
        // if eth left is greater than min eth allowed (sorry no pocket lint)
        if (_eth > 1000000000) 
        {
            
            // mint the new keys
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);
            
            // if they bought at least 1 whole key
            if (_keys >= 1e18)
            {
                updateTimer(_keys, _rID);

                // set new leaders
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;  
            }
            
            // manage airdrops
            uint256 currentPlayerMaxId = playerBook.getMaxPID();
            if (airDropPot_ >= airDropAmountLimit && currentPlayerMaxId >= minPlayerCountForAirdrop)  // airdrop pot 10 eth and players > 30
            {
                airDropCountTracker_++;
                uint256 _totalPrize = airDropAmountLimit;
                
                // airdrop to 10 luck players and give 1 eth per player
                for (uint256 i = 0;i<10;i++){
                    uint256 _prize = airDropAmountLimit / 10;
                    uint256 luckyPid = currentPlayerMaxId / (i + 1);
                    plyr_[luckyPid].win = (plyr_[luckyPid].win).add(_prize);   
                }
                
                airDropPot_ = (airDropPot_).sub(_totalPrize);
            }
            
            // update player 
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
            
            // update round
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
    
            // distribute eth
            _eventData_ = distributeExternal(_rID, _pID, _eth, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _keys, _eventData_);
            
            updatelastTenPIDs(_pID);
            
            // call end tx function to fire end tx event.
            endTx(_pID, _eth, _keys, _eventData_);
        }
    }
    
    function updatelastTenPIDs(uint256 _pID)
        private
        returns (bool)
    {
        bool isExist = false;
        for(uint256 i = 9; i>=0;i--){
            if (lastTenPIDs[i] == _pID){
                isExist = true;
                return false;
            }
        }
        if (!isExist){
            for(uint256 j = 9; j>=0;j--){
                if ( j > 0)
                    lastTenPIDs[j] = lastTenPIDs[j - 1];
            }
            lastTenPIDs[0] = _pID;
        }
        return true;
    }
    
    //==============================================================================
    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }
    
    /** 
     * @dev returns the amount of keys you would get given an amount of eth. 
     * -functionhash- 0xce89c80c
     * @param _rID round ID you want price for
     * @param _eth amount of eth sent in 
     * @return keys received 
     */
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else // rounds over.  need keys for new round
            return ( (_eth).keys() );
    }
    
    /** 
     * @dev returns current eth price for X keys.  
     * -functionhash- 0xcf808000
     * @param _keys number of keys desired (in 18 decimal format)
     * @return amount of eth needed to send
     */
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else // rounds over.  need price for new round
            return ( (_keys).eth() );
    }

//==============================================================================
    /**
     * @dev receives name/player info from names contract 
     */
    function receivePlayerInfo(uint256 _pID, address _addr)
        external
    {
        require (msg.sender == address(playerBook), "your not playerNames contract... hmmm..");
        if (pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;
        if (plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;
    }
        
    /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID 
     */
    function determinePID(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        // if player is new to this 
        if (_pID == 0)
        {
            // grab their player ID, name and last aff ID, from player names contract 
            _pID = playerBook.getPlayerID(msg.sender);
            uint256 _laff = playerBook.getPlayerLAff(_pID);
           
            
            // set up player account 
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
            
            
            if (_laff != 0 && _laff != _pID &&  plyr_[_pID].laff != 0)
                plyr_[_pID].laff = _laff;
            
            require(plyr_[_pID].laff != 0, "You Must have a affId");
        } 
        return (_eventData_);
    }
    
    /**
     * @dev decides if round end needs to be run & new round started.  and if 
     * player unmasked earnings from previously played rounds need to be moved.
     */
    function managePlayer(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);
            
        // update player's last round played
        plyr_[_pID].lrnd = rID_;
        
        return(_eventData_);
    }
    
    /**
     * @dev ends the round. manages paying out winner/splitting up pot
     */
    function endRound(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        // setup local rID
        uint256 _rID = rID_;
        
        // grab our winning player and team id's
        uint256 _winPID = round_[_rID].plyr;
        
        // grab our pot amount
        uint256 _pot = round_[_rID].pot;
        
        // calculate our winner share, community rewards, gen share, 
        // p3d share, and amount reserved for next pot 
        uint256 _win = (_pot.mul(48)) / 100;
        uint256 _com = (_pot / 50);
        uint256 _gen = (_pot.mul(potSplit.allBonus)) / 100;
        uint256 _initTeams = (_pot.mul(potSplit.initialTeams)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_initTeams);
        
        // calculate ppt for round mask
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }
        
        // pay our winner
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);
        
        // distribute gen portion to key holders
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = _res;
        
        // start next round
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;
        
        return(_eventData_);
    }
    
    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            // put in gen vault
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            // zero out their earnings by updating mask
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }
    
    /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        // grab time
        uint256 _now = now;
        
        // calculate time based on number of keys bought
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);
        
        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }
    
    function validAffId(uint256 affID)
        private 
        view
        returns (bool)
    {
        return affID > 0 && plyr_[affID].addr != address(0);
    }

    /**
     * @dev distributes eth based on fees to com, aff, and p3d
     */
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        // distribute share to affiliate
        uint256 _aff = _eth / 10;
        uint256 _affID = plyr_[_pID].laff;
        for(uint256 i = 1;i<=9;i++){
            // reward 9 generations 
            if (i >= 2){
                _affID = plyr_[_affID].laff;
                
                if (i >= 2 && i <= 4){
                    // pay 5% to 2-4
                    _aff = _eth / 20;
                } else if (i >= 5 && i<= 9) {
                    // pay 2% to 5-9
                    _aff = _eth / 50;
                }
            }
            if (validAffId(_affID)) {
                plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
                emit F3Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, _rID, _pID, _aff, now);
            }
        }
        
        return(_eventData_);
    }
    
    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        // calculate gen share 40%
        uint256 _gen = (_eth.mul(potSplit.allBonus)) / 100;
        
        // 2% into airdrop pot 
        uint256 _air = (_eth.mul(potSplit.airdrop) / 100);
        airDropPot_ = airDropPot_.add(_air);
        
        // update eth balance (eth = eth - (initialTeams share + aff share + airdrop pot share))
        // _eth = _eth.sub(((_eth.mul(potSplit.affiliateBonus)) / 100).add((_eth.mul(potSplit.initialTeams)) / 100));

        // calculate pot 
        uint256 _pot = (_eth.mul(potSplit.bigPot)) / 100 ;// _eth.sub(_gen);
        
        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
        // add eth to pot
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);
        
        // set up event data
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;
        
        return(_eventData_);
    }

    /**
     * @dev updates masks for round and player when keys are bought
     * @return dust left over 
     */
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
        /* MASKING NOTES
            earnings masks are a tricky thing for people to wrap their minds around.
            the basic thing to understand here.  is were going to have a global
            tracker based on profit per share for each round, that increases in
            relevant proportion to the increase in share supply.
            
            the player will have an additional mask that basically says "based
            on the rounds mask, my shares, and how much i've already withdrawn,
            how much is still owed to me?"
        */
        
        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
            
        // calculate player earning from their own buy (only based on the keys
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);
        
        // calculate & return dust
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }
    
    /**
     * @dev adds up unmasked earnings, & vault earnings, sets them all to 0
     * @return earnings in wei format
     */
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        // update gen vault
        updateGenVault(_pID, plyr_[_pID].lrnd);
        
        // from vaults 
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }
    
    /**
     * @dev prepares compression data and fires event for buy or reload tx's
     */
    function endTx(uint256 _pID, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        emit F3Devents.onEndTx
        (
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.TeamAmount,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }
//=============================================================================
    bool public activated_ = false;
    function activate()
        public
    {
        // only team just can activate 
        require(
            msg.sender == 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C,
            "only team just can activate"
        );
        
        // can only be ran once
        require(activated_ == false, "Monkey already activated");
        
        // activate the contract 
        activated_ = true;
        
        // lets start first round
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }
}