// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import "./BlockTeaseNfts.sol";

contract NFTMarketplaceAutomationVrf is VRFConsumerBaseV2Plus, CCIPReceiver, ReentrancyGuard, AutomationCompatibleInterface, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    uint256 public s_subscriptionId=292;
    address public vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 public s_keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint32 public callbackGasLimit = 40000;

    uint16 public requestConfirmations = 3;

    uint32 public numWords = 1;

    uint256 public luckySubscriberId;


    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    string public lastConfirmationMsg;

    error UnexpectedRequestID(bytes32 requestId);
    event SubscriptionPaused(uint256 indexed subscriptionId, address indexed pausedBy);
    event requestLuckySubscriberEvent(uint256 indexed requestId);
    event luckySubcriberSuccess(uint256 indexed requestId, uint256 subcricriptionId);
    event UnexpectedRequestIDError(bytes32 indexed requestId);
    event DecodingFailed(bytes32 indexed requestId);
    event ResponseError(bytes32 indexed requestId, bytes err);
    event Response(bytes32 indexed requestId, string response, bytes err);
    event RoyaltiesPaid(uint256 indexed tokenId, address indexed beneficiary, uint256 amount);

    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    string source = 
        "const walletAddress = args[0];"
        "const tokenId = args[1];"
        "const url = `https://chainlink-ntfn-service-blocktease.onrender.com/send-email`;"
        "console.log(`HTTP GET Request to ${url}?wallet_address=${walletAddress}&tokenId=${tokenId}`);"
        "const emailRequest = Functions.makeHttpRequest({"
        "  url: url,"
        "  headers: {"
        "    'Content-Type': 'application/json',"
        "  },"
        "  timeout: 9000,"
        "  params: {"
        "    wallet_address: walletAddress,"
        "    tokenId: tokenId,"
        "  },"
        "});"
        "const emailResponse = await emailRequest;"
        "console.log(`Email sent successfully to wallet address ${walletAddress} with tokenId ${tokenId}`);"
        "return Functions.encodeString(`Email sent successfully to wallet address ${walletAddress} with tokenId ${tokenId}`);";

    uint32 gasLimit = 300_000;
    bytes32 donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    BlockTeaseNFTs private nftContract;
    IERC20 public paymentToken;
    AggregatorV3Interface public priceFeed;

    struct Model {
        uint256 priceUSD;
        address associatedAddress;
        uint256 royaltyFees;
        uint256 duration;
    }

    struct Subscription {
        uint256 tokenId;
        uint256 expirationTime;
        uint256 modelId;
        address owner;
        bool paused;
        uint8 ntfnAttempts;
    }

    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isListed;
    }

    uint256[] public subscriptions;
    mapping(uint256 => Subscription) public tokenIdToSubscription;
    mapping(uint256 => Model) public models;
    mapping(uint256 => Listing) public listings;
    uint256 public listingId;

    event SubscriptionPurchased(address indexed buyer, uint256 modelId, uint256 subscriptionId, uint256 tokenId);
    event ModelUpdated(uint256 modelId, uint256 priceUSD, address associatedAddress, uint256 royaltyFee, uint256 duration);
    event NFTListed(uint256 indexed listingId, uint256 indexed tokenId, uint256 price, address indexed seller);
    event NFTSold(uint256 indexed listingId, uint256 indexed tokenId, uint256 price, address indexed buyer);

    constructor(address _priceFeedAddress, address _routerCrossChain, address _nftContract, address _paymentToken) CCIPReceiver(_routerCrossChain) FunctionsClient(router) VRFConsumerBaseV2Plus(vrfCoordinator) {
        nftContract = BlockTeaseNFTs(_nftContract);
        paymentToken = IERC20(_paymentToken);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        listingId = 1;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        (uint256 modelId, uint256 subscriptionId, address user, uint256 duration) = abi.decode(message.data, (uint256, uint256, address, uint256));

        Model memory model = models[modelId];
        uint256 tokenId = nftContract._encodeTokenId(modelId, subscriptionId);
        nftContract.mint(user, modelId, subscriptionId, 1, model.duration, model.royaltyFees, model.associatedAddress, "");

        subscriptions.push(tokenId);
        tokenIdToSubscription[tokenId] = Subscription(tokenId, block.timestamp + model.duration, modelId, user, false, 0);

        emit SubscriptionPurchased(user, modelId, subscriptionId, tokenId);
    }

    function updateModel(uint256 modelId, uint256 priceUSD, address associatedAddress, uint256 royaltyFee, uint256 duration) public onlyOwner {
        models[modelId] = Model(priceUSD, associatedAddress, royaltyFee, duration);
        emit ModelUpdated(modelId, priceUSD, associatedAddress, royaltyFee, duration);
    }

    function updateBatchModels(uint256[] memory modelIds, uint256[] memory pricesUSD, address[] memory associatedAddresses, uint256[] memory royaltyFees, uint256[] memory durations) public onlyOwner {
        require(modelIds.length == pricesUSD.length, "Array length mismatch");
        require(pricesUSD.length == associatedAddresses.length, "Array length mismatch");
        require(associatedAddresses.length == royaltyFees.length, "Array length mismatch");
        require(royaltyFees.length == durations.length, "Array length mismatch");

        for (uint256 i = 0; i < modelIds.length; i++) {
            models[modelIds[i]] = Model(pricesUSD[i], associatedAddresses[i], royaltyFees[i], durations[i]);
            emit ModelUpdated(modelIds[i], pricesUSD[i], associatedAddresses[i], royaltyFees[i], durations[i]);
        }
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256[] memory expiredTokenIds = new uint256[](subscriptions.length);
        uint256 counter = 0;

        for (uint256 i = 0; i < subscriptions.length; i++) {
            uint256 tokenId = subscriptions[i];
            Subscription memory subscription = tokenIdToSubscription[tokenId];
            if (subscription.expirationTime <= block.timestamp && !subscription.paused) {
                expiredTokenIds[counter] = tokenId;
                counter++;
            }
        }

        upkeepNeeded = counter > 0;
        assembly {
            mstore(expiredTokenIds, counter)
        }
        performData = abi.encode(expiredTokenIds);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256[] memory expiredTokenIds = abi.decode(performData, (uint256[]));

        for (uint256 i = 0; i < expiredTokenIds.length; i++) {
            uint256 tokenId = expiredTokenIds[i];
            Subscription storage subscription = tokenIdToSubscription[tokenId];
            Model memory model = models[subscription.modelId];

            if (paymentToken.balanceOf(subscription.owner) >= model.priceUSD && paymentToken.allowance(subscription.owner, address(this)) >= model.priceUSD) {
                require(paymentToken.transferFrom(subscription.owner, address(this), model.priceUSD));
                subscription.expirationTime = block.timestamp + model.duration;
                subscription.ntfnAttempts = 0;  // Reset failed attempts on successful payment
            } else {
                subscription.ntfnAttempts++;
                if (subscription.ntfnAttempts >= 2) {
                    subscription.paused = true;
                }

                string[] memory args = new string[](2);
                args[0] = toAsciiString(subscription.owner);
                args[1] = uintToString(subscription.tokenId);

                sendRequest(2825, args);
            }
        }
    }

    function listNft(uint256 tokenId, uint256 price) external {
        Subscription memory subscription = tokenIdToSubscription[tokenId];
        require(subscription.owner == msg.sender, "Only the owner can list this NFT");
        require(!subscription.paused, "Paused subscriptions cannot be listed");

        listings[listingId] = Listing(tokenId, price, msg.sender, true);
        emit NFTListed(listingId, tokenId, price, msg.sender);
        listingId++;
    }

    function buyNft(uint256 _listingId) external nonReentrant {
        Listing storage listing = listings[_listingId];
        require(listing.isListed, "NFT not listed for sale");
        require(paymentToken.balanceOf(msg.sender) >= listing.price, "Insufficient balance");
        require(paymentToken.allowance(msg.sender, address(this)) >= listing.price, "Insufficient allowance");

        Subscription storage subscription = tokenIdToSubscription[listing.tokenId];
        Model memory model = models[subscription.modelId];
        uint256 royaltyAmount = (listing.price * model.royaltyFees) / 10000;  // Assuming royaltyFees is in basis points (e.g., 500 for 5%)
        uint256 sellerAmount = listing.price - royaltyAmount;

        require(paymentToken.transferFrom(msg.sender, model.associatedAddress, royaltyAmount), "Failed to pay royalties");
        require(paymentToken.transferFrom(msg.sender, listing.seller, sellerAmount), "Failed to pay seller");

        nftContract.safeTransferFrom(subscription.owner, msg.sender, subscription.tokenId, 1, "");
        subscription.owner = msg.sender;
        listing.isListed = false;

        emit RoyaltiesPaid(listing.tokenId, model.associatedAddress, royaltyAmount);
        emit NFTSold(_listingId, listing.tokenId, listing.price, msg.sender);
    }

    function sendRequest(uint64 subscriptionId, string[] memory args) public returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        if (args.length > 0) req.setArgs(args);
        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);
        return s_lastRequestId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_lastRequestId != requestId) {
            emit Response(requestId, string(response), err);
            return;
        }
        s_lastResponse = response;
        s_lastError = err;
        lastConfirmationMsg = string(response);
        emit Response(requestId, lastConfirmationMsg, s_lastError);
    }

    function purchaseSubscription(uint256 modelId, uint256 subscriptionId) public nonReentrant {
        Model memory model = models[modelId];
        require(paymentToken.transferFrom(msg.sender, address(this), model.priceUSD), "Payment failed");
        uint256 tokenId = nftContract._encodeTokenId(modelId, subscriptionId);
        nftContract.mint(msg.sender, modelId, subscriptionId, 1, model.duration, model.royaltyFees, model.associatedAddress, "");

        subscriptions.push(tokenId);
        tokenIdToSubscription[tokenId] = Subscription(tokenId, block.timestamp + model.duration, modelId, msg.sender, false, 0);

        emit SubscriptionPurchased(msg.sender, modelId, subscriptionId, tokenId);
    }

    function updatePaymentToken(address newPaymentTokenAddress) public onlyOwner {
        require(newPaymentTokenAddress != address(0), "Invalid address");
        paymentToken = IERC20(newPaymentTokenAddress);
    }

    function requestLuckySubscriber() public onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit requestLuckySubscriberEvent(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 randomSubcriptionId = (randomWords[0] % subscriptions.length) + 1;
        luckySubscriberId = randomSubcriptionId;
        uint256 tokenId = subscriptions[luckySubscriberId];
        Subscription storage subscription = tokenIdToSubscription[tokenId];
        Model memory model = models[subscription.modelId];
        subscription.expirationTime = block.timestamp + model.duration;
        emit luckySubcriberSuccess(requestId, randomSubcriptionId);
    }

    function pauseSubscription(uint256 subscriptionId) external onlyOwner {
        require(tokenIdToSubscription[subscriptionId].tokenId != 0, "Subscription does not exist.");
        Subscription storage subscription = tokenIdToSubscription[subscriptionId];
        require(!subscription.paused, "Subscription already paused.");
        subscription.paused = true;
        emit SubscriptionPaused(subscriptionId, msg.sender);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uintToString(uint v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }
        uint j = v;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (v != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(v - v / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            v /= 10;
        }
        return string(bstr);
    }
}