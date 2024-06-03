# 💘 BlockTease 💌
Welcome to **BlockTease** — the ultimate fusion of **OnlyFans'** 🕊 charm with the transformative power of Web3! 🚀🌐 Dive into a world where privacy, decentralization, and seamless interactions are not just ideals but vibrant realities.

![image](https://github.com/BlockTease-BlockMagic/Backend/assets/40585900/d2d92f52-068d-4861-ae21-95a7a74fed89)

## Exciting Features ⚡

- 🚀 **Hassle-Free Onboarding**: 

  Join effortlessly with **Smart Accounts** that bridge Web2 and Web3. Get started without deep blockchain knowledge — a simple, barrier-free entry into the exciting world of decentralized        applications. 

- 🎨 **Dynamic NFT Avatar Generation**: 

    Create your unique digital identity with OpenAI's DALL-E, seamlessly integrated through **Chainlink Functions** to mint dynamic NFT avatars. Thanks to **Biconomy Paymaster**, these are     offered **free of charge** for new users, adding a personal touch from day one! 

- 🔄 **Autopay Creator Subscriptions**: 

    Never miss content from your favorite creators! Our **Chainlink Automation** setup wraps **Chainlink Functions** with nodemailer to keep you informed about your subscription status automatically. 

- 🔗🌍 **Cross-Chain Subscriptions with Custom Pricefeeds**: 

    Enjoy the freedom to follow and support creators across multiple blockchains, thanks to **Chainlink CCIP** & **Chainlink PriceFeeds**. No worries about single chain liquidity — subscribe anywhere, anytime! 

- 💸 **Gasless and Bundled Transactions**: 

    Experience the smoothest UX yet with Smart Account gasless and bundled transactions. Approve NFTs, make payments, and manage subscriptions all in one go, without the usual gas fees. 

-  🎲📞 **Monthly Lucky Subscriber Draw**: 

    Join the excitement with our monthly draws using **Chainlink VRF**! Every month, a lucky subscriber wins a one-on-one live call with a creator. Will it be you this time?
---

## Avalanche Network

### Overview
The Avalanche integration focuses on user onboarding and content interaction within a high-performance blockchain environment. It includes advanced features such as DALL-E integration for avatar creation and cross-chain subscription functionalities.

### Features

- **User Onboarding**: Streamlined onboarding process including OpenAI's DALL-E for personalized avatar generation.
- **Dynamic Avatar Generation**: Integrated directly into the onboarding process, leveraging OpenAI's DALL-E to provide users with unique, personalized avatars as they join.
- **Purchase Subscription**: Utilizes Chainlink's price feeds and CCIP for cross-chain subscriptions, ensuring users can subscribe to content across various blockchains.

### Contracts

- **UserOnboarding Contract**: Generates user profile NFT with chainlink functions --> **openAI dalle** to generate random avatar art
  - Address: [`0x82376dA85a76360BC9FfC9a542961429A2A653ff`](https://testnet.avascan.info/blockchain/all/address/0x82376dA85a76360BC9FfC9a542961429A2A653ff/contract) 
- **Subscription Contract**: Manages subscriptions with functionalities enhanced by **Chainlink's price feed** and **CCIP**.
  - Address: [`0xf6b6A9EFAFd008b1170D703C32Fe32C0dA92fc2F`](https://testnet.avascan.info/blockchain/all/address/0xf6b6A9EFAFd008b1170D703C32Fe32C0dA92fc2F/contract)


---

## Sepolia Network

### Overview
Sepolia serves as the base layer for NFT minting and marketplace functionalities within BlockTease. It supports liquidity from all CCIP-enabled chains, allowing for a robust trading and subscription environment.

### Features

- **NFT Minting and Marketplace**: Central hub for creating and trading NFTs.
- **MockUSD**: Utilized for all transactional tests and purchases within the network.
  - Address: [`0x9d24c52916A14afc31D86B5Aa046b252383ee444`](https://sepolia.etherscan.io/address/0x9d24c52916A14afc31D86B5Aa046b252383ee444#code)
- **Marketplace Contract**: Facilitates the buying and selling of NFTs.
  - Address: [`0xc96b21eDA35A43eFfc57d459688e066315106f59`](https://sepolia.etherscan.io/address/0xc96b21eDA35A43eFfc57d459688e066315106f59#code)
- **BlockTease NFT Contract**: Repository for all model-related NFTs.
  - Address: [`0x87555010E191072421d4f4B14E75FB59abE778B0`](https://sepolia.etherscan.io/address/0x87555010E191072421d4f4B14E75FB59abE778B0#code)
- **Chainlink Price Feeder**: Integrates Chainlink price feeds for accurate native payment processing.


---

## Polygon Networks

### Polygon Amoy
- Amoy network on Polygon focuses on CCIP-enabled transactions for enhanced cross-chain communication and interoperability.
  - **CCIP Gateway Contract**: [`0xa52309ed1de8781cbeecef9d05b4b09b209b2493`](https://amoy.polygonscan.com/address/0xa52309ed1de8781cbeecef9d05b4b09b209b2493#tokentxns) — Enables cross-chain interactions using Chainlink's Cross-Chain Interoperability Protocol (CCIP).

### Polygon Cardona zkEVM
- Our dedicated Cardona marketplace on the zkEVM layer of Polygon is designed to handle specialized transactions and features several key contracts:
  - **mUSD Address**: `0x3FA6cfdC28Ad346c4360AA0543b5BfdA551c7111` — Manages our custom mUSD currency for transactions within the marketplace.
  - **BlockTease NFT Address**: `0x5192Ffbc96b2E731649714B7b51d4cC4CA1fAB8F` — Repository for all model-related NFTs.
  - **Marketplace Contract**: `0x054ba199Ef61ef15226e2CeB61138f7d5E2F8408` — Facilitates the buying and selling of NFTs and other digital assets.



---

## zkSync Network

### Overview
zkSync is leveraged for its Layer-2 scaling solutions, providing cost-effective transaction capabilities for subscription services.

### Features

- **Subscription Services**: Efficient and cost-effective subscription management on a Layer-2 platform.

### Contracts

- **Subscription Contract**: Manages subscription processes efficiently on zkSync's Layer-2 network.
  - Address: [`0x52d8cB79B5f5C7Eab2141278C29A1c264C9dD405`](https://sepolia.explorer.zksync.io/address/0x52d8cB79B5f5C7Eab2141278C29A1c264C9dD405#contract)
- **mUSD Contract**: For mocking payment tokens.
  - Address: [`0x0C6AD0Fa2Fe5bae6eD2a1f82aCf760b520C81B6A`](https://sepolia.explorer.zksync.io/address/0x0C6AD0Fa2Fe5bae6eD2a1f82aCf760b520C81B6A#contract)

---


## Moonbeam Network

### Overview

This project demonstrates the interaction with smart contracts deployed on the Moonbase Alpha Testnet. Moonbase Alpha is the test network (testnet) for Moonbeam, providing a blockchain environment that supports Ethereum compatible smart contracts.

### Features

- **Smart Contract Interaction**: The script provides functionalities to interact with pre-deployed contracts on the Moonbase Alpha Testnet, performing batch transactions to streamline processes such as token approvals and subscriptions.
- **Batch Transactions**: Utilize a precompiled batch functionality to execute multiple contract calls in a single transaction, reducing gas costs and improving transaction efficiency.
- **Gasless Transactions**: Features a gasless precompile to fund the gas fees of batch transactions, enabling users to execute operations without the direct cost of gas.

### Contracts

The project uses the following contracts deployed on the Moonbase Alpha Testnet:

- **MockUSD Contract**: A mock USD stablecoin used for transactional testing within the network.
  - Address: [`0x309222b7833D3D0A59A8eBf9C64A5790bf43E2aA`](https://moonbase.moonscan.io/address/0x309222b7833D3D0A59A8eBf9C64A5790bf43E2aA)
- **Nft Marketplace Contract**: Manages subscriptions payments & marketplace list/buy handling via the MockUSD token.
  - Address: [`0xc96b21eDA35A43eFfc57d459688e066315106f59`](https://moonbase.moonscan.io/address/0xF99b791257ab50be7F235BC825E7d4B83942cf38)
- **Batch Contract**: Facilitates batch processing of transactions.
  - Address: [`0x0000000000000000000000000000000000000808`](https://moonbase.moonscan.io/address/0x0000000000000000000000000000000000000808)
- **Gasless Precompile Contract**: After batching, utilizes a gasless precompile to cover the gas fees of the batch transactions.
  - Address: [`0x000000000000000000000000000000000000080a`](https://moonbase.moonscan.io/address/0x000000000000000000000000000000000000080a)
