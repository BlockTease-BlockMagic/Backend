// Importing necessary libraries and plugins
const { ethers } = require("hardhat");

const purchaseSubscriptionAddress =
  "0xF99b791257ab50be7F235BC825E7d4B83942cf38";
const mockUsdAddress = "0x309222b7833D3D0A59A8eBf9C64A5790bf43E2aA";

async function checkBalances(mockUsd) {
  const signers = await ethers.getSigners();
  const signer = signers[0];
  const signerAddress = signer.address;

  const subscriptionBalance = ethers.formatUnits(
    await mockUsd.balanceOf(purchaseSubscriptionAddress),
    8
  );
  console.log(
    `PurchaseSubscription ${purchaseSubscriptionAddress} has a balance of: ${subscriptionBalance} mUSD`
  );

  const signerBalance = ethers.formatUnits(
    await mockUsd.balanceOf(signerAddress),
    8
  );
  console.log(
    `Account ${signerAddress} has a balance of: ${signerBalance} mUSD`
  );
}

async function batchSubscribe(mockUsd, modelId, subscriptionId, priceInUsd) {
  await checkBalances(mockUsd);
  const priceInMinUnits = ethers.parseUnits(priceInUsd.toString(), 8);

  const purchaseSubscription = await ethers.getContractAt(
    "PurchaseSubscription",
    purchaseSubscriptionAddress
  );

  // Create instance of Batch.sol
  const batchAddress = "0x0000000000000000000000000000000000000808";
  const batch = await ethers.getContractAt("Batch", batchAddress);

  const approvalCallData = mockUsd.interface.encodeFunctionData("approve", [
    purchaseSubscriptionAddress,
    priceInMinUnits,
  ]);
  const subscribeCallData = purchaseSubscription.interface.encodeFunctionData(
    "subscribeWithToken",
    [modelId, subscriptionId, priceInMinUnits]
  );

  // console.log(approvalCallData, subscribeCallData);

  const batchTx = await batch.batchAll(
    [mockUsdAddress, purchaseSubscriptionAddress],
    [],
    [approvalCallData, subscribeCallData],
    []
  );
  await batchTx.wait();
  console.log(`Batch executed for approval and subscription: ${batchTx.hash}`);

  await checkBalances(mockUsd);

}

async function main() {
  const mockUsd = await ethers.getContractAt(
    "MockUSD",
    "0x309222b7833D3D0A59A8eBf9C64A5790bf43E2aA"
  );

  const modelId = 2;
  const subscriptionId = 1;
  const priceInUsd = 1;

  await batchSubscribe(mockUsd, modelId, subscriptionId, priceInUsd);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
