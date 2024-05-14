const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  let BlockTeaseNFTs, blockTeaseNFTs, MockUSD, mockUSD, NFTMarketplace, nftMarketplace, owner, addr1;

  const modelIds = Array.from({ length: 16 }, (_, i) => i + 1);
  const pricesUSD = Array.from({ length: 16 }, () => (Math.floor(Math.random() * 10) + 1) * 100000000);
  const associatedAddresses = Array.from({ length: 16 }, () => "0x2cac89ABf06DbE5d3a059517053B7144074e1CE5");
  const royaltyFees = Array(16).fill(500);

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    MockUSD = await ethers.getContractFactory("MockUSD");
    mockUSD = await MockUSD.deploy(owner.address);
    await mockUSD.deployed();

    BlockTeaseNFTs = await ethers.getContractFactory("BlockTeaseNFTs");
    blockTeaseNFTs = await BlockTeaseNFTs.deploy(owner.address, owner.address);
    await blockTeaseNFTs.deployed();

    NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    nftMarketplace = await NFTMarketplace.deploy(blockTeaseNFTs.address, mockUSD.address);
    await nftMarketplace.deployed();

    await nftMarketplace.updateBatchModels(modelIds, pricesUSD, associatedAddresses, royaltyFees);
  });

  it("Should update models correctly", async function () {
    for (let i = 0; i < modelIds.length; i++) {
      const model = await nftMarketplace.models(modelIds[i]);
      expect(model.priceUSD).to.equal(pricesUSD[i]);
      expect(model.associatedAddress).to.equal(associatedAddresses[i]);
      expect(model.royaltyFees).to.equal(royaltyFees[i]);
    }
  });

  it("Should list and buy NFT with ETH correctly", async function () {
    await blockTeaseNFTs.mint(addr1.address, 1, 1, 1, 86400, 500, addr1.address, "0x");
    const tokenId = await blockTeaseNFTs._encodeTokenId(1, 1);

    await blockTeaseNFTs.connect(addr1).setApprovalForAll(nftMarketplace.address, true);
    await nftMarketplace.connect(addr1).listNFT(tokenId, ethers.utils.parseUnits("1", 18));

    await nftMarketplace.buyNFT(tokenId, { value: ethers.utils.parseUnits("1", 18) });

    expect(await blockTeaseNFTs.balanceOf(addr1.address, tokenId)).to.equal(0);
    expect(await blockTeaseNFTs.balanceOf(owner.address, tokenId)).to.equal(1);
  });

  it("Should buy NFT with USDC correctly", async function () {
    await blockTeaseNFTs.mint(addr1.address, 1, 1, 1, 86400, 500, addr1.address, "0x");
    const tokenId = await blockTeaseNFTs._encodeTokenId(1, 1);

    await blockTeaseNFTs.connect(addr1).setApprovalForAll(nftMarketplace.address, true);
    await nftMarketplace.connect(addr1).listNFT(tokenId, pricesUSD[0]);

    await mockUSD.mint(owner.address, pricesUSD[0]);
    await mockUSD.approve(nftMarketplace.address, pricesUSD[0]);

    await nftMarketplace.buyNFTWithUSDC(tokenId);

    expect(await blockTeaseNFTs.balanceOf(addr1.address, tokenId)).to.equal(0);
    expect(await blockTeaseNFTs.balanceOf(owner.address, tokenId)).to.equal(1);
  });
});
