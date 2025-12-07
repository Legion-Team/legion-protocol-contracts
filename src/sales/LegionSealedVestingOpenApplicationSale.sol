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

import { Constants } from "../utils/Constants.sol";
import { ECIES, Point } from "../lib/ECIES.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionSealedVestingOpenApplicationSale } from
    "../interfaces/sales/ILegionSealedVestingOpenApplicationSale.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionAbstractSale } from "./LegionAbstractSale.sol";

/**
 * @title Legion Pre-Liquid Sealed-Vesting Open Application Sale
 * @author Legion
 * @notice Executes pre-liquid sales of ERC20 tokens before Token Generation Event (TGE).
 * @dev Inherits from LegionAbstractSale and implements ILegionSealedVestingOpenApplicationSale for open application
 * pre-liquid sale management.
 */
contract LegionSealedVestingOpenApplicationSale is LegionAbstractSale, ILegionSealedVestingOpenApplicationSale {
    /// @dev Struct containing the pre-liquid sale configuration
    PreLiquidSaleConfiguration private s_preLiquidSaleConfig;

    /// @notice Restricts interaction to when the sale has ended.
    /// @dev Reverts if the sale has not ended.
    modifier whenSaleEnded() {
        // Verify that the sale has ended
        _verifySaleHasEnded();
        _;
    }

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

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        initializer
    {
        // Initialize and set the sale common parameters
        _setLegionSaleConfig(saleInitParams);

        // Verify if the sale initialization parameters are valid
        _verifyValidParams(preLiquidSaleInitParams);
        // Set the sale start time
        s_saleConfig.startTime = uint64(block.timestamp);

        // Set the refund period duration in seconds
        s_preLiquidSaleConfig.refundPeriodSeconds = saleInitParams.refundPeriodSeconds;

        // Set the public key for encrypting sealed vesting options
        s_preLiquidSaleConfig.publicKey = preLiquidSaleInitParams.publicKey;
    }

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function invest(
        uint256 amount,
        uint256 deadline,
        bytes calldata sealedVestingOption,
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

        // Decode the sealed vesting data
        (uint256 encryptedVestingOption, Point memory sealedVestingOptionPublicKey) =
            abi.decode(sealedVestingOption, (uint256, Point));

        // Verify that the provided public key is valid
        _verifyValidPublicKey(sealedVestingOptionPublicKey);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the investor has not claimed excess capital
        _verifyHasNotClaimedExcess(positionId);

        // Increment total capital invested from all investors
        s_saleStatus.totalCapitalInvested += amount;

        // Increment total invested capital for the investor
        s_investorPositions[positionId].investedCapital += amount;

        // Emit CapitalInvested event
        emit CapitalInvested(amount, encryptedVestingOption, msg.sender, positionId);

        // Collect Legion's operations fee
        _handleOpsFee();

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function updateSealedVestingOption(bytes calldata newSealedVestingOption)
        external
        whenNotPaused
        whenSaleNotEnded
        whenSaleNotCanceled
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the investor has not claimed excess capital
        _verifyHasNotClaimedExcess(positionId);

        // Decode the sealed vesting data
        (uint256 encryptedVestingOption, Point memory publicKey) = abi.decode(newSealedVestingOption, (uint256, Point));

        // Verify that the provided public key is valid
        _verifyValidPublicKey(publicKey);

        // Emit VestingOptionEdited event
        emit SealedVestingOptionUpdated(positionId, msg.sender, encryptedVestingOption);
    }

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function end() external onlyLegionOrProject whenNotPaused whenSaleNotCanceled whenSaleNotEnded {
        // Update the `hasEnded` status to true
        s_preLiquidSaleConfig.hasEnded = true;

        // Set the `endTime` of the sale
        s_saleConfig.endTime = uint64(block.timestamp);

        // Set the `refundEndTime` of the sale
        s_saleConfig.refundEndTime = uint64(block.timestamp) + s_preLiquidSaleConfig.refundPeriodSeconds;

        // Emit SaleEnded event
        emit SaleEnded();
    }

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function publishRaisedCapital(uint256 capitalRaised)
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
    {
        // Verify that capital raised can be published.
        _verifyCanPublishCapitalRaised();

        // Set the total capital raised to be withdrawn by the project
        s_saleStatus.totalCapitalRaised = capitalRaised;

        // Emit CapitalRaisedPublished event
        emit CapitalRaisedPublished(capitalRaised);
    }

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function initializeReveal()
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenCancelNotLocked
        whenRefundPeriodIsOver
    {
        // Flag that the sale is locked from canceling
        s_preLiquidSaleConfig.cancelLocked = true;

        // Emit RevealInitialized event
        emit RevealInitialized();
    }

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function reveal(
        uint256 sealedVestingOptionPrivateKey,
        uint256 fixedSalt
    )
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
        whenCancelLocked
    {
        // Verify if the provided private key is valid
        _verifyValidPrivateKey(sealedVestingOptionPrivateKey);

        // Set the private key used to decrypt sealed bids
        s_preLiquidSaleConfig.privateKey = sealedVestingOptionPrivateKey;

        // Set the fixed salt used for sealing bids
        s_preLiquidSaleConfig.fixedSalt = fixedSalt;

        // Emit Revealed event
        emit Revealed(sealedVestingOptionPrivateKey, fixedSalt);
    }

    /// @inheritdoc ILegionAbstractSale
    function withdrawRaisedCapital()
        external
        override(ILegionAbstractSale, LegionAbstractSale)
        onlyProject
        whenNotPaused
        whenSaleEnded
        whenRefundPeriodIsOver
        whenSaleNotCanceled
    {
        // Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        // Flag that the capital has been withdrawn
        s_saleStatus.capitalWithdrawn = true;

        // Cache value in memory
        uint256 _totalCapitalRaised = s_saleStatus.totalCapitalRaised;

        // Set the total capital that has been withdrawn
        s_saleStatus.totalCapitalWithdrawn = _totalCapitalRaised;

        // Cache Legion Sale Address Configuration
        LegionSaleAddressConfiguration memory addressConfig = s_addressConfig;

        // Cache Legion Sale Configuration
        LegionSaleConfiguration memory saleConfig = s_saleConfig;

        // Calculate Legion Fee
        uint256 _legionFee =
            (saleConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate Referrer Fee
        uint256 _referrerFee =
            (saleConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Emit CapitalWithdrawn event
        emit CapitalWithdrawn(_totalCapitalRaised);

        // Transfer the raised capital to the project owner
        SafeTransferLib.safeTransfer(
            addressConfig.bidToken, msg.sender, (_totalCapitalRaised - _legionFee - _referrerFee)
        );

        // Transfer the Legion fee to the Legion fee receiver address
        if (_legionFee != 0) {
            SafeTransferLib.safeTransfer(addressConfig.bidToken, addressConfig.legionFeeReceiver, _legionFee);
        }

        // Transfer the Referrer fee to the Referrer fee receiver address
        if (_referrerFee != 0) {
            SafeTransferLib.safeTransfer(addressConfig.bidToken, addressConfig.referrerFeeReceiver, _referrerFee);
        }
    }

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory) {
        return s_preLiquidSaleConfig;
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

    /// @inheritdoc ILegionSealedVestingOpenApplicationSale
    function decryptSealedVestingOption(
        uint256 encryptedVestingOption,
        address investor
    )
        external
        view
        returns (uint256)
    {
        // Verify that the private key has been published by Legion
        _verifyPrivateKeyIsPublished();

        // Cache the sealed pre-liquid sealed vesting sale configuration
        PreLiquidSaleConfiguration memory preLiquidSaleConfig = s_preLiquidSaleConfig;

        // Decrypt the sealed vesting option
        return ECIES.decrypt(
            encryptedVestingOption,
            preLiquidSaleConfig.publicKey,
            preLiquidSaleConfig.privateKey,
            uint256(keccak256(abi.encodePacked(investor, preLiquidSaleConfig.fixedSalt)))
        );
    }

    /// @dev Verifies that the sale has not ended.
    function _verifySaleHasNotEnded() internal view override {
        if (s_preLiquidSaleConfig.hasEnded) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /// @dev Verifies that the refund period has ended.
    function _verifyRefundPeriodIsOver() internal view override {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleConfig.refundEndTime;

        if (refundEndTime > 0 && block.timestamp < refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies that the refund period is still active.
    function _verifyRefundPeriodIsNotOver() internal view override {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleConfig.refundEndTime;

        if (refundEndTime > 0 && block.timestamp >= refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies conditions for withdrawing capital.
    function _verifyCanWithdrawCapital() internal view override {
        // Load the sale status
        LegionSaleStatus memory saleStatus = s_saleStatus;

        if (saleStatus.capitalWithdrawn) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        if (saleStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalRaisedNotPublished();
    }

    /// @dev Verifies that the sale has ended.
    function _verifySaleHasEnded() private view {
        if (!s_preLiquidSaleConfig.hasEnded) revert Errors.LegionSale__SaleHasNotEnded(block.timestamp);
    }

    /// @dev Verifies conditions for publishing capital raised.
    function _verifyCanPublishCapitalRaised() private view {
        if (s_saleStatus.totalCapitalRaised != 0) revert Errors.LegionSale__CapitalRaisedAlreadyPublished();
    }

    /// @dev Verifies the validity of sealed vesting sale initialization parameters.
    /// @param _preLiquidSaleInitParams The auction-specific parameters to validate.
    function _verifyValidParams(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams) private pure {
        // Check if the public key used for encryption is valid
        if (!ECIES.isValid(_preLiquidSaleInitParams.publicKey)) {
            revert Errors.LegionSale__InvalidBidPublicKey();
        }
    }

    /// @dev Verifies the validity of the public key used in a sealed vesting option.
    /// @param _publicKey The public key provided in the sealed vesting option.
    function _verifyValidPublicKey(Point memory _publicKey) private view {
        // Verify that the _publicKey is a valid point for the encryption library
        if (!ECIES.isValid(_publicKey)) revert Errors.LegionSale__InvalidBidPublicKey();

        // Cache the pre-liquid sealed vesting sale configuration
        PreLiquidSaleConfiguration memory preLiquidSaleConfig = s_preLiquidSaleConfig;

        // Verify that the _publicKey is the one used for the entire auction
        if (
            keccak256(abi.encodePacked(_publicKey.x, _publicKey.y))
                != keccak256(abi.encodePacked(preLiquidSaleConfig.publicKey.x, preLiquidSaleConfig.publicKey.y))
        ) revert Errors.LegionSale__InvalidBidPublicKey();
    }

    /// @dev Verifies the validity of the private key for decrypting sealed vesting options.
    /// @param _privateKey The private key provided for decryption.
    function _verifyValidPrivateKey(uint256 _privateKey) private view {
        // Cache the sealed pre-liquid sealed vesting sale configuration
        PreLiquidSaleConfiguration memory preLiquidSaleConfig = s_preLiquidSaleConfig;

        // Verify that the private key has not already been published
        if (preLiquidSaleConfig.privateKey != 0) {
            revert Errors.LegionSale__PrivateKeyAlreadyPublished();
        }

        // Verify that the private key is valid for the public key
        Point memory calcPubKey = ECIES.calcPubKey(Point(1, 2), _privateKey);
        if (calcPubKey.x != preLiquidSaleConfig.publicKey.x || calcPubKey.y != preLiquidSaleConfig.publicKey.y) {
            revert Errors.LegionSale__InvalidBidPrivateKey();
        }
    }

    /// @dev Verifies that the private key has been published.
    function _verifyPrivateKeyIsPublished() private view {
        if (s_preLiquidSaleConfig.privateKey == 0) {
            revert Errors.LegionSale__PrivateKeyNotPublished();
        }
    }

    /// @dev Verifies that cancellation is not locked.
    function _verifyCancelNotLocked() private view {
        if (s_preLiquidSaleConfig.cancelLocked) {
            revert Errors.LegionSale__CancelLocked();
        }
    }

    /// @dev Verifies that cancellation is locked.
    function _verifyCancelLocked() private view {
        if (!s_preLiquidSaleConfig.cancelLocked) {
            revert Errors.LegionSale__CancelNotLocked();
        }
    }
}
