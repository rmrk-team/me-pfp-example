// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.21;

import {RMRKAbstractEquippable} from "@rmrk-team/evm-contracts/contracts/implementations/abstract/RMRKAbstractEquippable.sol";
import {RMRKImplementationBase} from "@rmrk-team/evm-contracts/contracts/implementations/utils/RMRKImplementationBase.sol";

error ContractURIFrozen();
error LengthMismatch();
    

contract MeMock is RMRKAbstractEquippable {
    // Events 
    /**
     * @notice From ERC4906 This event emits when the metadata of a token is changed.
     *  So that the third-party platforms such as NFT market could
     *  get notified when the metadata of a token is changed.
     */
    event MetadataUpdate(uint256 _tokenId);
      
    /**
     * @notice From ERC7572 (Draft) Emitted when the contract-level metadata is updated
     */
    event ContractURIUpdated();
    
    // Variables
    mapping(address => bool) private _autoAcceptCollection;
    uint256 private _contractURIFrozen; // Cheaper than a bool
    

    // Constructor
    constructor(
      string memory collectionMetadata,
      uint256 maxSupply,
      address royaltyRecipient,
      uint16 royaltyPercentageBps
    )
        RMRKImplementationBase(
            "MeMock",
            "MM",
            collectionMetadata,
            maxSupply,
            royaltyRecipient,
            royaltyPercentageBps
        )
    {}
    
    // Methods
    function tokenURI(
        uint256 tokenId
    ) public view returns (string memory) {
        _requireMinted(tokenId);
        // This will revert if the token has not assets, only use if at least an asset is assigned on mint to every token
        return getAssetMetadata(tokenId, _activeAssets[tokenId][0]);
    }
      
    /**
     * @notice Hook that is called after an asset is accepted to a token's active assets array.
     * @param tokenId ID of the token for which the asset has been accepted
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to have been located at the specified index
     * @param replacedAssetId ID of the asset that has been replaced by the accepted asset
     */
    function _afterAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId,
        uint64 replacedAssetId
    ) internal virtual override {
        if(replacedAssetId != 0) {
            emit MetadataUpdate(tokenId);
        }
    }
    
    function setAutoAcceptCollection(
        address collection,
        bool autoAccept
    ) public virtual onlyOwnerOrContributor {
        _autoAcceptCollection[collection] = autoAccept;
    }

    function _afterAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory
    ) internal virtual override {
        // Auto accept children if they are from known collections
        if (_autoAcceptCollection[childAddress]) {
            _acceptChild(
                tokenId,
                _pendingChildren[tokenId].length - 1,
                childAddress,
                childId
            );
        }
    }
    
    function lockSupply() external onlyOwner {
      _maxSupply = _totalSupply;
    }
    
    /**
     * @notice Used to get whether the contract-level metadata is frozen and cannot be further updated.
     * @return isFrozen Whether the contract-level metadata is frozen
     */
    function isContractURIFrozen() external view returns (bool isFrozen) {
        isFrozen = _contractURIFrozen == 1;
    }

    /**
     * @notice Freezes the contract-level metadata, so it cannot be further updated.
     */
    function freezeContractURI() external onlyOwner {
        _contractURIFrozen = 1;
    }

    /**
     * @notice Sets the contract-level metadata URI to a new value and emits an event.
     * @param contractURI_ The new contract-level metadata URI
     */
    function setContractURI(string memory contractURI_) external onlyOwner {
        if (_contractURIFrozen == 1) {
            revert ContractURIFrozen();
        }
        _contractURI = contractURI_;
        emit ContractURIUpdated();
    }
    
    function batchAddEquippableAssetEntries(
        string[] memory metadataURIs,
        uint64[][] memory partIds,
        address catalogAddress,
        uint64 equippableGroupId
    ) public virtual onlyOwnerOrContributor {
        uint256 length = metadataURIs.length;
        if (length != partIds.length) revert LengthMismatch();

        for (uint256 i; i < length; ) {
            unchecked {
                ++_totalAssets;
            }
            _addAssetEntry(
                uint64(_totalAssets),
                equippableGroupId,
                catalogAddress,
                metadataURIs[i],
                partIds[i]
            );
            unchecked {
                ++i;
            }
        }
    }
    
    function mintWithAsset(
        address to,
        uint256 amount,
        uint64 assetId
    ) public virtual onlyOwnerOrContributor {
        (uint256 nextToken, uint256 totalSupplyOffset) = _prepareMint(
            amount
        );

        for (uint256 i = nextToken; i < totalSupplyOffset; ) {
            _safeMint(to, i, "");
            _addAssetToToken(i, assetId, 0);
            // _acceptAsset(i, 0, assetId); // Auto accepted
            unchecked {
                ++i;
            }
        }
    }
    
}
  