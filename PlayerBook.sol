pragma solidity ^0.4.24;

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
        plyr_[1].addr = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
        pIDxAddr_[0xca35b7d915458ef540ade6068dfe2f44e8fa733c] = 1;
        
        plyr_[2].addr = 0x8b4DA1827932D71759687f925D17F81Fc94e3123;
        pIDxAddr_[0x8b4DA1827932D71759687f925D17F81Fc94e3123] = 2;
        
        plyr_[3].addr = 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce123;
        pIDxAddr_[0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce123] = 3;
        
        plyr_[4].addr = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C;
        pIDxAddr_[0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C] = 4;
        
        plyr_[5].addr = 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53;
        pIDxAddr_[0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53] = 5;
        
        plyr_[6].addr = 0x8b4DA1827932D71759687f925D17F81Fc94e3124;
        pIDxAddr_[0x8b4DA1827932D71759687f925D17F81Fc94e3124] = 6;
        
        plyr_[7].addr = 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce124;
        pIDxAddr_[0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce124] = 7;
        
        plyr_[8].addr = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D7123;
        pIDxAddr_[0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D7123] = 8;
        
        plyr_[9].addr = 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D7124;
        pIDxAddr_[0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D7124] = 9;
        
        pID_ = 9;
    }

    //==============================================================================
    function determinePID(address _addr, uint256 affID)
        private
        returns (uint256)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;
            require (affID > 0 && plyr_[affID].addr != address(0), "Invalid affId");
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