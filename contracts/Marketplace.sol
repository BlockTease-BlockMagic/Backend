// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockTeaseMarketplace is Ownable {
    IERC1155 public nftContract;
    uint256 public constant SUBSCRIPTION_ID_OFFSET = 1e12; // Offset to ensure uniqueness of subscription IDs
    mapping(uint256 => uint256) public subscriptionPrices; // Mapping from subscription NFT ID to price

    event SubscriptionListed(uint256 indexed subscriptionId, uint256 price);
    event SubscriptionPurchased(address indexed buyer, uint256 subscriptionId);

    constructor(address initialOwner, address _nftContract) Ownable(initialOwner) {
        nftContract = IERC1155(_nftContract);
    }

    function listSubscription(uint256 modelId, uint256 price) external onlyOwner {
        uint256 subscriptionId = modelId + SUBSCRIPTION_ID_OFFSET;
        subscriptionPrices[subscriptionId] = price;
        emit SubscriptionListed(subscriptionId, price);
    }

    function purchaseSubscription(uint256 subscriptionId) external payable {
        uint256 price = subscriptionPrices[subscriptionId];
        require(price > 0, "Subscription not listed");
        require(msg.value == price, "Incorrect payment amount");

        nftContract.safeTransferFrom(address(this), msg.sender, subscriptionId, 1, "");
        emit SubscriptionPurchased(msg.sender, subscriptionId);
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }
}
