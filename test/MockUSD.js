const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MockUSD", function () {
  let MockUSD, mockUSD, owner, addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    MockUSD = await ethers.getContractFactory("MockUSD");
    mockUSD = await MockUSD.deploy(owner.address);
    await mockUSD.deployed();
  });

  it("Should have correct name and symbol", async function () {
    expect(await mockUSD.name()).to.equal("MockUSD");
    expect(await mockUSD.symbol()).to.equal("mUSD");
  });

  it("Should have 8 decimals", async function () {
    expect(await mockUSD.decimals()).to.equal(8);
  });

  it("Should mint tokens correctly", async function () {
    const amount = ethers.utils.parseUnits("100", 8);
    await mockUSD.mint(addr1.address, amount);
    expect(await mockUSD.balanceOf(addr1.address)).to.equal(amount);
  });

  it("Only owner should mint tokens", async function () {
    const amount = ethers.utils.parseUnits("100", 8);
    await expect(mockUSD.connect(addr1).mint(addr1.address, amount)).to.be.revertedWith("Ownable: caller is not the owner");
  });
});
