// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {

  const BullnBear = await hre.ethers.getContractFactory("Bull&Bear");
  const BullnBearContract = await BullnBear.deploy(10 , "	0x8A753747A1Fa494EC906cE90E9f37563A8AF630e");

  await BullnBearContract.deployed();

  console.log("Greeter deployed to:", BullnBearContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
