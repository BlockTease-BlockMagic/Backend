# Moonbeam Network

## Overview

This project demonstrates the interaction with smart contracts deployed on the Moonbase Alpha Testnet. Moonbase Alpha is the test network (testnet) for Moonbeam, providing a blockchain environment that supports Ethereum compatible smart contracts.

## Features

- **Smart Contract Interaction**: The script provides functionalities to interact with pre-deployed contracts on the Moonbase Alpha Testnet, performing batch transactions to streamline processes such as token approvals and subscriptions.
- **Batch Transactions**: Utilize a precompiled batch functionality to execute multiple contract calls in a single transaction, reducing gas costs and improving transaction efficiency.
- **Gasless Transactions**: Features a gasless precompile to fund the gas fees of batch transactions, enabling users to execute operations without the direct cost of gas.

## Contracts

The project uses the following contracts deployed on the Moonbase Alpha Testnet:

- **MockUSD Contract**: A mock USD stablecoin used for transactional testing within the network.
  - Address: [`0x309222b7833D3D0A59A8eBf9C64A5790bf43E2aA`](https://moonbase.moonscan.io/address/0x309222b7833D3D0A59A8eBf9C64A5790bf43E2aA)
- **PurchaseSubscription Contract**: Manages subscriptions payments via the MockUSD token.
  - Address: [`0xF99b791257ab50be7F235BC825E7d4B83942cf38`](https://moonbase.moonscan.io/address/0xF99b791257ab50be7F235BC825E7d4B83942cf38)
- **Batch Contract**: Facilitates batch processing of transactions.
  - Address: [`0x0000000000000000000000000000000000000808`](https://moonbase.moonscan.io/address/0x0000000000000000000000000000000000000808)
- **Gasless Precompile Contract**: After batching, utilizes a gasless precompile to cover the gas fees of the batch transactions.
  - Address: [`0x000000000000000000000000000000000000080a`](https://moonbase.moonscan.io/address/0x000000000000000000000000000000000000080a)

## Getting Started

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
