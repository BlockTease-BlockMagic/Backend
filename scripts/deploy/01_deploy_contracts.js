module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const [defaultAdmin, minter] = await ethers.getSigners();

  // Deploy MockUSD contract
  const mockUSD = await deploy('MockUSD', {
    from: deployer,
    args: [deployer],
    log: true,
  });

  // Deploy BlockTeaseNFTs contract
  const blockTeaseNFTs = await deploy('BlockTeaseNFTs', {
    from: deployer,
    args: [defaultAdmin.address, minter.address],
    log: true,
  });

  // Deploy NFTMarketplace contract
  const nftMarketplace = await deploy('NFTMarketplace', {
    from: deployer,
    args: [blockTeaseNFTs.address, mockUSD.address],
    log: true,
  });

  // Grant MinterRole to the Marketplace contract
  const blockTeaseNFTsContract = await ethers.getContractAt('BlockTeaseNFTs', blockTeaseNFTs.address);
  const MINTER_ROLE = await blockTeaseNFTsContract.MINTER_ROLE();
  const grantRoleTx = await blockTeaseNFTsContract.grantRole(MINTER_ROLE, nftMarketplace.address);
  await grantRoleTx.wait();
  console.log(`Granted MINTER_ROLE to marketplace at: ${nftMarketplace.address}`);
};

module.exports.tags = ['BlockTeaseDeployment'];
