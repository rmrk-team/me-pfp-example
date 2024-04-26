import { ethers, run, network } from 'hardhat';
import { delay, isHardhatNetwork } from './utils';
import {
  ME,
  RMRKBulkWriter,
  RMRKCatalogImpl,
  RMRKCatalogUtils,
  RMRKCollectionUtils,
  RMRKEquipRenderUtils,
} from '../typechain-types';
import { getRegistry } from './get-gegistry';
import * as C from './constants';

export async function mintMeNFTs(me: ME, to: string, assetId: number, amount: number) {
  console.log(`Minting ME NFTs with asset ID ${assetId} to ${to}...`);
  const tx = await me.mintWithAsset(to, amount, assetId);
  await tx.wait();
  console.log('ME NFTs minted');
}

export async function addMeAssets(me: ME, catalogAddress: string): Promise<void> {
  console.log('Adding assets to ME...');
  for (let i = 0; i < C.FIXED_PART_METADATA_URIS.length; i++) {
    const tx = await me.addEquippableAssetEntry(0, catalogAddress, C.FIXED_PART_METADATA_URIS[i], [
      C.FIXED_PART_IDS[i],
      C.SLOT_PART_BODY_ID,
      C.SLOT_PART_HEAD_ID,
      C.SLOT_PART_BACKGROUND_ID,
    ]);
    await tx.wait();
  }
  console.log('Assets added to ME');

  let tx = await me.setImgUri(1n, C.IMAGE_URIS[0]);
  await tx.wait();

  tx = await me.setImgUri(2n, C.IMAGE_URIS[1]);
  await tx.wait();

  tx = await me.setImgUri(3n, C.IMAGE_URIS[2]);
  await tx.wait();

  console.log('Image URIs set');

  if (network.config.chainId === undefined)
    throw new Error('Chain ID is not defined in network config');

  let baseAnimationURI =
    network.config.chainId === 8453 ? C.BASE_ANIMATION_URI_PROD : C.BASE_ANIMATION_URI_TEST;
  baseAnimationURI = baseAnimationURI
    .replace('{contractAddress}', await me.getAddress())
    .replace('{chanId}', network.config.chainId.toString());
  tx = await me.setBaseAnimationURI(baseAnimationURI);
  await tx.wait();
  console.log('Base animation URI set');
}

export async function configureCatalog(catalog: RMRKCatalogImpl): Promise<void> {
  console.log('Configuring catalog...');
  let tx = await catalog.addPartList([
    {
      partId: C.FIXED_PART_IDS[0],
      part: {
        itemType: C.PART_TYPE_FIXED,
        z: C.SKIN_Z_INDEX,
        equippable: [],
        metadataURI: C.FIXED_PART_METADATA_URIS[0],
      },
    },
    {
      partId: C.FIXED_PART_IDS[1],
      part: {
        itemType: C.PART_TYPE_FIXED,
        z: C.SKIN_Z_INDEX,
        equippable: [],
        metadataURI: C.FIXED_PART_METADATA_URIS[1],
      },
    },
    {
      partId: C.FIXED_PART_IDS[2],
      part: {
        itemType: C.PART_TYPE_FIXED,
        z: C.SKIN_Z_INDEX,
        equippable: [],
        metadataURI: C.FIXED_PART_METADATA_URIS[2],
      },
    },
    {
      partId: C.SLOT_PART_BACKGROUND_ID,
      part: {
        itemType: C.PART_TYPE_SLOT,
        z: C.BACKGROUND_Z_INDEX,
        equippable: [],
        metadataURI: C.BACKGROUND_SLOT_METADATA,
      },
    },
    {
      partId: C.SLOT_PART_BODY_ID,
      part: {
        itemType: C.PART_TYPE_SLOT,
        z: C.BODY_Z_INDEX,
        equippable: [],
        metadataURI: C.BODY_SLOT_METADATA,
      },
    },
    {
      partId: C.SLOT_PART_HEAD_ID,
      part: {
        itemType: C.PART_TYPE_SLOT,
        z: C.HEAD_Z_INDEX,
        equippable: [],
        metadataURI: C.HEAD_SLOT_METADATA,
      },
    },
  ]);
  await tx.wait();

  tx = await catalog.setEquippableToAll(C.SLOT_PART_BODY_ID);
  await tx.wait();
  tx = await catalog.setEquippableToAll(C.SLOT_PART_HEAD_ID);
  await tx.wait();
  tx = await catalog.setEquippableToAll(C.SLOT_PART_BACKGROUND_ID);
  await tx.wait();
  console.log('Catalog configured');
}

