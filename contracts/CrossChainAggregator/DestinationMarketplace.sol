// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";    
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./BlockTeaseNfts.sol";

contract NFTMarketplace is CCIPReceiver, ReentrancyGuard, Ownable {
    BlockTeaseNFTs private nftContract;
    IERC20 public paymentToken;
    AggregatorV3Interface public priceFeed;
    uint256 public listingId=0;

    struct Model {
        uint256 priceUSD;  // Price per subscription in USD
        address associatedAddress;  // address, can be used for royalties or creator info
        uint256 royaltyFees; // basis points (e.g., 500 for 5%)
    }

    struct Listing {
        uint256 price;
        address seller;
        bool isListed;,
        uint256 tokenId,
    }

    mapping(uint256 => Listing) public listings; // incrementalListingId => Listing

    mapping(uint256 => Model) public models;

    event SubscriptionPurchased(address indexed buyer, uint256 modelId, uint256 subscriptionId, uint256 tokenId);
    event ModelUpdated(uint256 modelId, uint256 priceUSD, address associatedAddress, uint256 royaltyFee);
    event NFTListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTSold(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);
    event SubscriptionPurchasedWithEth(address indexed subscriber, uint256 modelId, uint256 subscriptionId, uint256 ethAmount, uint256 tokenId);

    constructor( address _priceFeedAddress, address _router, address _nftContract, address _paymentToken) Ownable(msg.sender) CCIPReceiver(_router) {
        nftContract = BlockTeaseNFTs(_nftContract);
        paymentToken = IERC20(_paymentToken);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function _ccipReceive(
            Client.Any2EVMMessage memory message
        ) internal override {
        
        // Decode the message to get the modelId, subID, address and the duration
        (uint256 modelId,uint256 subscriptionId, address user, uint256 duration) = abi.decode(message.data, (uint256, uint256, address, uint256));

        Model memory model = models[modelId];
        uint256 tokenId = nftContract._encodeTokenId(modelId, subscriptionId);
        nftContract.mint(user, modelId, subscriptionId, 1, duration, model.royaltyFees, model.associatedAddress, "");
        
        emit SubscriptionPurchased(user, modelId, subscriptionId, tokenId);
    }

    function updateModel(uint256 modelId, uint256 priceUSD, address associatedAddress, uint256 royaltyFee) public onlyOwner {
        models[modelId] = Model(priceUSD, associatedAddress, royaltyFee);
        emit ModelUpdated(modelId, priceUSD, associatedAddress, royaltyFee);
    }

    function updateBatchModels(uint256[] calldata modelIds, uint256[] calldata pricesUSD, address[] calldata associatedAddresses, uint256[] calldata royaltyFees) public onlyOwner {
        require(modelIds.length == pricesUSD.length && modelIds.length == associatedAddresses.length && modelIds.length == royaltyFees.length, "Data length mismatch");
        for (uint256 i = 0; i < modelIds.length; i++) {
            models[modelIds[i]] = Model(pricesUSD[i], associatedAddresses[i], royaltyFees[i]);
            emit ModelUpdated(modelIds[i], pricesUSD[i], associatedAddresses[i], royaltyFees[i]);
        }
    }

    function listNFT(uint256 tokenId, uint256 price) public {
        require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Sender must own the NFT");
        require(nftContract.isApprovedForAll(msg.sender, address(this)), "Contract must be approved to manage NFT");

        listings[listingId] = Listing(price, msg.sender, true, tokenId);
        listingId++;
        emit NFTListed(msg.sender, tokenId, price);
    }


    function buyNFTWithUSDC(uint256 tokenId) public nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.isListed, "This NFT is not for sale");
        require(paymentToken.balanceOf(msg.sender) >= listing.price, "Insufficient funds");
        require(paymentToken.allowance(msg.sender, address(this)) >= listing.price, "Marketplace not authorized to use the required funds");


        // Handle royalty payment
        (address royaltyReceiver, uint256 royaltyAmount) = nftContract.royaltyInfo(tokenId, listing.price);
        if (royaltyAmount > 0) {
            require(paymentToken.transferFrom(msg.sender, royaltyReceiver, royaltyAmount), "Royalty transfer failed");
        }

        // Transfer the purchase price from buyer to the seller
        require(paymentToken.transferFrom(msg.sender, listing.seller, listing.price - royaltyAmount), "Payment transfer failed");

        // Transfer the NFT to the buyer
        nftContract.safeTransferFrom(listing.seller, msg.sender, tokenId, 1, "");

        // Update the listing status
        listing.isListed = false;

        emit NFTSold(listing.seller, msg.sender, tokenId, listing.price);
    }

    function purchaseSubscription(uint256 modelId, uint256 subscriptionId, uint256 duration) public nonReentrant {
        Model memory model = models[modelId];
        require(paymentToken.transferFrom(msg.sender, address(this), model.priceUSD), "Payment failed");
        uint256 tokenId = nftContract._encodeTokenId(modelId, subscriptionId);
        nftContract.mint(msg.sender, modelId, subscriptionId, 1, duration, model.royaltyFees, model.associatedAddress, "");
        
        emit SubscriptionPurchased(msg.sender, modelId, subscriptionId, tokenId);
    }

    // Admin functions to withdraw earnings or manage the contract
    function withdrawPayments(address beneficiary) external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "No funds available");
        require(paymentToken.transfer(beneficiary, balance), "Withdrawal failed");
    }

    function mintUnsafe(uint256 modelId, uint256 subscriptionId, uint256 duration, address user) public {
        Model memory model = models[modelId];
        uint256 tokenId = nftContract._encodeTokenId(modelId, subscriptionId);
        (address royaltyReceiver, uint256 royaltyAmount) = nftContract.royaltyInfo(tokenId, 1);
        nftContract.mint(user, modelId, subscriptionId, 1, duration, royaltyAmount,royaltyReceiver, "");
        
        emit SubscriptionPurchased(user, modelId, subscriptionId,tokenId);
    }

    function purchaseSubscriptionWithEth(uint256 modelId, uint256 subscriptionId, uint256 duration) external payable {
        Model memory model = models[modelId];
        uint256 priceInUsd = model.priceUSD;
        uint256 ethAmountRequired = usdToEth(priceInUsd);
        require(msg.value >= ethAmountRequired, "Insufficient ETH sent");

        uint256 tokenId = nftContract._encodeTokenId(modelId, subscriptionId);
        nftContract.mint(msg.sender, modelId, subscriptionId, 1, duration, model.royaltyFees, model.associatedAddress, "");
        
        emit SubscriptionPurchasedWithEth(msg.sender, modelId, subscriptionId, ethAmountRequired, tokenId);

        // Refund any excess ETH sent
        if (msg.value > ethAmountRequired) {
            payable(msg.sender).transfer(msg.value - ethAmountRequired);
        }
    }

    function fetchLatestPrice() public view returns (int) {
        (, int price,,,) = priceFeed.latestRoundData();
        return price;
    }

    function usdToEth(uint256 usdAmount) public view returns (uint256) {
        int price = fetchLatestPrice();  // Get the latest ETH price in USD
        require(price > 0, "Invalid price feed data");
        return (usdAmount * 1e18) / uint256(price);  // Required Eth based on USD
    }

    // Function to update the payment token contract address
    function updatePaymentToken(address newPaymentTokenAddress) public onlyOwner {
        require(newPaymentTokenAddress != address(0), "Invalid address");
        paymentToken = IERC20(newPaymentTokenAddress);
    }

}
