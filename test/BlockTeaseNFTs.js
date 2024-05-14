const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BlockTeaseNFTs", function () {
  let BlockTeaseNFTs, blockTeaseNFTs, owner, minter, addr1;

  beforeEach(async function () {
    [owner, minter, addr1] = await ethers.getSigners();
    BlockTeaseNFTs = await ethers.getContractFactory("BlockTeaseNFTs");
    blockTeaseNFTs = await BlockTeaseNFTs.deploy(owner.address, minter.address);
    await blockTeaseNFTs.deployed();
  });

  it("Should set the right roles", async function () {
    expect(await blockTeaseNFTs.hasRole(await blockTeaseNFTs.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
    expect(await blockTeaseNFTs.hasRole(await blockTeaseNFTs.MINTER_ROLE(), minter.address)).to.be.true;
  });

  it("Should mint tokens correctly with royalty info", async function () {
    const modelId = 1, subscriptionId = 1, amount = 1, duration = 86400, royaltyFee = 500;
    await blockTeaseNFTs.connect(minter).mint(addr1.address, modelId, subscriptionId, amount, duration, royaltyFee, addr1.address, "0x");
    const tokenId = await blockTeaseNFTs._encodeTokenId(modelId, subscriptionId);
    const expirationTime = await blockTeaseNFTs.expirationTimes(tokenId);

    expect(expirationTime).to.be.gt(0);
    const [receiver, fee] = await blockTeaseNFTs.royaltyInfo(tokenId, 10000);
    expect(receiver).to.equal(addr1.address);
    expect(fee).to.equal(500);
  });

  it("Only minter should mint tokens", async function () {
    await expect(blockTeaseNFTs.connect(addr1).mint(addr1.address, 1, 1, 1, 86400, 500, addr1.address, "0x")).to.be.revertedWith("AccessControl: account ");
  });
});
