# 💘 BlockTease 💌
Welcome to **BlockTease** — the ultimate fusion of **OnlyFans'** 🕊 charm with the transformative power of Web3! 🚀🌐 Dive into a world where privacy, decentralization, and seamless interactions are not just ideals but vibrant realities.

![image](https://github.com/BlockTease-BlockMagic/Backend/assets/40585900/ad09411b-9a81-404f-845f-7ddc3a82e3bd)



## 🎉 Exciting Features

### 🚀 Hassle-Free Onboarding
Join effortlessly with **Biconomy Smart Accounts** that bridge Web2 and Web3. Get started without deep blockchain knowledge — a simple, barrier-free entry into the exciting world of decentralized applications.

### 🖼🎨 Dynamic NFT Avatar Generation
Create your unique digital identity with OpenAI's DALL-E, seamlessly integrated through **Chainlink Functions** to mint dynamic NFT avatars. Thanks to **Biconomy Paymaster**, these are offered **free of charge** for new users, adding a personal touch from day one!

### 💌📬 Autopay Creator Subscriptions
Never miss content from your favorite creators! Our **Chainlink Automation** setup wraps **Chainlink Functions** with nodemailer to keep you informed about your subscription status automatically.

### 🔗🌍 Cross-Chain Subscriptions
Enjoy the freedom to follow and support creators across multiple blockchains, thanks to **Chainlink CCIP**. No worries about single chain liquidity — subscribe anywhere, anytime!

### 🛒💸 Gasless and Bundled Transactions
Experience the smoothest UX yet with Biconomy's gasless and bundled transactions. Approve NFTs, make payments, and manage subscriptions all in one go, without the usual gas fees.

### 🏆📞 Weekly Lucky Subscriber Draw
Join the excitement with our weekly draws using **Chainlink VRF**! Every week, a lucky subscriber wins a one-on-one live call with a creator. Will it be you this time?

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
  - Address: [Insert Address]


---

## Sepolia Network

### Overview
Sepolia serves as the base layer for NFT minting and marketplace functionalities within BlockTease. It supports liquidity from all CCIP-enabled chains, allowing for a robust trading and subscription environment.

### Features

- **NFT Minting and Marketplace**: Central hub for creating and trading NFTs.
- **MockUSD**: Utilized for all transactional tests and purchases within the network.
  - Address: [Insert Address]
- **Marketplace Contract**: Facilitates the buying and selling of NFTs.
  - Address: [Insert Address]
- **BlockTease NFT Contract**: Repository for all model-related NFTs.
  - Address: [Insert Address]
- **Chainlink Price Feeder**: Integrates Chainlink price feeds for accurate native payment processing.

---

## Polygon Network

### Overview
On Polygon, the focus is on providing seamless subscription services through the use of Chainlink technologies, enhancing both the efficiency and reliability of transactions.

### Features

- **Purchase Subscription**: Leverages Chainlink price feeders and CCIP for efficient cross-chain subscriptions.

### Contracts

- **Purchase Subscription Contract**: Utilizes Chainlink technology for accurate and efficient subscription management.
  - Address: [Insert Address]

---

## zkSync Network

### Overview
zkSync is leveraged for its Layer-2 scaling solutions, providing cost-effective transaction capabilities for subscription services.

### Features

- **Subscription Services**: Efficient and cost-effective subscription management on a Layer-2 platform.

### Contracts

- **Subscription Contract**: Manages subscription processes efficiently on zkSync's Layer-2 network.
  - Address: [Insert Address]

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
- **PurchaseSubscription Contract**: Manages subscriptions payments via the MockUSD token.
  - Address: [`0xF99b791257ab50be7F235BC825E7d4B83942cf38`](https://moonbase.moonscan.io/address/0xF99b791257ab50be7F235BC825E7d4B83942cf38)
- **Batch Contract**: Facilitates batch processing of transactions.
  - Address: [`0x0000000000000000000000000000000000000808`](https://moonbase.moonscan.io/address/0x0000000000000000000000000000000000000808)
- **Gasless Precompile Contract**: After batching, utilizes a gasless precompile to cover the gas fees of the batch transactions.
  - Address: [`0x000000000000000000000000000000000000080a`](https://moonbase.moonscan.io/address/0x000000000000000000000000000000000000080a)

### Getting Started

To interact with these contracts, you will need to set up your development environment:

1. **Install Dependencies**: Make sure you have Node.js and npm installed. Then run `npm install` to install the required dependencies including Hardhat and Ethers.js.
2. **Configure Hardhat**: Set up your Hardhat environment to connect to the Moonbase Alpha Testnet. Modify your `hardhat.config.js` to include network settings for Moonbase Alpha.
3. **Run the Script**: Execute the script using Hardhat's command line tools. For example, `npx hardhat run scripts/GassLessbatchTxn.js --network moonbasealpha`.

## Network Configuration

Ensure your `hardhat.config.js` includes the Moonbase Alpha network configuration as follows:

```javascript
module.exports = {
  networks: {
    moonbasealpha: {
      url: "https://rpc.api.moonbase.moonbeam.network",
      chainId: 1287,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  solidity: "0.8.20",
};
