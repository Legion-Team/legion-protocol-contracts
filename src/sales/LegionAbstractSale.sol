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
import { ERC20 } from "@solady/src/tokens/ERC20.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

/**
 * @title Legion Abstract Sale
 * @author Legion
 * @notice Provides core functionality for token sales in the Legion Protocol.
 * @dev Abstract base contract that implements common sale operations including investments, refunds, token
 * distribution, and position management using soulbound NFTs.
 */
abstract contract LegionAbstractSale is ILegionAbstractSale, Initializable, Pausable, ERC20 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev Struct containing the sale configuration
    LegionSaleConfiguration internal s_saleConfig;

    /// @dev Struct containing the sale addresses configuration
    LegionSaleAddressConfiguration internal s_addressConfig;

    /// @dev Struct tracking the current sale status
    LegionSaleStatus internal s_saleStatus;

    /// @dev Mapping of investor addresses to their respective positions
    mapping(address s_investorAddress => InvestorPosition s_investorPosition) internal s_investorPositions;

    /// Standard receive function to accept ETH payments for ops fees
    receive() external payable { }

    /// @notice Restricts function access to the Legion bouncer only.
    /// @dev Reverts if the caller is not the configured Legion bouncer.
    modifier onlyLegion() {
        if (msg.sender != s_addressConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /// @notice Restricts function access to the project admin only.
    /// @dev Reverts if the caller is not the configured project admin.
    modifier onlyProject() {
        if (msg.sender != s_addressConfig.projectAdmin) revert Errors.LegionSale__NotCalledByProject();
        _;
    }

    /// @notice Restricts function access to either Legion bouncer or project admin.
    /// @dev Reverts if the caller is neither project admin nor Legion bouncer.
    modifier onlyLegionOrProject() {
        if (msg.sender != s_addressConfig.projectAdmin && msg.sender != s_addressConfig.legionBouncer) {
            revert Errors.LegionSale__NotCalledByLegionOrProject();
        }
        _;
    }

    /// @notice Restricts interaction to when the sale is canceled.
    /// @dev Reverts if the sale is not canceled.
    modifier whenSaleCanceled() {
        // Verify that the sale is canceled
        _verifySaleIsCanceled();
        _;
    }

    /// @notice Restricts interaction to when the sale is not canceled.
    /// @dev Reverts if the sale is canceled.
    modifier whenSaleNotCanceled() {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();
        _;
    }

    /// @notice Restricts interaction to when the sale has ended.
    /// @dev Reverts if the sale has not ended.
    modifier whenSaleEnded() {
        // Verify that the sale has ended
        _verifySaleHasEnded();
        _;
    }

    /// @notice Restricts interaction to when the sale is not ended
    /// @dev Reverts if the sale has ended.
    modifier whenSaleNotEnded() {
        // Verify that the sale has not ended
        _verifySaleHasNotEnded();
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

    /// @notice Constructor for the LegionAbstractSale contract.
    /// @dev Prevents the implementation contract from being initialized directly.
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /// @inheritdoc ERC20
    function name() public pure override returns (string memory) {
        return "Legion Sale Receipt";
    }

    /// @inheritdoc ERC20
    function symbol() public pure override returns (string memory) {
        return "LGN-RECEIPT";
    }

    /// @inheritdoc ERC20
    function decimals() public view override returns (uint8) {
        return s_saleConfig.bidTokenDecimals;
    }

    /// @inheritdoc ILegionAbstractSale
    function refund() external virtual whenNotPaused whenRefundPeriodNotOver whenSaleNotCanceled {
        // Verify that the investor has not refunded
        _verifyHasNotRefunded(msg.sender);

        // Cache the amount to refund in memory
        uint256 amountToRefund = s_investorPositions[msg.sender].investedCapital;

        // Revert in case there's nothing to refund
        if (amountToRefund == 0) revert Errors.LegionSale__InvalidWithdrawAmount(0);

        // Set the total invested capital for the investor to 0
        s_investorPositions[msg.sender].investedCapital = 0;

        // Flag that the investor has refunded
        s_investorPositions[msg.sender].hasRefunded = true;

        // Decrement total capital invested from investors
        s_saleStatus.totalCapitalInvested -= amountToRefund;

        // Emit CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender);

        // Burn the sale receipt tokens from the investor
        _burn(msg.sender, amountToRefund);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_addressConfig.bidToken, msg.sender, amountToRefund);
    }

    /// @inheritdoc ILegionAbstractSale
    function withdrawRaisedCapital()
        external
        virtual
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

        // Emit CapitalWithdrawn
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

    /// @inheritdoc ILegionAbstractSale
    function withdrawExcessInvestedCapital(
        uint256 amount,
        bytes calldata signature
    )
        external
        virtual
        whenNotPaused
        whenSaleNotCanceled
    {
        // Verify that the investor has not refunded
        _verifyHasNotRefunded(msg.sender);

        // Verify that the investor is eligible to get excess capital back
        _verifyCanClaimExcessCapital(msg.sender, amount, signature);

        // Mark that the excess capital has been returned
        s_investorPositions[msg.sender].hasClaimedExcess = true;

        // Decrement the total invested capital for the investor
        s_investorPositions[msg.sender].investedCapital -= amount;

        // Decrement total capital invested from all investors
        s_saleStatus.totalCapitalInvested -= amount;

        // Emit ExcessCapitalWithdrawn
        emit ExcessCapitalWithdrawn(amount, msg.sender);

        // Burn the sale receipt tokens from the investor
        _burn(msg.sender, amount);

        // Transfer the excess capital back to the investor
        if (amount > 0) SafeTransferLib.safeTransfer(s_addressConfig.bidToken, msg.sender, amount);
    }

    /// @inheritdoc ILegionAbstractSale
    function withdrawInvestedCapitalIfCanceled() external virtual whenNotPaused whenSaleCanceled {
        // Verify that the investor has not refunded
        _verifyHasNotRefunded(msg.sender);

        // Cache the amount to refund in memory
        uint256 amountToWithdraw = s_investorPositions[msg.sender].investedCapital;

        // Revert in case there's nothing to claim
        if (amountToWithdraw == 0) revert Errors.LegionSale__InvalidWithdrawAmount(0);

        // Set the total invested capital for the investor to 0
        s_investorPositions[msg.sender].investedCapital = 0;

        // Decrement total capital invested from all investors
        s_saleStatus.totalCapitalInvested -= amountToWithdraw;

        // Emit CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToWithdraw, msg.sender);

        // Burn the sale receipt tokens from the investor
        _burn(msg.sender, amountToWithdraw);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_addressConfig.bidToken, msg.sender, amountToWithdraw);
    }

    /// @inheritdoc ILegionAbstractSale
    function emergencyWithdraw(address receiver, address token, uint256 amount) external virtual onlyLegion {
        // Emit EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /// @inheritdoc ILegionAbstractSale
    function syncLegionAddresses() external virtual onlyLegion {
        // Sync the Legion addresses
        _syncLegionAddresses();
    }

    /// @inheritdoc ILegionAbstractSale
    function pause() external virtual onlyLegion {
        // Pause the sale
        _pause();
    }

    /// @inheritdoc ILegionAbstractSale
    function unpause() external virtual onlyLegion {
        // Unpause the sale
        _unpause();
    }

    /// @notice Updates Legion's operations fee.
    /// @param newFee The new fee amount in wei.
    function updateLegionOpsFee(uint256 newFee) external virtual onlyLegion {
        // Cache the old fee
        uint256 oldFee = s_saleConfig.legionOpsFeeInWei;

        // Update the operations fee
        s_saleConfig.legionOpsFeeInWei = newFee;

        // Emit LegionOpsFeeUpdated
        emit LegionOpsFeeUpdated(oldFee, newFee);
    }

    /// @inheritdoc ILegionAbstractSale
    function saleConfiguration() external view virtual returns (LegionSaleConfiguration memory) {
        return s_saleConfig;
    }

    /// @inheritdoc ILegionAbstractSale
    function saleStatus() external view virtual returns (LegionSaleStatus memory) {
        return s_saleStatus;
    }

    /// @inheritdoc ILegionAbstractSale
    function investorPosition(address investor) external view virtual returns (InvestorPosition memory) {
        return s_investorPositions[investor];
    }

    /// @inheritdoc ILegionAbstractSale
    function cancel() public virtual onlyProject whenNotPaused whenSaleNotCanceled {
        // Cache the amount of funds to be returned to the capital raise
        // The project should return the total capital raised including the charged fees
        uint256 capitalToReturn = s_saleStatus.totalCapitalWithdrawn;

        // Mark sale as canceled
        s_saleStatus.isCanceled = true;

        // Emit SaleCanceled event
        emit SaleCanceled();

        // In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            // Set the totalCapitalWithdrawn to zero
            s_saleStatus.totalCapitalWithdrawn = 0;
            // Transfer the capital back to the contract
            SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /// @dev Verifies that the correct ops fee is sent and transfers it to the Legion fee receiver.
    function _handleOpsFee() internal virtual {
        uint256 requiredFee = s_saleConfig.legionOpsFeeInWei;
        if (requiredFee > 0) {
            if (msg.value != requiredFee) {
                revert Errors.LegionSale__InvalidOpsFee(msg.value, requiredFee);
            }
            // Transfer the ops fee to the Legion fee receiver
            SafeTransferLib.safeTransferETH(s_addressConfig.legionFeeReceiver, requiredFee);
        }
    }

    /// @notice Sets the sale parameters during initialization
    /// @dev Virtual function to configure sale
    /// @param _saleInitParams Calldata struct with initialization parameters
    function _setLegionSaleConfig(LegionSaleInitializationParams calldata _saleInitParams)
        internal
        virtual
        onlyInitializing
    {
        // Verify if the sale common configuration is valid
        _verifyValidInitParams(_saleInitParams);

        // Set the sale configuration
        s_saleConfig.legionFeeOnCapitalRaisedBps = _saleInitParams.legionFeeOnCapitalRaisedBps;
        s_saleConfig.referrerFeeOnCapitalRaisedBps = _saleInitParams.referrerFeeOnCapitalRaisedBps;
        s_saleConfig.minimumInvestAmount = _saleInitParams.minimumInvestAmount;
        s_saleConfig.legionOpsFeeInWei = _saleInitParams.legionOpsFeeInWei;
        s_saleConfig.bidTokenDecimals = _saleInitParams.bidTokenDecimals;

        // Set the address configuration
        s_addressConfig.bidToken = _saleInitParams.bidToken;
        s_addressConfig.projectAdmin = _saleInitParams.projectAdmin;
        s_addressConfig.addressRegistry = _saleInitParams.addressRegistry;
        s_addressConfig.referrerFeeReceiver = _saleInitParams.referrerFeeReceiver;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /// @dev Synchronizes Legion addresses from the address registry.
    function _syncLegionAddresses() internal virtual {
        // Cache Legion addresses from `LegionAddressRegistry`
        s_addressConfig.legionBouncer =
            ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        s_addressConfig.legionSigner =
            ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        s_addressConfig.legionFeeReceiver =
            ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);

        // Emit LegionAddressesSynced
        emit LegionAddressesSynced(
            s_addressConfig.legionBouncer, s_addressConfig.legionSigner, s_addressConfig.legionFeeReceiver
        );
    }

    /// @dev Verifies investor eligibility to claim excess capital using Merkle proof.
    /// @param _investor The address of the investor.
    /// @param _amount The amount of excess capital to claim.
    /// @param _signature The signature authorizing the withdrawal.
    function _verifyCanClaimExcessCapital(
        address _investor,
        uint256 _amount,
        bytes calldata _signature
    )
        internal
        view
        virtual
    {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_investor];

        // Check if the investor has already settled their allocation
        if (position.hasClaimedExcess) revert Errors.LegionSale__AlreadyClaimedExcess(_investor);

        // Construct the signed data
        bytes32 _data = keccak256(
            abi.encodePacked(_investor, address(this), block.chainid, _amount, SaleAction.WITHDRAW_EXCESS_CAPITAL)
        ).toEthSignedMessageHash();

        // Verify the signature
        if (_data.recover(_signature) != s_addressConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_signature);
        }
    }

    /// @dev Validates the sale initialization parameters.
    /// @param _saleInitParams The initialization parameters to validate.
    function _verifyValidInitParams(LegionSaleInitializationParams calldata _saleInitParams) internal view virtual {
        // Check for zero addresses provided
        if (
            _saleInitParams.bidToken == address(0) || _saleInitParams.projectAdmin == address(0)
                || _saleInitParams.addressRegistry == address(0)
        ) {
            revert Errors.LegionSale__ZeroAddressProvided();
        }

        // Check for zero values provided
        if (_saleInitParams.refundPeriodSeconds == 0) {
            revert Errors.LegionSale__ZeroValueProvided();
        }

        // Check if refund period is longer than allowed
        if (_saleInitParams.refundPeriodSeconds > 2 weeks) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }

        // Check if refund period is shorter than allowed
        if (_saleInitParams.refundPeriodSeconds < 1 hours) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }
    }

    /// @dev Verifies that the invested amount meets the minimum requirement.
    /// @param _amount The amount being invested.
    function _verifyMinimumInvestAmount(uint256 _amount) internal view virtual {
        if (_amount < s_saleConfig.minimumInvestAmount) revert Errors.LegionSale__InvalidInvestAmount(_amount);
    }

    /// @dev Verifies that the sale has ended.
    function _verifySaleHasEnded() internal view virtual {
        if (!s_saleStatus.hasEnded) revert Errors.LegionSale__SaleHasNotEnded(block.timestamp);
    }

    /// @dev Verifies that the sale has not ended.
    function _verifySaleHasNotEnded() internal view virtual {
        if (s_saleStatus.hasEnded) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /// @dev Verifies that the refund period has ended.
    function _verifyRefundPeriodIsOver() internal view virtual {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleConfig.refundEndTime;

        if (refundEndTime > 0 && block.timestamp < refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies that the refund period is still active.
    function _verifyRefundPeriodIsNotOver() internal view virtual {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleConfig.refundEndTime;

        if (refundEndTime > 0 && block.timestamp >= refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies that the sale is not canceled.
    function _verifySaleNotCanceled() internal view virtual {
        if (s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsCanceled();
    }

    /// @dev Verifies that the sale is canceled.
    function _verifySaleIsCanceled() internal view virtual {
        if (!s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsNotCanceled();
    }

    /// @dev Verifies that an investment signature is valid.
    /// @param _signature The signature to verify.
    function _verifyInvestSignature(
        bytes calldata _signature,
        uint256 amount,
        uint256 deadline
    )
        internal
        view
        virtual
    {
        bytes32 _data = keccak256(
            abi.encodePacked(msg.sender, address(this), block.chainid, amount, deadline, SaleAction.INVEST)
        ).toEthSignedMessageHash();

        if (_data.recover(_signature) != s_addressConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_signature);
        }

        if (block.timestamp > deadline) {
            revert Errors.LegionSale__SignatureExpired(block.timestamp, deadline);
        }
    }

    /// @dev Verifies conditions for withdrawing capital.
    function _verifyCanWithdrawCapital() internal view virtual {
        // Load the sale status
        LegionSaleStatus memory _saleStatus = s_saleStatus;

        if (_saleStatus.capitalWithdrawn) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        if (_saleStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalRaisedNotPublished();
    }

    /// @dev Verifies that the investor has not refunded.
    /// @param _investor The address of the investor.
    function _verifyHasNotRefunded(address _investor) internal view virtual {
        if (s_investorPositions[_investor].hasRefunded) revert Errors.LegionSale__InvestorHasRefunded(msg.sender);
    }

    /// @dev Verifies that the investor has not claimed excess capital.
    /// @param _investor The address of the investor.
    function _verifyHasNotClaimedExcess(address _investor) internal view virtual {
        if (s_investorPositions[_investor].hasClaimedExcess) {
            revert Errors.LegionSale__InvestorHasClaimedExcess(msg.sender);
        }
    }
}
