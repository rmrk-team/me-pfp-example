import {
  deployCatalog,
  deployMe,
  configureCatalog,
  addMeAssets,
  mintMeNFTs,
} from './deploy-methods';
import * as C from './constants';
import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);
  const catalog = await deployCatalog(C.CATALOG_METADATA_URI, C.CATALOG_TYPE);
  const me = await deployMe();
  await configureCatalog(catalog);
  await addMeAssets(me, await catalog.getAddress());
  // await mintMeNFTs(me, deployer.address, 1, 1);
  // await mintMeNFTs(me, deployer.address, 2, 1);
  // await mintMeNFTs(me, deployer.address, 3, 1);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
