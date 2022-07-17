// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract NTBListing is
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply
{
    event CreateToken(
        uint256 indexed tokenId,
        address indexed createdBy,
        string indexed name,
        string description,
        string image,
        string metadataCID
    );
    event VoteUp(
        address indexed createdBy,
        uint256 indexed tokenId,
        uint256 amount
    );
    event CreateComment(
        address indexed createdBy,
        uint256 indexed tokenId,
        string commentCID
    );

    using Counters for Counters.Counter;
    Counters.Counter public tokenIdCounter;

    uint256 public createTokenPrice = 0.01 ether;
    uint256 public votePrice = 0.01 ether;

    mapping(uint256 => string) public tokenURIMap;
    mapping(uint256 => address) public tokenOwnerMap;

    // vote
    mapping(address => uint256) public userTotalVoteUpCountMap; // userAddress => userTotalVoteUpAmount
    mapping(uint256 => string[]) public voteUpCIDArrayMap; // tokenId => voteUpCID[], store all cid for every token's voteUp

    // comment
    mapping(uint256 => string[]) public commentCIDArrayMap; // tokenId => commentCID[], store all cid for every token's comment
    mapping(address => string[]) public userCommentCIDArrayMap; // userAddress => commentCID[], store all comment cid for every user

    // profile
    mapping(address => string) public userProfileMap; // userAddress => userProfileCID
    address[] public userProfileAddressList;

    function getTokenDataList(uint256 start, uint256 limit)
        public
        view
        returns (
            string[] memory tokenURIs,
            uint256[] memory voteUpCounts,
            uint256[] memory commentCounts
        )
    {
        uint256 lens = uint256(tokenIdCounter._value - start);
        if (lens < limit) {
            limit = lens;
        }

        tokenURIs = new string[](limit);
        voteUpCounts = new uint256[](limit);
        commentCounts = new uint256[](limit);

        for (uint256 i = 0; i < limit; i++) {
            tokenURIs[i] = tokenURIMap[start + i];
            voteUpCounts[i] = totalSupply(start + i);
            commentCounts[i] = commentCIDArrayMap[start + i].length;
        }
    }

    function getList(
        uint256 dataType,
        uint256 tokenId,
        uint256 start,
        uint256 limit
    ) public view returns (string[] memory arr_) {
        string[] memory all = voteUpCIDArrayMap[tokenId];
        if (dataType == 1) {
            all = commentCIDArrayMap[tokenId];
        }

        uint256 lens = all.length - start;
        if (lens < limit) {
            limit = lens;
        }
        arr_ = new string[](limit);

        for (uint256 i = 0; i < limit; i++) {
            arr_[i] = all[start + i];
        }
    }

    function getUserList(uint256 start, uint256 limit)
        public
        view
        returns (string[] memory arr_)
    {
        uint256 lens = userProfileAddressList.length - start;
        if (lens < limit) {
            limit = lens;
        }
        arr_ = new string[](limit);

        for (uint256 i = 0; i < limit; i++) {
            arr_[i] = userProfileMap[userProfileAddressList[start + i]];
        }
    }

    function updateProfile(string memory profileCID) public whenNotPaused {
        require(bytes(profileCID).length > 0, "profileCID is empty");
        address createdBy = _msgSender();

        if (bytes(userProfileMap[createdBy]).length == 0) {
            userProfileAddressList.push(createdBy);
        }
        userProfileMap[createdBy] = profileCID;
    }

    /* solhint-disable func-visibility */
    constructor() ERC1155("") {
        _setURI("");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory tokenURI = tokenURIMap[tokenId];
        return tokenURI;
    }

    function createToken(
        string memory name,
        string memory description,
        string memory image,
        string memory metadataCID
    ) public payable whenNotPaused {
        require(bytes(metadataCID).length > 0, "metadataCID is empty");
        require(
            msg.value >= createTokenPrice,
            "insufficient funds for createToken"
        );

        address createdBy = _msgSender();

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        tokenURIMap[tokenId] = metadataCID;
        tokenOwnerMap[tokenId] = createdBy;

        emit CreateToken(
            tokenId,
            createdBy,
            name,
            description,
            image,
            metadataCID
        );
    }

    function updateToken(uint256 tokenId, string memory metadataCID)
        public
        whenNotPaused
    {
        require(bytes(metadataCID).length > 0, "metadataCID is empty");
        address createdBy = _msgSender();
        require(
            tokenOwnerMap[tokenId] == createdBy,
            "you are not the token creator"
        );

        tokenURIMap[tokenId] = metadataCID;
        tokenOwnerMap[tokenId] = createdBy;
    }

    function voteUp(
        uint256 tokenId,
        uint256 amount,
        string memory voteUpCID,
        string memory commentCID
    ) public payable whenNotPaused {
        require(bytes(tokenURIMap[tokenId]).length > 0, "token not create yet");
        require(
            msg.value >= votePrice * amount,
            "insufficient funds for createToken"
        );

        address createdBy = _msgSender();

        // voteUp
        _mint(createdBy, tokenId, amount, "");
        userTotalVoteUpCountMap[createdBy] += amount;
        voteUpCIDArrayMap[tokenId].push(voteUpCID);
        emit VoteUp(createdBy, tokenId, amount);

        // comment
        if (bytes(commentCID).length > 0) {
            commentCIDArrayMap[tokenId].push(commentCID);
            userCommentCIDArrayMap[createdBy].push(commentCID);
            emit CreateComment(createdBy, tokenId, commentCID);
        }
    }

    /* solhint-disable */
    function withdraw(address withdrawTo) public onlyOwner {
        (bool hs, ) = payable(withdrawTo).call{value: (address(this).balance)}(
            ""
        );
        require(hs, "Failed to withdraw");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
