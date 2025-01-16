// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./IDAObi.sol";

contract DaobiVoteContract is ERC721, ERC721URIStorage, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Can pause contract
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Can mint new tokens
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // Can burn tokens
    bytes32 public constant NFT_MANAGER = keccak256("NFT_MANAGER"); // Manages NFT functionality
    bytes32 public constant VOTE_ADMIN_ROLE = keccak256("VOTE_ADMIN_ROLE");
    bytes32 public constant MINREQ_ROLE = keccak256("MINREQ_ROLE");

    struct Voter {
        address votedFor;
        bool serving;
        uint160 votesAccrued;
        bytes32 courtName;
        uint32 voteDate;
        bytes19 __gap; // Gap for future use
    }

    mapping(address => Voter) public voterRegistry;
    string public URIaddr;
    uint256 public propertyRequirement;
    address payable public tokenContract;
    IDAObi daobi;

    uint256 public stake_amount; // Default stake amount
    mapping(address => uint256) public stakes;

    event NewToken(address indexed newDBvt);
    event Registered(address indexed regVoter, bytes32 nickname, address initVote);
    event Reclused(address indexed reclVoter);
    event Voted(address indexed voter, address indexed votee);
    event Burnt(address indexed burnee);
    event SelfBurnt(address indexed burner);
    event NFTRetarget(string newURI);

    constructor() ERC721("DAObi Voting Token", "DBvt") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(NFT_MANAGER, msg.sender);
        _grantRole(VOTE_ADMIN_ROLE, msg.sender);
        _grantRole(MINREQ_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setURI(string memory newURI) public onlyRole(NFT_MANAGER) {
        URIaddr = newURI;
        emit NFTRetarget(newURI);
    }

    /*function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return URIaddr;
    }*/

    function refreshTokenURI() public {
        require(ownerOf(uint160(address(msg.sender))) == msg.sender, "Only token owner can update URI");
        _setTokenURI(uint160(address(msg.sender)), URIaddr);
    }

    function mint(address to) public onlyRole(MINTER_ROLE) {
        require(balanceOf(to) == 0, "Account already has a token");
        daobi.transferFrom(to, address(this), stake_amount);
        stakes[to] = stake_amount;
        _safeMint(to, uint160(to));
        _setTokenURI(uint160(to), URIaddr);
        emit NewToken(to);
    }

    function targetDaobi(address payable _daobi) public onlyRole(VOTE_ADMIN_ROLE) {
        tokenContract = _daobi;
        daobi = IDAObi(_daobi);
    }

    function setMinimumTokenReq(uint256 _minDB) public onlyRole(MINREQ_ROLE) {
        propertyRequirement = _minDB;
    }

    function register(address _initialVote, bytes32 _name) public {
        require(balanceOf(msg.sender) > 0, "You must hold a token to register");
        require(!voterRegistry[msg.sender].serving, "Already registered");
        require(balanceOf(_initialVote) > 0 || _initialVote == address(0), "Invalid candidate");
        require(daobi.balanceOf(msg.sender) >= propertyRequirement, "Insufficient balance");

        if (stakes[msg.sender] == 0) {
            daobi.transferFrom(msg.sender, address(this), stake_amount);
            stakes[msg.sender] = stake_amount;
        }

        voterRegistry[msg.sender] = Voter(_initialVote, true, 0, _name, uint32(block.timestamp % 2**32), 0);
        voterRegistry[_initialVote].votesAccrued++;
        emit Registered(msg.sender, _name, _initialVote);
    }

    function recluse() public {
        require(voterRegistry[msg.sender].serving, "Already inactive");
        voterRegistry[msg.sender].serving = false;
        voterRegistry[voterRegistry[msg.sender].votedFor].votesAccrued--;
        voterRegistry[msg.sender].votedFor = address(0);

        uint256 stakedAmount = stakes[msg.sender];
        if (stakedAmount > 0) {
            delete stakes[msg.sender];
            daobi.transfer(msg.sender, stakedAmount);
        }

        emit Reclused(msg.sender);
    }

    function vote(address _voteFor) public {
        require(balanceOf(msg.sender) > 0, "You don't have a token");
        require(voterRegistry[msg.sender].serving, "Not registered");
        require(balanceOf(_voteFor) > 0 || _voteFor == address(0), "Invalid candidate");
        require(daobi.balanceOf(msg.sender) >= propertyRequirement, "Insufficient balance");

        voterRegistry[voterRegistry[msg.sender].votedFor].votesAccrued--;
        voterRegistry[msg.sender].votedFor = _voteFor;
        voterRegistry[msg.sender].voteDate = uint32(block.timestamp % 2**32);
        voterRegistry[_voteFor].votesAccrued++;
        emit Voted(msg.sender, _voteFor);
    }

    function burn(address _account) public onlyRole(BURNER_ROLE) {
        require(balanceOf(_account) > 0, "No token to burn");
        voterRegistry[_account].serving = false;
        _burn(uint160(_account));
        emit Burnt(_account);
    }

    function selfImmolate() public {
        require(balanceOf(msg.sender) > 0, "No token to burn");
        voterRegistry[msg.sender].serving = false;
        _burn(uint160(msg.sender));
        emit SelfBurnt(msg.sender);
    }

    function assessVotes(address _voter) public view returns (uint160) {
        return voterRegistry[_voter].votesAccrued;
    }

    function seeBallot(address _voter) public view returns (address) {
        return voterRegistry[_voter].votedFor;
    }

    function checkStatus(address _voter) public view returns (bool) {
        return voterRegistry[_voter].serving;
    }

    function getAlias(address _voter) public view returns (bytes32) {
        return voterRegistry[_voter].courtName;
    }

    function getVoteDate(address _voter) public view returns (uint32) {
        return voterRegistry[_voter].voteDate;
    }

    function _increaseBalance(address addr, uint128 value) internal override(ERC721) {
        // Call parent implementations of `_burn`.
        super._increaseBalance(addr, value);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address){
        super._update(to, tokenId, auth);
    }

    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721URIStorage, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
