// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

//       ___       ___           ___                       ___           ___
//      /\__\     /\  \         /\  \          ___        /\  \         /\__\
//     /:/  /    /::\  \       /::\  \        /\  \      /::\  \       /::|  |
//    /:/  /    /:/\:\  \     /:/\:\  \       \:\  \    /:/\:\  \     /:|:|  |
//   /:/  /    /::\~\:\  \   /:/  \:\  \      /::\__\  /:/  \:\  \   /:/|:|  |__
//  /:/__/    /:/\:\ \:\__\ /:/__/_\:\__\  __/:/\/__/ /:/__/ \:\__\ /:/ |:| /\__\
//  \:\  \    \:\~\:\ \/__/ \:\  /\ \/__/ /\/:/  /    \:\  \ /:/  / \/__|:|/:/  /
//   \:\  \    \:\ \:\__\    \:\ \:\__\   \::/__/      \:\  /:/  /      |:/:/  /
//    \:\  \    \:\ \/__/     \:\/:/  /    \:\__\       \:\/:/  /       |::/  /
//     \:\__\    \:\__\        \::/  /      \/__/        \::/  /        /:/  /
//      \/__/     \/__/         \/__/                     \/__/         \/__/

import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { ECIES, Point } from "../lib/ECIES.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";
import { ILegionSealedBidAuctionSale } from "../interfaces/sales/ILegionSealedBidAuctionSale.sol";

import { LegionAbstractSale } from "./LegionAbstractSale.sol";

/**
 * @title Legion Sealed Bid Auction
 * @author Legion
 * @notice Executes sealed bid auctions of ERC20 tokens after Token Generation Event (TGE).
 * @dev Inherits from LegionAbstractSale and implements ILegionSealedBidAuctionSale with ECIES encryption features for
 * bid privacy.
 */
