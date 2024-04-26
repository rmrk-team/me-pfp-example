import { ethers } from 'hardhat';
import { deployCatalog } from './deploy-methods';
import { CATALOG_METADATA_URI, CATALOG_TYPE } from './constants';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deployer address: ${deployer.address}`);

  await deployCatalog(CATALOG_METADATA_URI, CATALOG_TYPE);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
