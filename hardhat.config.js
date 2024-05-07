require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
 
module.exports = {
  solidity: "0.8.20",
  networks:{
    goerli:{
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    moonbase: {
      url: "https://rpc.api.moonbase.moonbeam.network",
      chainId: 1287, // 0x507 in hex,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
  }
};  