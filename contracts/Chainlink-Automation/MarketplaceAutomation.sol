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

import "./BlockTeaseNfts.sol";

contract NFTMarketplaceAutomation is CCIPReceiver, ReentrancyGuard, Ownable, AutomationCompatibleInterface, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    string public lastConfirmationMsg;

    error UnexpectedRequestID(bytes32 requestId);
    event UnexpectedRequestIDError(bytes32 indexed requestId);
    event DecodingFailed(bytes32 indexed requestId);
    event ResponseError(bytes32 indexed requestId, bytes err);
    event Response(bytes32 indexed requestId, string response, bytes err);

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

    uint32 gasLimit = 270_000;
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
    }

    uint256[] public subscriptions;
    mapping(uint256 => Subscription) public tokenIdToSubscription;
    mapping(uint256 => Model) public models;

    event SubscriptionPurchased(address indexed buyer, uint256 modelId, uint256 subscriptionId, uint256 tokenId);
    event ModelUpdated(uint256 modelId, uint256 priceUSD, address associatedAddress, uint256 royaltyFee, uint256 duration);

    constructor(address _priceFeedAddress, address _routerCrossChain, address _nftContract, address _paymentToken) Ownable(msg.sender) CCIPReceiver(_routerCrossChain) FunctionsClient(router) {
        nftContract = BlockTeaseNFTs(_nftContract);
        paymentToken = IERC20(_paymentToken);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        (uint256 modelId, uint256 subscriptionId, address user) = abi.decode(message.data, (uint256, uint256, address));

        Model memory model = models[modelId];
        uint256 tokenId = nftContract._encodeTokenId(modelId, subscriptionId);
        nftContract.mint(user, modelId, subscriptionId, 1, model.duration, model.royaltyFees, model.associatedAddress, "");

        subscriptions.push(tokenId);
        tokenIdToSubscription[tokenId] = Subscription(tokenId, block.timestamp + model.duration, modelId, user);

        emit SubscriptionPurchased(user, modelId, subscriptionId, tokenId);
    }

    function updateModel(uint256 modelId, uint256 priceUSD, address associatedAddress, uint256 royaltyFee, uint256 duration) public onlyOwner {
        models[modelId] = Model(priceUSD, associatedAddress, royaltyFee, duration);
        emit ModelUpdated(modelId, priceUSD, associatedAddress, royaltyFee, duration);
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256[] memory expiredTokenIds = new uint256[](subscriptions.length);
        uint256 counter = 0;

        for (uint256 i = 0; i < subscriptions.length; i++) {
            uint256 tokenId = subscriptions[i];
            if (tokenIdToSubscription[tokenId].expirationTime <= block.timestamp) {
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
            } else {
                string[] memory args = new string[](2);
                args[0] = toAsciiString(subscription.owner);
                args[1] = uintToString(subscription.tokenId);

                sendRequest(2825, args);
            }
        }
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
        tokenIdToSubscription[tokenId] = Subscription(tokenId, block.timestamp + model.duration, modelId, msg.sender);

        emit SubscriptionPurchased(msg.sender, modelId, subscriptionId, tokenId);
    }

    function updatePaymentToken(address newPaymentTokenAddress) public onlyOwner {
        require(newPaymentTokenAddress != address(0), "Invalid address");
        paymentToken = IERC20(newPaymentTokenAddress);
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