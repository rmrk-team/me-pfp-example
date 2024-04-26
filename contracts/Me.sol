// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.21;

import {
    RMRKAbstractEquippable
} from "@rmrk-team/evm-contracts/contracts/implementations/abstract/RMRKAbstractEquippable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    RMRKImplementationBase
} from "@rmrk-team/evm-contracts/contracts/implementations/utils/RMRKImplementationBase.sol";
import {
    RMRKTokenHolder
} from "@rmrk-team/evm-contracts/contracts/RMRK/extension/tokenHolder/RMRKTokenHolder.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

error ContractURIFrozen();
error LimitExceeded();
error OnlyNFTOwnerCanTransferTokensFromIt();

contract ME is RMRKAbstractEquippable, RMRKTokenHolder {
    using Strings for uint256;

    // Events

    /**
     * @notice From ERC7572 (Draft) Emitted when the contract-level metadata is updated
     */
    event ContractURIUpdated();

    // Variables
    address private _erc20TokenAddress;
    mapping(uint64 assetId => uint256 price) private _pricePerAsset;
    mapping(uint64 assetId => string imgUri) private _imgPerAsset;
    mapping(address => bool) private _autoAcceptCollection;
    bool private _autoAcceptAllCollections;
    uint256 private _contractURIFrozen; // Cheaper than a bool
    uint256 private _limitPerHolder;
    string private _baseAnimationURI;

    // Constructor
    constructor(
        string memory collectionMetadata,
        uint256 maxSupply,
        address royaltyRecipient,
        uint16 royaltyPercentageBps
    )
        RMRKImplementationBase(
            "ME",
            "ME",
            collectionMetadata,
            maxSupply,
            royaltyRecipient,
            royaltyPercentageBps
        )
    {}

    // TOKEN URI

    function setImgUri(
        uint64 assetId,
        string memory imgUri
    ) external onlyOwnerOrContributor {
        _imgPerAsset[assetId] = imgUri;
    }

    function setBaseAnimationURI(
        string memory baseAnimationURI
    ) external onlyOwnerOrContributor {
        _baseAnimationURI = baseAnimationURI;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        _requireMinted(tokenId);
        string memory tokenID = tokenId.toString();
        uint64 mainAssetId = getActiveAssets(tokenId)[0];
        string memory imgURI = _imgPerAsset[mainAssetId];
        string memory json = string(
            abi.encodePacked(
                '{\n\t"name": "ME Avatar #',
                tokenID,
                '",\n\t"description": "Your ME avatar, ready to be equipped with different NFTs to create your unique digital identity. Only possible with RMRK modular NFTs. Freedom to be ME!',
                '",\n\t"external_url": "https://singular.app/',
                '",\n\t"image": "',
                imgURI,
                '",\n\t"mediaUri": "',
                imgURI,
                '",\n\t"animation_url": "',
                _baseAnimationURI,
                tokenID,
                '"\n}'
            )
        ); // format the json

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            ); // return the full concatenated string
    }

    // MINTING

    /**
     * @notice Used to retrieve the address of the ERC20 token this smart contract supports.
     * @return Address of the ERC20 token's smart contract
     */
    function erc20TokenAddress() public view virtual returns (address) {
        return _erc20TokenAddress;
    }

    /**
     * @notice Used to retrieve the price per mint.
     * @return The price per mint of a single token expressed in the lowest denomination of a native currency
     */
    function getPricePerAsset(uint64 assetId) public view returns (uint256) {
        return _pricePerAsset[assetId];
    }

    function getLimitPerHolder() public view returns (uint256) {
        return _limitPerHolder;
    }

    function mintWithAsset(
        address to,
        uint256 amount,
        uint64 assetId
    ) public virtual {
        if (_limitPerHolder != 0 && balanceOf(to) + amount > _limitPerHolder) {
            revert LimitExceeded();
        }
        _chargeMints(amount, assetId);
        (uint256 nextToken, uint256 totalSupplyOffset) = _prepareMint(amount);

        for (uint256 i = nextToken; i < totalSupplyOffset; ) {
            _safeMint(to, i, "");
            _addAssetToToken(i, assetId, 0);
            // _acceptAsset(i, 0, assetId); // Auto accepted
            unchecked {
                ++i;
            }
        }
    }

    function setPricePerAsset(
        uint64 assetId,
        uint256 price
    ) public onlyOwnerOrContributor {
        _pricePerAsset[assetId] = price;
    }

    function setLimitPerHolder(uint256 limit) public onlyOwnerOrContributor {
        _limitPerHolder = limit;
    }

    function setERC20TokenAddress(address erc20) public onlyOwnerOrContributor {
        _erc20TokenAddress = erc20;
    }

    /**
     * @notice Used to withdraw the minting proceedings to a specified address.
     * @dev This function can only be called by the owner.
     * @param erc20 Address of the ERC20 token to withdraw
     * @param to Address to receive the given amount of minting proceedings
     * @param amount The amount to withdraw
     */
    function withdrawRaisedERC20(
        address erc20,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(erc20).transfer(to, amount);
    }

    // CONTRACT URI

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
    function freezeContractURI() external onlyOwnerOrContributor {
        _contractURIFrozen = 1;
    }

    /**
     * @notice Sets the contract-level metadata URI to a new value and emits an event.
     * @param contractURI_ The new contract-level metadata URI
     */
    function setContractURI(
        string memory contractURI_
    ) external onlyOwnerOrContributor {
        if (_contractURIFrozen == 1) {
            revert ContractURIFrozen();
        }
        _contractURI = contractURI_;
        emit ContractURIUpdated();
    }

    // OTHER

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(RMRKTokenHolder, RMRKAbstractEquippable)
        returns (bool)
    {
        return
            RMRKAbstractEquippable.supportsInterface(interfaceId) ||
            RMRKTokenHolder.supportsInterface(interfaceId);
    }

    function setAutoAcceptAllCollections(
        bool autoAccept
    ) public virtual onlyOwnerOrContributor {
        _autoAcceptAllCollections = autoAccept;
    }

    function setAutoAcceptCollection(
        address collection,
        bool autoAccept
    ) public virtual onlyOwnerOrContributor {
        _autoAcceptCollection[collection] = autoAccept;
    }

    function lockSupply() external onlyOwnerOrContributor {
        _maxSupply = _totalSupply;
    }

    function transferHeldERC20FromToken(
        address erc20Contract,
        uint256 tokenHolderId,
        address to,
        uint256 amount,
        bytes memory data
    ) external {
        if (_msgSender() != ownerOf(tokenHolderId)) {
            revert OnlyNFTOwnerCanTransferTokensFromIt();
        }
        _transferHeldERC20FromToken(
            erc20Contract,
            tokenHolderId,
            to,
            amount,
            data
        );
    }

    // HELPERS

    function _afterAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory
    ) internal virtual override {
        // Auto accept children if autoaccept for all is enabled or if they are from known collections
        if (_autoAcceptAllCollections || _autoAcceptCollection[childAddress]) {
            _acceptChild(
                tokenId,
                _pendingChildren[tokenId].length - 1,
                childAddress,
                childId
            );
        }
    }

    /**
     * @notice Used to charge the minter for the amount of tokens they desire to mint.
     * @param numToMint The amount of tokens to charge the caller for
     */
    function _chargeMints(uint256 numToMint, uint64 assetId) internal {
        if (_pricePerAsset[assetId] == 0) return;
        uint256 price = numToMint * _pricePerAsset[assetId];
        IERC20(_erc20TokenAddress).transferFrom(
            msg.sender,
            address(this),
            price
        );
    }
}
