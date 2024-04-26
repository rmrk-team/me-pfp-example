export const BASE_METADATA_URI = 'ipfs://ABC'; // TODO: Set your own IPFS URI here

export const SKIN_COLLECTION_METADATA = `${BASE_METADATA_URI}/collection.json`;

export const CATALOG_METADATA_URI = `${BASE_METADATA_URI}/catalog/catalog.json`;
export const CATALOG_TYPE = 'image/png';

export const BACKGROUND_SLOT_METADATA = `${BASE_METADATA_URI}/catalog/slot/background.json`;
export const BODY_SLOT_METADATA = `${BASE_METADATA_URI}/catalog/slot/body.json`;
export const HEAD_SLOT_METADATA = `${BASE_METADATA_URI}/catalog/slot/head.json`;

export const BACKGROUND_Z_INDEX = 0n;
export const SKIN_Z_INDEX = 1n;
export const BODY_Z_INDEX = 2n;
export const HEAD_Z_INDEX = 3n;

// TODO: Set your own image URIs here
export const IMAGE_URIS = [
  'ipfs://QmeBELRq3JxsynRp3HAx5CwWtvVqmX34ZeXyqjC5ugNAjW/body_01.png',
  'ipfs://QmeBELRq3JxsynRp3HAx5CwWtvVqmX34ZeXyqjC5ugNAjW/body_02.png',
  'ipfs://QmeBELRq3JxsynRp3HAx5CwWtvVqmX34ZeXyqjC5ugNAjW/body_03.png',
];
// TODO: Set your own renderer here. Ready to use example at https://github.com/rmrk-team/rmrk-examples/tree/master/react-nextjs-example
export const BASE_ANIMATION_URI_TEST = 'https://YOUR_RENDER_IN_TEST/{chanId}/{contractAddress}/';
export const BASE_ANIMATION_URI_PROD = 'https://YOUR_RENDER_IN_PROD/{chanId}/{contractAddress}/';

export const FIXED_PART_METADATA_URIS = [
  `${BASE_METADATA_URI}/assets/01.json`,
  `${BASE_METADATA_URI}/assets/02.json`,
  `${BASE_METADATA_URI}/assets/03.json`,
];
export const FIXED_PART_IDS = [1n, 2n, 3n];

export const ME_EQUIPPABLE_GROUP_ID = 1n; // Only useful if we plan to equip it into something else.
export const SLOT_PART_BACKGROUND_ID = 1001n;
export const SLOT_PART_BODY_ID = 1002n;
export const SLOT_PART_HEAD_ID = 1003n;

export const BENEFICIARY = ''; // TODO: Set your beneficiary address here
export const ROYALTIES_BPS = 300; // 3%

// PART TYPES (Defined by standard)
export const PART_TYPE_SLOT = 1n;
export const PART_TYPE_FIXED = 2n;
