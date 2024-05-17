const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const DEFAULT_ADMIN_ADDRESS = "0x2cac89ABf06DbE5d3a059517053B7144074e1CE5";
const MOCK_USD_ADDRESS = "0xf7409b94F7285d27Ab1A456638A1110A4E55bFEC";
const BLOCKTEASE_NFT_ADDRESS = "0x12B77FEb2c44dC16d57d96a1FedEd3136Ad02FBB";

module.exports = buildModule("CombinedModule", (m) => {

  const blockTeaseNFTs = m.contractAt("BlockTeaseNFTs", BLOCKTEASE_NFT_ADDRESS)
  const mockUSD = m.contractAt("MockUSD", MOCK_USD_ADDRESS)
  
  // Deploy NFTMarketplace contract using the addresses of the previously deployed contracts
  const nftMarketplace = m.contract("NFTMarketplace", [blockTeaseNFTs, mockUSD]);
  
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
