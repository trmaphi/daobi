// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DaobiChancellorsSeal is ERC721URIStorage, ERC721Enumerable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SEAL_MANAGER = keccak256("SEAL_MANAGER");
    string public URIaddr;

    event SealURIRetarget(string newAddr);
    event SealBurnt();
    event SealMinted(address indexed mintee);

    constructor() ERC721("DAObi Chancellor's Seal", "DAOBI SEAL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(SEAL_MANAGER, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _increaseBalance(address addr, uint128 value) internal override(ERC721, ERC721Enumerable) {
        // Call parent implementations of `_burn`.
        super._increaseBalance(addr, value);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721Enumerable, ERC721) returns (address){
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
        override(AccessControl, ERC721URIStorage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setURI(string memory newURI) public onlyRole(SEAL_MANAGER) {
        URIaddr = newURI;
        emit SealURIRetarget(newURI);
    }

    function mint(address to) public onlyRole(SEAL_MANAGER) {
        require(totalSupply() == 0, "A Chancellor Seal Already Exists!");
        _safeMint(to, 1);
        _setTokenURI(1, URIaddr);
        emit SealMinted(to);
    }

    function burn() public onlyRole(SEAL_MANAGER) {
        require(totalSupply() > 0, "No seal to burn!");
        _burn(1);
        emit SealBurnt();
    }


    /*function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return URIaddr;
    }*/



}
