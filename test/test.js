const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = require("hardhat");

describe("CombinedModule", function () {
  let blockTeaseNFTs, mockUSD, nftMarketplace;
  let owner;

  const modelIds = Array.from({ length: 16 }, (_, i) => i + 1);
  const pricesUSD = Array.from({ length: 16 }, () => (Math.floor(Math.random() * 10) + 1) * 100000000);
  const associatedAddresses = Array.from({ length: 16 }, () => "0x2cac89ABf06DbE5d3a059517053B7144074e1CE5");
  const royaltyFees = Array(16).fill(500);

  before(async function () {
    [owner] = await ethers.getSigners();
    
    const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

    const module = buildModule("CombinedModule", (m) => {
      const DEFAULT_ADMIN_ADDRESS = owner.address;
      const MINTER_ADDRESS = owner.address;
      const OWNER_ADDRESS = owner.address;

      const blockTeaseNFTs = m.contract("BlockTeaseNFTs", [DEFAULT_ADMIN_ADDRESS, MINTER_ADDRESS]);
      const mockUSD = m.contract("MockUSD", [OWNER_ADDRESS]);
      const nftMarketplace = m.contract("NFTMarketplace", [blockTeaseNFTs, mockUSD]);

      const MINTER_ROLE = m.staticCall(blockTeaseNFTs, "MINTER_ROLE", []);
      m.call(blockTeaseNFTs, "grantRole", [MINTER_ROLE, nftMarketplace]);

      m.call(nftMarketplace, "updateBatchModels", [modelIds, pricesUSD, associatedAddresses, royaltyFees]);

      return { blockTeaseNFTs, mockUSD, nftMarketplace };
    });

    const deployment = await hre.ignition.deploy(module);
    blockTeaseNFTs = deployment.blockTeaseNFTs;
    mockUSD = deployment.mockUSD;
    nftMarketplace = deployment.nftMarketplace;
  });

  it("Should deploy BlockTeaseNFTs, MockUSD, and NFTMarketplace contracts", async function () {
    expect(blockTeaseNFTs).to.be.ok;
    expect(mockUSD).to.be.ok;
    expect(nftMarketplace).to.be.ok;
  });

  it("Should grant MINTER_ROLE to NFTMarketplace", async function () {
    const MINTER_ROLE = await blockTeaseNFTs.MINTER_ROLE();
    const hasRole = await blockTeaseNFTs.hasRole(MINTER_ROLE, await nftMarketplace.getAddress());
    expect(hasRole).to.be.true;
  });

  it("Should update models correctly in NFTMarketplace", async function () {
    for (let i = 0; i < modelIds.length; i++) {
      const model = await nftMarketplace.models(modelIds[i]);
      expect(model.priceUSD).to.equal(pricesUSD[i]);
      expect(model.associatedAddress).to.equal(associatedAddresses[i]);
      expect(model.royaltyFees).to.be.equal(royaltyFees[i]);
    }
  });
});
