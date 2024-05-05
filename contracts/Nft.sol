// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockTeaseSubscriptionNFT is ERC1155, Ownable {
    uint256 public constant SUBSCRIPTION_ID_OFFSET = 1e12; // Offset to ensure uniqueness of subscription IDs
    uint256 public subscriptionIdCounter;

    constructor(address initialOwner) ERC1155("URI")  Ownable(initialOwner) { // Provide URI for metadata
        subscriptionIdCounter = 1;
    }

    // Mint new subscription NFTs
    function mint(address account, uint256 modelId, uint256 amount) external onlyOwner {
        _mint(account, modelId + SUBSCRIPTION_ID_OFFSET, amount, "");
    }

    // Burn subscription NFTs
    function burn(address account, uint256 modelId, uint256 amount) external onlyOwner {
        _burn(account, modelId + SUBSCRIPTION_ID_OFFSET, amount);
    }

    // Override isApprovedForAll to allow marketplace contract to transfer tokens
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return super.isApprovedForAll(account, operator);
    }

    // Set URI for metadata
    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }
}
