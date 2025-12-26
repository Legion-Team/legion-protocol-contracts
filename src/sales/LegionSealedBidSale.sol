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
import { ILegionSealedBidSale } from "../interfaces/sales/ILegionSealedBidSale.sol";

import { LegionAbstractSale } from "./LegionAbstractSale.sol";

/**
 * @title Legion Sealed Bid Sale
 * @author Legion
 * @notice Executes sealed bid sales of ERC20 tokens after Token Generation Event (TGE).
 * @dev Inherits from LegionAbstractSale and implements ILegionSealedBidSale with ECIES encryption features for
 * bid privacy.
 */
contract LegionSealedBidSale is LegionAbstractSale, ILegionSealedBidSale {
    /// @dev Struct containing the sealed bid sale configuration
    SealedBidSaleConfiguration private s_sealedBidSaleConfig;

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

    /// @inheritdoc ILegionSealedBidSale
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        SealedBidSaleInitializationParams calldata sealedBidSaleInitParams
    )
        external
        initializer
    {
        // Verify if the sale initialization parameters are valid
        _verifyValidParams(sealedBidSaleInitParams);

        // Initialize and set the sale common parameters
        _setLegionSaleConfig(saleInitParams);

        // Set the sealed bid sale specific configuration
        (s_sealedBidSaleConfig.publicKey) = sealedBidSaleInitParams.publicKey;

        // Calculate and set startTime, endTime and refundEndTime
        s_saleConfig.startTime = uint64(block.timestamp);
        s_saleConfig.endTime = s_saleConfig.startTime + saleInitParams.salePeriodSeconds;
        s_saleConfig.refundEndTime = s_saleConfig.endTime + saleInitParams.refundPeriodSeconds;
    }

    /// @inheritdoc ILegionSealedBidSale
    function invest(
        uint256 amount,
        uint256 deadline,
        bytes calldata sealedBid,
        bytes calldata signature
    )
        external
        payable
        whenNotPaused
        whenSaleNotEnded
        whenSaleNotCanceled
    {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the amount invested is more than the minimum required
        _verifyMinimumInvestAmount(amount);

        // Verify that the investor is allowed to invest capital
        _verifyInvestSignature(signature, amount, deadline);

        // Decode the sealed bid data
        (uint256 encryptedAmountOut, Point memory sealedBidPublicKey) = abi.decode(sealedBid, (uint256, Point));

        // Verify that the provided public key is valid
        _verifyValidPublicKey(sealedBidPublicKey);

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

        // Collect Legion's operations fee
        _handleOpsFee();

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /// @inheritdoc ILegionSealedBidSale
    function initializeReveal()
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenCancelNotLocked
        whenRefundPeriodIsOver
    {
        // Flag that the sale is locked from canceling
        s_sealedBidSaleConfig.cancelLocked = true;

        // Emit RevealInitialized event
        emit RevealInitialized();
    }

    /// @inheritdoc ILegionSealedBidSale
    function reveal(
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

        // Set the private key used to decrypt sealed bids
        s_sealedBidSaleConfig.privateKey = sealedBidPrivateKey;

        // Set the fixed salt used for sealing bids
        s_sealedBidSaleConfig.fixedSalt = fixedSalt;

        // Emit Revealed event
        emit Revealed(sealedBidPrivateKey, fixedSalt);
    }

    /// @inheritdoc ILegionSealedBidSale
    function publishRaisedCapital(uint256 capitalRaised)
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenRefundPeriodIsOver
    {
        // Verify that capital raised can be published.
        _verifyCanPublishCapitalRaised();

        // Set the total capital raised to be withdrawn by the project
        s_saleStatus.totalCapitalRaised = capitalRaised;

        // Emit CapitalRaisedPublished event
        emit CapitalRaisedPublished(capitalRaised);
    }

    /// @inheritdoc ILegionSealedBidSale
    function sealedBidSaleConfiguration() external view returns (SealedBidSaleConfiguration memory) {
        return s_sealedBidSaleConfig;
    }

    /// @inheritdoc ILegionAbstractSale
    function cancel()
        public
        override(ILegionAbstractSale, LegionAbstractSale)
        onlyProject
        whenNotPaused
        whenSaleNotCanceled
        whenCancelNotLocked
    {
        // Call parent method
        super.cancel();
    }

    /// @inheritdoc ILegionSealedBidSale
    function decryptSealedBid(uint256 encryptedAmountOut, address investor) external view returns (uint256) {
        // Verify that the private key has been published by Legion
        _verifyPrivateKeyIsPublished();

        // Cache the sealed bid sale configuration
        SealedBidSaleConfiguration memory sealedBidSaleConfig = s_sealedBidSaleConfig;

        // Decrypt the sealed bid
        return ECIES.decrypt(
            encryptedAmountOut,
            sealedBidSaleConfig.publicKey,
            sealedBidSaleConfig.privateKey,
            uint256(keccak256(abi.encodePacked(investor, sealedBidSaleConfig.fixedSalt)))
        );
    }

    /// @dev Verifies the validity of sealed bid sale initialization parameters.
    /// @param _sealedBidSaleInitParams The sale-specific parameters to validate.
    function _verifyValidParams(SealedBidSaleInitializationParams calldata _sealedBidSaleInitParams) private pure {
        // Check if the public key used for encryption is valid
        if (!ECIES.isValid(_sealedBidSaleInitParams.publicKey)) {
            revert Errors.LegionSale__InvalidBidPublicKey();
        }
    }

    /// @dev Verifies the validity of the public key used in a sealed bid.
    /// @param _publicKey The public key provided in the sealed bid.
    function _verifyValidPublicKey(Point memory _publicKey) private view {
        // Verify that the _publicKey is a valid point for the encryption library
        if (!ECIES.isValid(_publicKey)) revert Errors.LegionSale__InvalidBidPublicKey();

        // Cache the sealed bid sale configuration
        SealedBidSaleConfiguration memory sealedBidSaleConfig = s_sealedBidSaleConfig;

        // Verify that the _publicKey is the one used for the entire sale
        if (
            keccak256(abi.encodePacked(_publicKey.x, _publicKey.y))
                != keccak256(abi.encodePacked(sealedBidSaleConfig.publicKey.x, sealedBidSaleConfig.publicKey.y))
        ) revert Errors.LegionSale__InvalidBidPublicKey();
    }

    /// @dev Verifies the validity of the private key for decrypting bids.
    /// @param _privateKey The private key provided for decryption.
    function _verifyValidPrivateKey(uint256 _privateKey) private view {
        // Cache the sealed bid sale configuration
        SealedBidSaleConfiguration memory sealedBidSaleConfig = s_sealedBidSaleConfig;

        // Verify that the private key has not already been published
        if (sealedBidSaleConfig.privateKey != 0) {
            revert Errors.LegionSale__PrivateKeyAlreadyPublished();
        }

        // Verify that the private key is valid for the public key
        Point memory calcPubKey = ECIES.calcPubKey(Point(1, 2), _privateKey);
        if (calcPubKey.x != sealedBidSaleConfig.publicKey.x || calcPubKey.y != sealedBidSaleConfig.publicKey.y) {
            revert Errors.LegionSale__InvalidBidPrivateKey();
        }
    }

    /// @dev Verifies that the private key has been published.
    function _verifyPrivateKeyIsPublished() private view {
        if (s_sealedBidSaleConfig.privateKey == 0) {
            revert Errors.LegionSale__PrivateKeyNotPublished();
        }
    }

    /// @dev Verifies that cancellation is not locked.
    function _verifyCancelNotLocked() private view {
        if (s_sealedBidSaleConfig.cancelLocked) {
            revert Errors.LegionSale__CancelLocked();
        }
    }

    /// @dev Verifies that cancellation is locked.
    function _verifyCancelLocked() private view {
        if (!s_sealedBidSaleConfig.cancelLocked) {
            revert Errors.LegionSale__CancelNotLocked();
        }
    }

    /// @dev Verifies conditions for publishing capital raised.
    function _verifyCanPublishCapitalRaised() private view {
        if (s_saleStatus.totalCapitalRaised != 0) revert Errors.LegionSale__CapitalRaisedAlreadyPublished();
    }
}
