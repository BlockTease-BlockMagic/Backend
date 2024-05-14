const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const DEFAULT_ADMIN_ADDRESS = "0x2cac89ABf06DbE5d3a059517053B7144074e1CE5";
const MINTER_ADDRESS = "0x2cac89ABf06DbE5d3a059517053B7144074e1CE5";
const OWNER_ADDRESS = "0x2cac89ABf06DbE5d3a059517053B7144074e1CE5";
const CHAINLINK_PRICE_FEEDER = "0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF";

module.exports = buildModule("CombinedModule", (m) => {
  // Deploy BlockTeaseNFTs contract
  const blockTeaseNFTs = m.contract("BlockTeaseNFTs", [DEFAULT_ADMIN_ADDRESS, MINTER_ADDRESS]);
  
  // Deploy MockUSD contract
  const mockUSD = m.contract("MockUSD", [OWNER_ADDRESS]);
  
  // Deploy NFTMarketplace contract using the addresses of the previously deployed contracts
  const nftMarketplace = m.contract("ZkNFTMarketplace", [blockTeaseNFTs, mockUSD, CHAINLINK_PRICE_FEEDER]);
  
  // Assign minter role to NFTMarketplace
  const MINTER_ROLE = m.staticCall(blockTeaseNFTs, "MINTER_ROLE", []);
  m.call(blockTeaseNFTs, "grantRole", [MINTER_ROLE, nftMarketplace]);

  // Preparing data for updateBatchModels
  const modelIds = Array.from({ length: 16 }, (_, i) => i + 1);
  const pricesUSD = Array.from({ length: 16 }, () => (Math.floor(Math.random() * 10) + 1) * 100000000);
  const associatedAddresses = Array.from({ length: 16 }, () => DEFAULT_ADMIN_ADDRESS);
  const royaltyFees = Array(16).fill(500);

  // Call updateBatchModels on the NFTMarketplace contract
  m.call(nftMarketplace, "updateBatchModels", [modelIds, pricesUSD, associatedAddresses, royaltyFees]);

  return { blockTeaseNFTs, mockUSD, nftMarketplace };
});
