require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
require('@nomicfoundation/hardhat-verify');

module.exports = {
  solidity: "0.8.20",
  networks:{
    moonbaseAlpha: {
      url: "https://rpc.api.moonbase.moonbeam.network",
      chainId: 1287, // 0x507 in hex,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    zkTestnet: {
      url: "https://sepolia.era.zksync.dev", // The testnet RPC URL of zkSync Era network.
      chainId: 300, // The Ethereum Web3 RPC URL, or the identifier of the network (e.g. `mainnet` or `sepolia`)
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      zksync: true
    }
  },
  etherscan: {
    apiKey: {
      moonbaseAlpha: [`${process.env.MOONBASE_API_KEY}`],
    },
  },
};  