contract LegionSealedBidAuctionSale is LegionAbstractSale, ILegionSealedBidAuctionSale {
    /// @dev Struct containing the sealed bid auction sale configuration
    SealedBidAuctionSaleConfiguration private s_sealedBidAuctionSaleConfig;

    /// @notice Restricts interaction to when the sale cancelation is locked.
    /// @dev Reverts if canceling is not locked.
    modifier whenCancelLocked() {
        // Verify that canceling is locked
        _verifyCancelLocked();
        _;
    }

    /// @notice Restricts interaction to when the sale cancelation is not locked.
    /// @dev Reverts if canceling is locked.
    modifier whenCancelNotLocked() {
        // Verify that canceling is not locked
        _verifyCancelNotLocked();
        _;
    }

    /// @inheritdoc ILegionSealedBidAuctionSale
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams
    )
        external
        initializer
    {
        // Verify if the sale initialization parameters are valid
        _verifyValidParams(sealedBidAuctionSaleInitParams);

        // Initialize and set the sale common parameters
        _setLegionSaleConfig(saleInitParams);

        // Set the sealed bid auction sale specific configuration
        (s_sealedBidAuctionSaleConfig.publicKey) = sealedBidAuctionSaleInitParams.publicKey;

        // Calculate and set startTime, endTime and refundEndTime
        s_saleConfig.startTime = uint64(block.timestamp);
        s_saleConfig.endTime = s_saleConfig.startTime + saleInitParams.salePeriodSeconds;
        s_saleConfig.refundEndTime = s_saleConfig.endTime + saleInitParams.refundPeriodSeconds;
    }

    /// @inheritdoc ILegionSealedBidAuctionSale
    function invest(
        uint256 amount,
        bytes calldata sealedBid,
        bytes calldata signature
    )
        external
        whenNotPaused
        whenSaleNotEnded
        whenSaleNotCanceled
    {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the investor is allowed to invest capital
        _verifyInvestSignature(signature);

        // Decode the sealed bid data
        (uint256 encryptedAmountOut, Point memory sealedBidPublicKey) = abi.decode(sealedBid, (uint256, Point));

        // Verify that the provided public key is valid
        _verifyValidPublicKey(sealedBidPublicKey);

        // Verify that the amount invested is more than the minimum required
        _verifyMinimumInvestAmount(amount);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the investor has not claimed excess capital
        _verifyHasNotClaimedExcess(positionId);

        // Increment total capital invested from all investors
        s_saleStatus.totalCapitalInvested += amount;

        // Increment total invested capital for the investor
        s_investorPositions[positionId].investedCapital += amount;

        // Emit CapitalInvested event
        emit CapitalInvested(amount, encryptedAmountOut, msg.sender, positionId);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /// @inheritdoc ILegionSealedBidAuctionSale
    function initializePublishSaleResults()
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenCancelNotLocked
        whenRefundPeriodIsOver
    {
        // Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        // Flag that the sale is locked from canceling
        s_sealedBidAuctionSaleConfig.cancelLocked = true;

        // Emit PublishSaleResultsInitialized event
        emit PublishSaleResultsInitialized();
    }

    /// @inheritdoc ILegionSealedBidAuctionSale
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint256 capitalRaised,
        uint256 sealedBidPrivateKey,
        uint256 fixedSalt
    )
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenRefundPeriodIsOver
        whenCancelLocked
    {
        // Verify if the provided private key is valid
        _verifyValidPrivateKey(sealedBidPrivateKey);

        // Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        // Set the merkle root for claiming tokens
        s_saleStatus.claimTokensMerkleRoot = claimMerkleRoot;

        // Set the merkle root for accepted capital
        s_saleStatus.acceptedCapitalMerkleRoot = acceptedMerkleRoot;

        // Set the total tokens to be allocated by the Project team
        s_saleStatus.totalTokensAllocated = tokensAllocated;

        // Set the total capital raised to be withdrawn by the project
        s_saleStatus.totalCapitalRaised = capitalRaised;

        // Set the private key used to decrypt sealed bids
        s_sealedBidAuctionSaleConfig.privateKey = sealedBidPrivateKey;

        // Set the fixed salt used for sealing bids
        s_sealedBidAuctionSaleConfig.fixedSalt = fixedSalt;

        // Emit SaleResultsPublished event
        emit SaleResultsPublished(
            claimMerkleRoot, acceptedMerkleRoot, tokensAllocated, capitalRaised, sealedBidPrivateKey, fixedSalt
        );
    }

    /// @inheritdoc ILegionSealedBidAuctionSale
    function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory) {
        return s_sealedBidAuctionSaleConfig;
    }

    /// @inheritdoc ILegionAbstractSale
    function cancel()
        public
        override(ILegionAbstractSale, LegionAbstractSale)
        onlyProject
        whenNotPaused
        whenCancelNotLocked
    {
        // Call parent method
        super.cancel();
    }

    /// @inheritdoc ILegionSealedBidAuctionSale
    function decryptSealedBid(uint256 encryptedAmountOut, address investor) external view returns (uint256) {
        // Verify that the private key has been published by Legion
        _verifyPrivateKeyIsPublished();

        // Cache the sealed bid auction sale configuration
        SealedBidAuctionSaleConfiguration memory sealedBidAuctionSaleConfig = s_sealedBidAuctionSaleConfig;

        // Decrypt the sealed bid
        return ECIES.decrypt(
            encryptedAmountOut,
            sealedBidAuctionSaleConfig.publicKey,
            sealedBidAuctionSaleConfig.privateKey,
            uint256(keccak256(abi.encodePacked(investor, sealedBidAuctionSaleConfig.fixedSalt)))
        );
    }

    /// @dev Verifies the validity of sealed bid auction initialization parameters.
    /// @param _sealedBidAuctionSaleInitParams The auction-specific parameters to validate.
    function _verifyValidParams(SealedBidAuctionSaleInitializationParams calldata _sealedBidAuctionSaleInitParams)
        private
        pure
    {
        // Check if the public key used for encryption is valid
        if (!ECIES.isValid(_sealedBidAuctionSaleInitParams.publicKey)) {
            revert Errors.LegionSale__InvalidBidPublicKey();
        }
    }

    /// @dev Verifies the validity of the public key used in a sealed bid.
    /// @param _publicKey The public key provided in the sealed bid.
    function _verifyValidPublicKey(Point memory _publicKey) private view {
        // Verify that the _publicKey is a valid point for the encryption library
        if (!ECIES.isValid(_publicKey)) revert Errors.LegionSale__InvalidBidPublicKey();

        // Cache the sealed bid auction sale configuration
        SealedBidAuctionSaleConfiguration memory sealedBidAuctionSaleConfig = s_sealedBidAuctionSaleConfig;

        // Verify that the _publicKey is the one used for the entire auction
        if (
            keccak256(abi.encodePacked(_publicKey.x, _publicKey.y))
                != keccak256(
                    abi.encodePacked(sealedBidAuctionSaleConfig.publicKey.x, sealedBidAuctionSaleConfig.publicKey.y)
                )
        ) revert Errors.LegionSale__InvalidBidPublicKey();
    }

    /// @dev Verifies the validity of the private key for decrypting bids.
    /// @param _privateKey The private key provided for decryption.
    function _verifyValidPrivateKey(uint256 _privateKey) private view {
        // Cache the sealed bid auction sale configuration
        SealedBidAuctionSaleConfiguration memory sealedBidAuctionSaleConfig = s_sealedBidAuctionSaleConfig;

        // Verify that the private key has not already been published
        if (sealedBidAuctionSaleConfig.privateKey != 0) {
            revert Errors.LegionSale__PrivateKeyAlreadyPublished();
        }

        // Verify that the private key is valid for the public key
        Point memory calcPubKey = ECIES.calcPubKey(Point(1, 2), _privateKey);
        if (
            calcPubKey.x != sealedBidAuctionSaleConfig.publicKey.x
                || calcPubKey.y != sealedBidAuctionSaleConfig.publicKey.y
        ) revert Errors.LegionSale__InvalidBidPrivateKey();
    }

    /// @dev Verifies that the private key has been published.
    function _verifyPrivateKeyIsPublished() private view {
        if (s_sealedBidAuctionSaleConfig.privateKey == 0) {
            revert Errors.LegionSale__PrivateKeyNotPublished();
        }
    }

    /// @dev Verifies that cancellation is not locked.
    function _verifyCancelNotLocked() private view {
        if (s_sealedBidAuctionSaleConfig.cancelLocked) {
            revert Errors.LegionSale__CancelLocked();
        }
    }

    /// @dev Verifies that cancellation is locked.
    function _verifyCancelLocked() private view {
        if (!s_sealedBidAuctionSaleConfig.cancelLocked) {
            revert Errors.LegionSale__CancelNotLocked();
        }
    }
}
