const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("BlockTeaseDeploymentModule", (m) => {
  // Deploy BlockTeaseNFT contract
  const deployNFT = async () => {
    const BlockTeaseNFT = await m.deploy("BlockTeaseNFT");
    await BlockTeaseNFT.deployed();
    console.log("BlockTeaseNFT deployed to:", BlockTeaseNFT.address);
    return BlockTeaseNFT;
  };

  // Deploy BlockTeaseMarketplace contract
  const deployMarketplace = async (nftAddress) => {
    const BlockTeaseMarketplace = await m.deploy("BlockTeaseMarketplace", [nftAddress]);
    await BlockTeaseMarketplace.deployed();
    console.log("BlockTeaseMarketplace deployed to:", BlockTeaseMarketplace.address);
    return BlockTeaseMarketplace;
  };

  // Deploy both contracts and return their addresses
  const deployContracts = async () => {
    const nftContract = await deployNFT();
    const marketplaceContract = await deployMarketplace(nftContract.address);
    return { nftContract, marketplaceContract };
  };

  return deployContracts();
});