export async function deployMe(): Promise<ME> {
  console.log(`Deploying ME to ${network.name} blockchain...`);

  const contractFactory = await ethers.getContractFactory('ME');
  const args = [
    C.SKIN_COLLECTION_METADATA,
    ethers.MaxUint256,
    C.BENEFICIARY,
    C.ROYALTIES_BPS,
  ] as const;
  const contract: ME = await contractFactory.deploy(...args);
  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();
  console.log(`ME deployed to ${contractAddress}`);

  if (!isHardhatNetwork()) {
    console.log('Waiting 10 seconds before verifying contract...');
    await delay(10000);
    await run('verify:verify', {
      address: contractAddress,
      constructorArguments: args,
      contract: 'contracts/Me.sol:ME',
    });

    // Only do on testing, or if whitelisted for production
    const registry = await getRegistry();
    await registry.addExternalCollection(contractAddress, args[0]);
    console.log('Collection added to Singular Registry');
  }
  return contract;
}

export async function deployBulkWriter(): Promise<RMRKBulkWriter> {
  const bulkWriterFactory = await ethers.getContractFactory('RMRKBulkWriter');
  const bulkWriter = await bulkWriterFactory.deploy();
  await bulkWriter.waitForDeployment();
  const bulkWriterAddress = await bulkWriter.getAddress();
  console.log('Bulk Writer deployed to:', bulkWriterAddress);

  await verifyIfNotHardhat(bulkWriterAddress);
  return bulkWriter;
}

export async function deployCatalogUtils(): Promise<RMRKCatalogUtils> {
  const catalogUtilsFactory = await ethers.getContractFactory('RMRKCatalogUtils');
  const catalogUtils = await catalogUtilsFactory.deploy();
  await catalogUtils.waitForDeployment();
  const catalogUtilsAddress = await catalogUtils.getAddress();
  console.log('Catalog Utils deployed to:', catalogUtilsAddress);

  await verifyIfNotHardhat(catalogUtilsAddress);
  return catalogUtils;
}

export async function deployCollectionUtils(): Promise<RMRKCollectionUtils> {
  const collectionUtilsFactory = await ethers.getContractFactory('RMRKCollectionUtils');
  const collectionUtils = await collectionUtilsFactory.deploy();
  await collectionUtils.waitForDeployment();
  const collectionUtilsAddress = await collectionUtils.getAddress();
  console.log('Collection Utils deployed to:', collectionUtilsAddress);

  await verifyIfNotHardhat(collectionUtilsAddress);
  return collectionUtils;
}

export async function deployRenderUtils(): Promise<RMRKEquipRenderUtils> {
  const renderUtilsFactory = await ethers.getContractFactory('RMRKEquipRenderUtils');
  const renderUtils = await renderUtilsFactory.deploy();
  await renderUtils.waitForDeployment();
  const renderUtilsAddress = await renderUtils.getAddress();
  console.log('Equip Render Utils deployed to:', renderUtilsAddress);

  await verifyIfNotHardhat(renderUtilsAddress);
  return renderUtils;
}

export async function deployCatalog(
  catalogMetadataUri: string,
  catalogType: string,
): Promise<RMRKCatalogImpl> {
  const catalogFactory = await ethers.getContractFactory('RMRKCatalogImpl');
  const catalog = await catalogFactory.deploy(catalogMetadataUri, catalogType);
  await catalog.waitForDeployment();
  const catalogAddress = await catalog.getAddress();
  console.log('Catalog deployed to:', catalogAddress);

  await verifyIfNotHardhat(catalogAddress, [catalogMetadataUri, catalogType]);
  return catalog;
}

async function verifyIfNotHardhat(contractAddress: string, args: any[] = []) {
  if (isHardhatNetwork()) {
    // Hardhat
    return;
  }

  // sleep 20s
  await delay(20000);

  console.log('Etherscan contract verification starting now.');
  try {
    await run('verify:verify', {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (error) {
    // probably already verified
  }
}
