// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IBlockTeaseNFTs {
    function mint(address account, uint256 modelId, uint256 subscriptionId, uint256 amount, uint256 duration, uint256 royaltyFee, address royaltyReceiver, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
    function _encodeTokenId(uint256 modelId, uint256 subscriptionId) external pure returns (uint256);
    function expirationTimes(uint256 tokenId) external view returns (uint256);
}

contract ZkNFTMarketplace is ReentrancyGuard, Ownable {
    IBlockTeaseNFTs private nftContract;
    IERC20 public paymentToken;
    AggregatorV3Interface public priceFeed;

    struct Model {
        uint256 priceUSD;  // Price per subscription in USD
        address associatedAddress;  // address, can be used for royalties or creator info
        uint256 royaltyFees; // basis points (e.g., 500 for 5%)
    }

    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }

    mapping(uint256 => Listing) public listings; // tokenId => Listing

    mapping(uint256 => Model) public models;
    event SubscriptionPurchasedWithEth(address indexed subscriber, uint256 modelId, uint256 subscriptionId, uint256 ethAmount, uint256 tokenId);
    event SubscriptionPurchased(address indexed buyer, uint256 modelId, uint256 subscriptionId, uint256 tokenId);
    event ModelUpdated(uint256 modelId, uint256 priceUSD, address associatedAddress, uint256 royaltyFee);
    event NFTListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTSold(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(address _nftContract, address _paymentToken, address _priceFeedAddress) Ownable(msg.sender) {
        nftContract = IBlockTeaseNFTs(_nftContract);
        paymentToken = IERC20(_paymentToken);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
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

        listings[tokenId] = Listing(price, msg.sender, true);
        emit NFTListed(msg.sender, tokenId, price);
    }

    function buyNFT(uint256 tokenId) public payable nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.isListed, "This NFT is not for sale");
        require(msg.value >= listing.price, "Insufficient funds sent");

        // Pay the seller
        payable(listing.seller).transfer(listing.price);

        // Handle royalty payment
        (address royaltyReceiver, uint256 royaltyAmount) = nftContract.royaltyInfo(tokenId, listing.price);
        if (royaltyAmount > 0) {
            payable(royaltyReceiver).transfer(royaltyAmount);
            payable(listing.seller).transfer(listing.price - royaltyAmount);
        } else {
            payable(listing.seller).transfer(listing.price);
        }

        // Transfer the NFT to the buyer
        nftContract.safeTransferFrom(listing.seller, msg.sender, tokenId, 1, "");

        // Update the listing status
        listing.isListed = false;

        emit NFTSold(listing.seller, msg.sender, tokenId, listing.price);
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

    function purchaseSubscription(uint256 modelId, uint256 subscriptionId, uint256 duration) public nonReentrant {
        Model memory model = models[modelId];
        require(paymentToken.transferFrom(msg.sender, address(this), model.priceUSD), "Payment failed");
        uint256 tokenId = nftContract._encodeTokenId(modelId, subscriptionId);
        nftContract.mint(msg.sender, modelId, subscriptionId, 1, duration, model.royaltyFees, model.associatedAddress, "");
        
        emit SubscriptionPurchased(msg.sender, modelId, subscriptionId, tokenId);
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


    // Admin functions to withdraw earnings or manage the contract
    function withdrawPayments(address beneficiary) external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "No funds available");
        require(paymentToken.transfer(beneficiary, balance), "Withdrawal failed");
    }

}
