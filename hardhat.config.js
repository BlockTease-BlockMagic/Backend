require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
 
module.exports = {
  solidity: "0.8.20",
  networks:{
    goerli:{
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    }
  }
};