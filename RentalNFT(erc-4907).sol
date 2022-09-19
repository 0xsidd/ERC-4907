// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC4907.sol";


contract ERC4907Contract is ERC721, IERC4907 {

    struct UserInfo 
    {
        address user;   // address of user role
        uint64 expires; // unix timestamp, user expires
    }

    // mapping(address=>mapping(uint256=>uint256))public rentalData;  //add=>count=>time
    // mapping(address=>mapping(uint256=>uint256))public countData;  //address=>tokenId=>count
    // mapping (address=>mapping(uint256=>uint256))public tokenData;   //add=>count=>tokenId
    mapping(uint256=>uint256)public tokenTimeData; //tokenId=>time
    // mapping(uint=>uint[])public nestedTimeData; //tokenId=>count=>time
    mapping (uint256  => UserInfo) public _users;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_)
     ERC721(name_, symbol_)
     {
     }
    
    function setUser(uint256 tokenId, address user, uint64 expiresTimeInSecond) public virtual override{
        uint64 expires = uint64(block.timestamp+expiresTimeInSecond);
        require(user!=msg.sender,"Can not rent to yourself");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC4907: transfer caller is not owner nor approved");
        _users[tokenId] = UserInfo(user,expires);
        // countData[msg.sender][tokenId] +=1;
        // rentalData[msg.sender][countData[msg.sender][tokenId]] = block.timestamp;
        // tokenData[msg.sender][countData[msg.sender][tokenId]] = tokenId;
        tokenTimeData[tokenId] = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    // function setUserAgain(uint256 tokenId,address user,uint64 expiresTimeInSecond)public {
    //     uint64 expires = uint64(block.timestamp+expiresTimeInSecond);
    //     require((userOf(tokenId)==msg.sender)&&(expires>block.timestamp),"Only owner,user are allowed to rent their NFTs or the rental duration is over");
    //     require(ownerOf(tokenId)!=user,"Can not rent NFT to it's owner");
    //     require(user!=userOf(tokenId),"Can not rent to yourself");
    //     require(expires<_users[tokenId].expires,"Expiry time should be less than the previous user's expiry time");


    //     countData[msg.sender][tokenId] +=1;
    //     rentalData[msg.sender][countData[msg.sender][tokenId]] = block.timestamp;
    //     _users[tokenId] = UserInfo(user,expires);
    //     emit UpdateUser(tokenId, user, expires);
    // }

    function getTimestamp()public view returns(uint256){
        return(block.timestamp);
    }

     function safeMint(address to) public {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function userOf(uint256 tokenId) public view virtual override returns(address){
        if( uint256(_users[tokenId].expires) >=  block.timestamp){
            return  _users[tokenId].user;
        }
        else{
            return (address(0));
        }
    }

    function userExpires(uint256 tokenId) public view virtual override returns(uint256){
        return _users[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }
} 