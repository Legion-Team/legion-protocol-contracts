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

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionCapitalRaise } from "../interfaces/raise/ILegionCapitalRaise.sol";

import { LegionPositionManager } from "../position/LegionPositionManager.sol";

/**
 * @title Legion Capital Raise
 * @author Legion
 * @notice Manages capital raising for ERC20 token sales before Token Generation Event (TGE).
 * @dev Handles the complete pre-liquid capital raise lifecycle including investments, refunds, withdrawals, and
 * position management using soulbound NFTs.
 */
contract LegionCapitalRaise is ILegionCapitalRaise, LegionPositionManager, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev Struct containing the pre-liquid capital raise configuration.
    CapitalRaiseConfig private s_capitalRaiseConfig;

    /// @dev Struct tracking the current capital raise status.
    CapitalRaiseStatus private s_capitalRaiseStatus;

    /// @dev Mapping of position IDs to their positions.
    mapping(uint256 s_positionId => InvestorPosition s_investorPosition) private s_investorPositions;

    /// @dev Mapping to track used signatures per investor.
    mapping(address s_investorAddress => mapping(bytes s_signature => bool s_used) s_usedSignature) private
        s_usedSignatures;

    /// @notice Restricts function access to the Legion bouncer only.
    /// @dev Reverts if the caller is not the configured Legion bouncer address.
    modifier onlyLegion() {
        if (msg.sender != s_capitalRaiseConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /// @notice Restricts function access to the project admin only.
    /// @dev Reverts if the caller is not the configured project admin address.
    modifier onlyProject() {
        if (msg.sender != s_capitalRaiseConfig.projectAdmin) revert Errors.LegionSale__NotCalledByProject();
        _;
    }

    /// @notice Restricts function access to either Legion bouncer or project admin.
    /// @dev Reverts if the caller is neither the project admin nor Legion bouncer.
    modifier onlyLegionOrProject() {
        if (msg.sender != s_capitalRaiseConfig.projectAdmin && msg.sender != s_capitalRaiseConfig.legionBouncer) {
            revert Errors.LegionSale__NotCalledByLegionOrProject();
        }
        _;
    }

    /// @notice Restricts function execution when the capital raise is canceled.
    /// @dev Reverts if the capital raise has not been canceled.
    modifier whenRaiseCanceled() {
        // Verify that the capital raise has been canceled
        _verifyCapitalRaiseIsCanceled();
        _;
    }

    /// @notice Restricts function execution when the capital raise is not canceled.
    /// @dev Reverts if the capital raise has been canceled.
    modifier whenRaiseNotCanceled() {
        // Verify that the capital raise has not been canceled
        _verifyCapitalRaisedNotCanceled();
        _;
    }

    /// @notice Restricts function execution when the capital raise has ended.
    /// @dev Reverts if the capital raise has not ended.
    modifier whenRaiseHasEnded() {
        // Verify that the capital raise has ended
        _verifyCapitalRaiseHasEnded();
        _;
    }

    /// @notice Restricts function execution when the capital raise has not ended.
    /// @dev Reverts if the capital raise has ended.
    modifier whenRaiseNotEnded() {
        // Verify that the capital raise has not ended
        _verifyCapitalRaiseHasNotEnded();
        _;
    }

    /// @notice Restricts interaction to when the refund period is over.
    /// @dev Reverts if the refund period is not over.
    modifier whenRefundPeriodIsOver() {
        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();
        _;
    }

    /// @notice Restricts interaction to when the refund period is not over.
    /// @dev Reverts if the refund period is over.
    modifier whenRefundPeriodNotOver() {
        // Verify that the refund period is not over
        _verifyRefundPeriodIsNotOver();
        _;
    }

    /// @notice Constructor for the LegionCapitalRaise contract.
    /// @dev Prevents the implementation contract from being initialized directly.
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /// @inheritdoc ILegionCapitalRaise
    function initialize(CapitalRaiseInitializationParams calldata capitalRaiseInitParams) external initializer {
        _setLegionCapitalRaiseConfig(capitalRaiseInitParams);
    }

    /// @inheritdoc ILegionCapitalRaise
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata investSignature
    )
        external
        whenNotPaused
        whenRaiseNotCanceled
        whenRaiseNotEnded
    {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the invest signature has not been used
        _verifySignatureNotUsed(investSignature);

        // Verify that the investor has not claimed excess capital
        _verifyCanClaimExcessCapital(positionId);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Increment total capital invested from investors
        s_capitalRaiseStatus.totalCapitalInvested += amount;

        // Increment total capital for the investor
        position.investedCapital += amount;

        // Mark the signature as used
        s_usedSignatures[msg.sender][investSignature] = true;

        // Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate);

        // Verify that the investor position is valid
        _verifyValidPosition(investSignature, positionId, CapitalRaiseAction.INVEST);

        // Emit CapitalInvested
        emit CapitalInvested(amount, msg.sender, positionId);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_capitalRaiseConfig.bidToken, msg.sender, address(this), amount);
    }

    /// @inheritdoc ILegionCapitalRaise
    function refund() external whenNotPaused whenRaiseNotCanceled whenRefundPeriodNotOver {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Cache the amount to refund in memory
        uint256 amountToRefund = position.investedCapital;

        // Set the total invested capital for the investor to 0
        position.investedCapital = 0;

        // Flag that the investor has refunded
        s_investorPositions[positionId].hasRefunded = true;

        // Decrement total capital invested from all investors
        s_capitalRaiseStatus.totalCapitalInvested -= amountToRefund;

        // Emit CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender, positionId);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_capitalRaiseConfig.bidToken, msg.sender, amountToRefund);
    }

    /// @inheritdoc ILegionCapitalRaise
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        // Emit EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /// @inheritdoc ILegionCapitalRaise
    function withdrawRaisedCapital()
        external
        onlyProject
        whenNotPaused
        whenRaiseNotCanceled
        whenRaiseHasEnded
        whenRefundPeriodIsOver
    {
        // Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        // Cache value in memory
        uint256 _totalCapitalRaised = s_capitalRaiseStatus.totalCapitalRaised;

        // Account for the capital withdrawn
        s_capitalRaiseStatus.totalCapitalWithdrawn = _totalCapitalRaised;

        // Cache the sale configuration
        CapitalRaiseConfig memory capitalRaiseConfig = s_capitalRaiseConfig;

        // Calculate Legion Fee
        uint256 legionFee =
            (capitalRaiseConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate Referrer Fee
        uint256 referrerFee = (capitalRaiseConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised)
            / Constants.BASIS_POINTS_DENOMINATOR;

        // Emit CapitalWithdrawn
        emit CapitalWithdrawn(_totalCapitalRaised);

        // Transfer the amount to the Project's address
        SafeTransferLib.safeTransfer(
            capitalRaiseConfig.bidToken, msg.sender, (_totalCapitalRaised - legionFee - referrerFee)
        );

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransfer(capitalRaiseConfig.bidToken, capitalRaiseConfig.legionFeeReceiver, legionFee);
        }

        // Transfer the Referrer fee to the Referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransfer(
                capitalRaiseConfig.bidToken, capitalRaiseConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /// @inheritdoc ILegionCapitalRaise
    function cancel() external onlyProject whenNotPaused whenRaiseNotCanceled {
        // Cache the amount of funds to be returned to the capital raise
        // The project should return the total capital raised including the charged fees
        uint256 capitalToReturn = s_capitalRaiseStatus.totalCapitalWithdrawn;

        // Mark the capital raise as canceled
        s_capitalRaiseStatus.isCanceled = true;

        // Emit CapitalRaiseCanceled
        emit CapitalRaiseCanceled();

        // In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            // Set the totalCapitalWithdrawn to zero
            s_capitalRaiseStatus.totalCapitalWithdrawn = 0;
            // Transfer the raised capital back to the contract
            SafeTransferLib.safeTransferFrom(s_capitalRaiseConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /// @inheritdoc ILegionCapitalRaise
    function withdrawInvestedCapitalIfCanceled() external whenNotPaused whenRaiseCanceled {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Cache the amount to refund in memory
        uint256 amountToClaim = s_investorPositions[positionId].investedCapital;

        // Revert in case there's nothing to claim
        if (amountToClaim == 0) revert Errors.LegionSale__InvalidWithdrawAmount(0);

        // Set the total invested capital for the investor to 0
        s_investorPositions[positionId].investedCapital = 0;

        // Decrement total capital invested from all investors
        s_capitalRaiseStatus.totalCapitalInvested -= amountToClaim;

        // Emit CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToClaim, msg.sender, positionId);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_capitalRaiseConfig.bidToken, msg.sender, amountToClaim);
    }

    /// @inheritdoc ILegionCapitalRaise
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata claimExcessSignature
    )
        external
        whenNotPaused
        whenRaiseNotCanceled
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the signature has not been used
        _verifySignatureNotUsed(claimExcessSignature);

        // Verify that the investor is eligible to get excess capital back
        _verifyCanClaimExcessCapital(positionId);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Decrement total capital invested from investors
        s_capitalRaiseStatus.totalCapitalInvested -= amount;

        // Decrement total investor capital for the investor
        position.investedCapital -= amount;

        // Mark that the excess capital has been returned
        position.hasClaimedExcess = true;

        // Mark the signature as used
        s_usedSignatures[msg.sender][claimExcessSignature] = true;

        // Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate);

        // Verify that the investor position is valid
        _verifyValidPosition(claimExcessSignature, positionId, CapitalRaiseAction.WITHDRAW_EXCESS_CAPITAL);

        // Emit ExcessCapitalWithdrawn
        emit ExcessCapitalWithdrawn(amount, msg.sender, positionId);

        // Transfer the excess capital to the investor
        if (amount > 0) SafeTransferLib.safeTransfer(s_capitalRaiseConfig.bidToken, msg.sender, amount);
    }

    /// @inheritdoc ILegionCapitalRaise
    function end() external onlyLegionOrProject whenNotPaused whenRaiseNotEnded whenRaiseNotCanceled {
        // Update the `hasEnded` status to true
        s_capitalRaiseStatus.hasEnded = true;

        // Set the `endTime` of the capital raise
        s_capitalRaiseStatus.endTime = uint64(block.timestamp);

        // Set the `refundEndTime` of the capital raise
        s_capitalRaiseStatus.refundEndTime = uint64(block.timestamp) + s_capitalRaiseConfig.refundPeriodSeconds;

        // Emit CapitalRaiseEnded
        emit CapitalRaiseEnded();
    }

    /// @inheritdoc ILegionCapitalRaise
    function publishRaisedCapital(uint256 capitalRaised)
        external
        onlyLegion
        whenNotPaused
        whenRaiseNotCanceled
        whenRaiseHasEnded
        whenRefundPeriodIsOver
    {
        // Verify that capital raised can be published.
        _verifyCanPublishCapitalRaised();

        // Set the total capital raised to be withdrawn by the project
        s_capitalRaiseStatus.totalCapitalRaised = capitalRaised;

        // Emit CapitalRaisedPublished
        emit CapitalRaisedPublished(capitalRaised);
    }

    /// @inheritdoc LegionPositionManager
    function transferInvestorPosition(
        address from,
        address to,
        uint256 positionId
    )
        external
        override
        onlyLegion
        whenNotPaused
        whenRaiseNotCanceled
        whenRaiseHasEnded
        whenRefundPeriodIsOver
    {
        // Verify that the position can be transferred
        _verifyCanTransferInvestorPosition(positionId);

        // Burn or transfer the investor position
        _burnOrTransferInvestorPosition(from, to, positionId);
    }

    /// @inheritdoc LegionPositionManager
    function transferInvestorPositionWithAuthorization(
        address from,
        address to,
        uint256 positionId,
        bytes calldata signature
    )
        external
        virtual
        override
        whenNotPaused
        whenRaiseNotCanceled
        whenRaiseHasEnded
        whenRefundPeriodIsOver
    {
        // Verify the signature for transferring the position
        _verifyTransferSignature(from, to, positionId, s_capitalRaiseConfig.legionSigner, signature);

        // Verify that the position can be transferred
        _verifyCanTransferInvestorPosition(positionId);

        // Burn or transfer the investor position
        _burnOrTransferInvestorPosition(from, to, positionId);
    }

    /// @inheritdoc ILegionCapitalRaise
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /// @inheritdoc ILegionCapitalRaise
    function pause() external virtual onlyLegion {
        // Pause the capital raise
        _pause();
    }

    /// @inheritdoc ILegionCapitalRaise
    function unpause() external virtual onlyLegion {
        // Unpause the capital raise
        _unpause();
    }

    /// @inheritdoc ILegionCapitalRaise
    function saleConfiguration() external view returns (CapitalRaiseConfig memory) {
        return s_capitalRaiseConfig;
    }

    /// @inheritdoc ILegionCapitalRaise
    function saleStatus() external view returns (CapitalRaiseStatus memory) {
        return s_capitalRaiseStatus;
    }

    /// @inheritdoc ILegionCapitalRaise
    function investorPosition(address investor) external view returns (InvestorPosition memory) {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investor);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        return s_investorPositions[positionId];
    }

    /// @dev Sets the capital raise parameters during initialization.
    /// @param _preLiquidSaleInitParams The initialization parameters.
    function _setLegionCapitalRaiseConfig(CapitalRaiseInitializationParams calldata _preLiquidSaleInitParams)
        private
        onlyInitializing
    {
        // Verify if the capital raise configuration is valid
        _verifyValidConfig(_preLiquidSaleInitParams);

        // Initialize the capital raise configuration
        s_capitalRaiseConfig.refundPeriodSeconds = _preLiquidSaleInitParams.refundPeriodSeconds;
        s_capitalRaiseConfig.legionFeeOnCapitalRaisedBps = _preLiquidSaleInitParams.legionFeeOnCapitalRaisedBps;
        s_capitalRaiseConfig.referrerFeeOnCapitalRaisedBps = _preLiquidSaleInitParams.referrerFeeOnCapitalRaisedBps;
        s_capitalRaiseConfig.bidToken = _preLiquidSaleInitParams.bidToken;
        s_capitalRaiseConfig.projectAdmin = _preLiquidSaleInitParams.projectAdmin;
        s_capitalRaiseConfig.addressRegistry = _preLiquidSaleInitParams.addressRegistry;
        s_capitalRaiseConfig.referrerFeeReceiver = _preLiquidSaleInitParams.referrerFeeReceiver;

        // Initialize pre-liquid sale soulbound token configuration
        s_positionManagerConfig.name = _preLiquidSaleInitParams.saleName;
        s_positionManagerConfig.symbol = _preLiquidSaleInitParams.saleSymbol;
        s_positionManagerConfig.baseURI = _preLiquidSaleInitParams.saleBaseURI;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /// @dev Synchronizes Legion addresses from the registry.
    function _syncLegionAddresses() private {
        // Cache Legion addresses from `LegionAddressRegistry`
        s_capitalRaiseConfig.legionBouncer =
            ILegionAddressRegistry(s_capitalRaiseConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        s_capitalRaiseConfig.legionSigner =
            ILegionAddressRegistry(s_capitalRaiseConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        s_capitalRaiseConfig.legionFeeReceiver = ILegionAddressRegistry(s_capitalRaiseConfig.addressRegistry)
            .getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);

        // Emit LegionAddressesSynced
        emit LegionAddressesSynced(
            s_capitalRaiseConfig.legionBouncer,
            s_capitalRaiseConfig.legionSigner,
            s_capitalRaiseConfig.legionFeeReceiver
        );
    }

    /// @dev Updates an investor's position with new investment and allocation data.
    /// @param _investAmount The maximum capital allowed to invest.
    /// @param _tokenAllocationRate The token allocation percentage (18 decimals precision).
    function _updateInvestorPosition(uint256 _investAmount, uint256 _tokenAllocationRate) private {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Cache the SAFT amount the investor is allowed to invest
        if (position.cachedInvestAmount != _investAmount) {
            position.cachedInvestAmount = _investAmount;
        }

        // Cache the token allocation rate in 18 decimals precision
        if (position.cachedTokenAllocationRate != _tokenAllocationRate) {
            position.cachedTokenAllocationRate = _tokenAllocationRate;
        }
    }

    /// @dev Burns or transfers an investor position based on receiver's existing position.
    /// @param _from The address of the current owner.
    /// @param _to The address of the new owner.
    /// @param _positionId The ID of the position to transfer or burn.
    function _burnOrTransferInvestorPosition(address _from, address _to, uint256 _positionId) private {
        // Get the position ID of the receiver
        uint256 positionIdTo = s_investorPositionIds[_to];

        // If the receiver already has a position, burn the transferred position
        // and update the existing position
        if (positionIdTo != 0) {
            // Load the investor positions
            InvestorPosition memory positionToBurn = s_investorPositions[_positionId];
            InvestorPosition storage positionToUpdate = s_investorPositions[positionIdTo];

            // Verify that the updated position is not settled or refunded
            if (positionToUpdate.hasRefunded || !positionToUpdate.hasClaimedExcess) {
                revert Errors.LegionSale__UnableToMergeInvestorPosition(positionIdTo);
            }

            // Update the existing position with the transferred values
            positionToUpdate.investedCapital += positionToBurn.investedCapital;
            positionToUpdate.cachedTokenAllocationRate += positionToBurn.cachedTokenAllocationRate;
            positionToUpdate.cachedInvestAmount += positionToBurn.cachedInvestAmount;

            // Delete the burned position
            delete s_investorPositions[_positionId];

            // Burn the investor position from the `from` address
            _burnInvestorPosition(_from);
        } else {
            // Transfer the investor position to the new address
            _transferInvestorPosition(_from, _to, _positionId);
        }
    }

    /// @dev Validates the capital raise configuration parameters.
    /// @param _preLiquidSaleInitParams The initialization parameters to validate.
    function _verifyValidConfig(CapitalRaiseInitializationParams calldata _preLiquidSaleInitParams) private pure {
        // Check for zero addresses provided
        if (
            _preLiquidSaleInitParams.bidToken == address(0) || _preLiquidSaleInitParams.projectAdmin == address(0)
                || _preLiquidSaleInitParams.addressRegistry == address(0)
        ) revert Errors.LegionSale__ZeroAddressProvided();

        // Check for zero values provided
        if (_preLiquidSaleInitParams.refundPeriodSeconds == 0) {
            revert Errors.LegionSale__ZeroValueProvided();
        }

        // Check if the refund period is within range
        if (_preLiquidSaleInitParams.refundPeriodSeconds > 2 weeks) revert Errors.LegionSale__InvalidPeriodConfig();
    }

    /// @dev Ensures the capital raise is not canceled.
    function _verifyCapitalRaisedNotCanceled() internal view {
        if (s_capitalRaiseStatus.isCanceled) revert Errors.LegionSale__SaleIsCanceled();
    }

    /// @dev Ensures the capital raise is canceled.
    function _verifyCapitalRaiseIsCanceled() internal view {
        if (!s_capitalRaiseStatus.isCanceled) revert Errors.LegionSale__SaleIsNotCanceled();
    }

    /// @dev Ensures the capital raise has not ended.
    function _verifyCapitalRaiseHasNotEnded() internal view {
        if (s_capitalRaiseStatus.hasEnded) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /// @dev Ensures the capital raise has ended.
    function _verifyCapitalRaiseHasEnded() internal view {
        if (!s_capitalRaiseStatus.hasEnded) revert Errors.LegionSale__SaleHasNotEnded(block.timestamp);
    }

    /// @dev Ensures a signature has not been used before.
    /// @param _signature The signature to verify.
    function _verifySignatureNotUsed(bytes calldata _signature) private view {
        // Check if the signature is used
        if (s_usedSignatures[msg.sender][_signature]) revert Errors.LegionSale__SignatureAlreadyUsed(_signature);
    }

    /// @dev Verifies conditions for withdrawing capital.
    function _verifyCanWithdrawCapital() internal view virtual {
        // Load the sale status
        CapitalRaiseStatus memory capitalRaiseStatus = s_capitalRaiseStatus;
        // Check if capital has not been withdrawn
        if (capitalRaiseStatus.totalCapitalWithdrawn > 0) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        // Check if capital raised has been published
        if (capitalRaiseStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalNotRaised();
    }

    /// @dev Ensures the refund period has ended.
    function _verifyRefundPeriodIsOver() internal view {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_capitalRaiseStatus.refundEndTime;
        if (refundEndTime > 0 && block.timestamp < refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Ensures the refund period is still active.
    function _verifyRefundPeriodIsNotOver() internal view {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_capitalRaiseStatus.refundEndTime;
        if (refundEndTime > 0 && block.timestamp >= refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Ensures the investor has not already refunded.
    /// @param _positionId The ID of the investor's position.

    function _verifyHasNotRefunded(uint256 _positionId) internal view virtual {
        if (s_investorPositions[_positionId].hasRefunded) revert Errors.LegionSale__InvestorHasRefunded(msg.sender);
    }

    /// @dev Verifies conditions for publishing capital raised.
    function _verifyCanPublishCapitalRaised() internal view {
        if (s_capitalRaiseStatus.totalCapitalRaised != 0) revert Errors.LegionSale__CapitalRaisedAlreadyPublished();
    }

    /// @dev Validates an investor's position using signature verification.
    /// @param _signature The signature to verify.
    /// @param _positionId The ID of the investor's position.
    /// @param _actionType The type of capital raise action being performed.
    function _verifyValidPosition(
        bytes calldata _signature,
        uint256 _positionId,
        CapitalRaiseAction _actionType
    )
        internal
        view
    {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Verify that the amount invested is equal to the SAFT amount
        if (position.investedCapital != position.cachedInvestAmount) {
            revert Errors.LegionSale__InvalidPositionAmount(msg.sender);
        }

        // Construct the signed data
        bytes32 _data = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                block.chainid,
                uint256(position.cachedInvestAmount),
                uint256(position.cachedTokenAllocationRate),
                _actionType
            )
        ).toEthSignedMessageHash();

        // Verify the signature
        if (_data.recover(_signature) != s_capitalRaiseConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_signature);
        }
    }

    /// @dev Verifies investor eligibility to claim excess capital.
    /// @param _positionId The position ID of the investor.
    function _verifyCanClaimExcessCapital(uint256 _positionId) internal view virtual {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Check if the investor has already claimed excess capital
        if (position.hasClaimedExcess) revert Errors.LegionSale__AlreadyClaimedExcess(msg.sender);
    }

    /// @dev Verifies conditions for transferring an investor position.
    /// @param _positionId The ID of the investor's position.
    function _verifyCanTransferInvestorPosition(uint256 _positionId) private view {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Verify that the position is not refunded
        if (position.hasRefunded || !position.hasClaimedExcess) {
            revert Errors.LegionSale__UnableToTransferInvestorPosition(_positionId);
        }
    }
}
