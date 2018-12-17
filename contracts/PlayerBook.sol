pragma solidity ^0.4.23;

import "./SafeMath.sol";
import "./PlayerDatasets.sol";

contract PlayerBook {
    using SafeMath for uint256;

    uint256 public pID_;        // total number of players
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (uint256 => PlayerDatasets.Player) public plyr_;               // (pID => data) player data

    constructor()
        public
    {
        plyr_[1].addr = 0xb42b160895Db93874073Bf032174b7597e0fdB82;
        pIDxAddr_[0xb42b160895Db93874073Bf032174b7597e0fdB82] = 1;
        
        plyr_[2].addr = 0xBD0fB7781990279c26C3c996998Cf4768C706F88;
        pIDxAddr_[0xBD0fB7781990279c26C3c996998Cf4768C706F88] = 2;
        
        plyr_[3].addr = 0xFEA345c648D8D13d44AAb7A4d730D0C4eeDB7F34;
        pIDxAddr_[0xFEA345c648D8D13d44AAb7A4d730D0C4eeDB7F34] = 3;
        
        plyr_[4].addr = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C;
        pIDxAddr_[0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C] = 4;
        
        plyr_[5].addr = 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53;
        pIDxAddr_[0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53] = 5;
        
        plyr_[6].addr = 0x7553664189200a33be0932B8C39771C9248DFEB1;
        pIDxAddr_[0x7553664189200a33be0932B8C39771C9248DFEB1] = 6;
        
        plyr_[7].addr = 0xf9EEc40e933F82896A682a63E1277232b99C64E1;
        pIDxAddr_[0xf9EEc40e933F82896A682a63E1277232b99C64E1] = 7;
        
        plyr_[8].addr = 0xaE25a93A3D7766F5dF24333a0Ef97351ce49e66d;
        pIDxAddr_[0xaE25a93A3D7766F5dF24333a0Ef97351ce49e66d] = 8;
        
        plyr_[9].addr = 0x4591f7a860A28819FC010c842983c548A44d0f26;
        pIDxAddr_[0x4591f7a860A28819FC010c842983c548A44d0f26] = 9;
        
        pID_ = 9;
    }

    //==============================================================================
    function determinePID(address _addr, uint256 affID)
        private
        returns (uint256)
    {
        require (affID > 0 && plyr_[affID].addr != address(0), "Invalid affId");
        require (affID != pIDxAddr_[_addr], "can not be self");
        
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;
            if (plyr_[pID_].laff == 0){
                plyr_[pID_].laff = affID;
                // plyr_[affID].subPlys.push(pID_);
            }
            return (pID_);
        } else {
            return (0);
        }
    }

    //==============================================================================
    
    function registerPlayerID(address _addr, uint256 affID)
        external
        returns (uint256)
    {
        return determinePID(_addr, affID);
    }
    
    function getPlayerID(address _addr)
        external
        view
        returns (uint256)
    {
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
    
    function getPlayerSubPlys(uint256 _pID)
        external
        view 
        returns(uint256)
    {
        return plyr_[_pID].subPlys;
    }
    
    function getMaxPID() 
        external
        view
        returns (uint256 )
    {
        return pID_;
    }
}