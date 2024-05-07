// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PurchaseSubscription {
    address public owner;
    IERC20 public stablecoin;

    struct Subscription {
        uint256 modelId;
        uint256 subscriptionId;
        uint256 priceInUsd; // Price in USD
    }

    mapping(address => Subscription[]) public subscriptions;

    // Events
    event SubscribedWithToken(address indexed subscriber, uint256 modelId, uint256 subscriptionId, uint256 priceInUsd);
    event SubscribedWithEth(address indexed subscriber, uint256 modelId, uint256 subscriptionId, uint256 ethAmount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _stablecoinAddress) {
        owner = msg.sender;
        stablecoin = IERC20(_stablecoinAddress);

    }

    function subscribeWithToken(uint256 modelId, uint256 subscriptionId, uint256 priceInUsd) external {
        require(stablecoin.transferFrom(msg.sender, address(this), priceInUsd), "Transfer failed");
        Subscription memory newSubscription = Subscription({
            modelId: modelId,
            subscriptionId: subscriptionId,
            priceInUsd: priceInUsd
        });
        subscriptions[msg.sender].push(newSubscription);
        emit SubscribedWithToken(msg.sender, modelId, subscriptionId, priceInUsd);
    }
}