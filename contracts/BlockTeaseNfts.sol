// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlockTeaseNFTs is ERC1155, AccessControl, ERC1155Burnable, IERC2981 {
    using Strings for uint256;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // Nested mapping to store expiration times for each token ID
    mapping(uint256 => uint256) public expirationTimes; // tokenId => expirationTime
    mapping(uint256 => address) public _royaltyReceivers;
    mapping(uint256 => uint256) public _royaltyFees; // basis points (e.g., 500 for 5%)

    constructor(address defaultAdmin, address minter)
        ERC1155("")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(URI_SETTER_ROLE, defaultAdmin);
    }

    function _setRoyaltyInfo(uint256 tokenId, address receiver, uint256 feeBasisPoints) private {
        _royaltyReceivers[tokenId] = receiver;
        _royaltyFees[tokenId] = feeBasisPoints;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyReceivers[tokenId];
        royaltyAmount = (salePrice * _royaltyFees[tokenId]) / 10000;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

  function mint(address account, uint256 modelId, uint256 subscriptionId, uint256 amount, uint256 duration, uint256 royaltyFee, address royaltyReceiver, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _encodeTokenId(modelId, subscriptionId);
        _mint(account, tokenId, amount, data);
        expirationTimes[tokenId] = block.timestamp + duration;
        _setRoyaltyInfo(tokenId, royaltyReceiver, royaltyFee);
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        require(expirationTimes[tokenId] > block.timestamp, "NFT is expired");
        (uint256 modelId, ) = _decodeTokenId(tokenId);
        string memory baseURI = super.uri(0);
        return string(abi.encodePacked(baseURI, modelId.toString(), ".json"));
    }

    function _encodeTokenId(uint256 modelId, uint256 subscriptionId) public pure returns (uint256) {
        return modelId * 10**18 + subscriptionId;
    }

    function _decodeTokenId(uint256 tokenId) public pure returns (uint256 modelId, uint256 subscriptionId) {
        modelId = tokenId / 10**18;
        subscriptionId = tokenId % 10**18;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
