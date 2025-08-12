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
import { ILegionPreLiquidApprovedSale } from "../interfaces/sales/ILegionPreLiquidApprovedSale.sol";
import { ILegionVesting } from "../interfaces/vesting/ILegionVesting.sol";

import { LegionPositionManager } from "../position/LegionPositionManager.sol";
import { LegionVestingManager } from "../vesting/LegionVestingManager.sol";

/**
 * @title Legion Pre-Liquid Approved Sale
 * @author Legion
 * @notice Executes pre-liquid sales of ERC20 tokens before Token Generation Event (TGE).
 * @dev Manages pre-liquid sale lifecycle including investment, refunds, token supply, and vesting with signature-based
 * authorization.
 */
contract LegionPreLiquidApprovedSale is
    ILegionPreLiquidApprovedSale,
    LegionVestingManager,
    LegionPositionManager,
    Initializable,
    Pausable
{
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev Struct containing the pre-liquid sale configuration.
    PreLiquidSaleConfig private s_saleConfig;

    /// @dev Struct tracking the current sale status.
    PreLiquidSaleStatus private s_saleStatus;

    /// @dev Mapping of position IDs to their respective positions.
    mapping(uint256 s_positionId => InvestorPosition s_investorPosition) private s_investorPositions;

    /// @dev Mapping to track used signatures per investor.
    mapping(address s_investorAddress => mapping(bytes s_signature => bool s_used) s_usedSignature) private
        s_usedSignatures;

    /// @notice Restricts function access to the Legion bouncer only.
    /// @dev Reverts if the caller is not the configured Legion bouncer address.
    modifier onlyLegion() {
        if (msg.sender != s_saleConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /// @notice Restricts function access to the project admin only.
    /// @dev Reverts if the caller is not the configured project admin address.
    modifier onlyProject() {
        if (msg.sender != s_saleConfig.projectAdmin) revert Errors.LegionSale__NotCalledByProject();
        _;
    }

    /// @notice Restricts function access to either Legion bouncer or project admin.
    /// @dev Reverts if the caller is neither the project admin nor Legion bouncer.
    modifier onlyLegionOrProject() {
        if (msg.sender != s_saleConfig.projectAdmin && msg.sender != s_saleConfig.legionBouncer) {
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

    /// @notice Restricts interaction to when tokens have been supplied for distribution.
    /// @dev Reverts if tokens have not been supplied.
    modifier whenTokensSupplied() {
        // Verify that tokens have been supplied to the sale
        _verifyTokensSupplied();
        _;
    }

    /// @notice Restricts interaction to when tokens have not been supplied for distribution.
    /// @dev Reverts if tokens have been supplied.
    modifier whenTokensNotSupplied() {
        // Verify that no tokens have been supplied to the sale by the Project
        _verifyTokensNotSupplied();
        _;
    }

    /// @notice Restricts interaction to when the sale results have not been published.
    /// @dev Reverts if sale results have been published.
    modifier whenSaleResultsNotPublished() {
        // Verify that sale results have not been published
        _verifySaleResultsNotPublished();
        _;
    }

    /// @notice Constructor for the LegionPreLiquidApprovedSale contract.
    /// @dev Prevents the implementation contract from being initialized directly.
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external initializer {
        _setLegionSaleConfig(preLiquidSaleInitParams);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata investSignature
    )
        external
        whenNotPaused
        whenSaleNotCanceled
        whenSaleNotEnded
    {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the signature has not been used
        _verifySignatureNotUsed(investSignature);

        // Verify that the investor has not claimed excess capital
        _verifyCanClaimExcessCapital(positionId);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Increment total capital invested from investors
        s_saleStatus.totalCapitalInvested += amount;

        // Increment total capital for the investor
        position.investedCapital += amount;

        // Mark the signature as used
        s_usedSignatures[msg.sender][investSignature] = true;

        // Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate, positionId);

        // Verify that the investor position is valid
        _verifyValidPosition(investSignature, positionId, SaleAction.INVEST);

        // Emit CapitalInvested event
        emit CapitalInvested(amount, msg.sender, positionId);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_saleConfig.bidToken, msg.sender, address(this), amount);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function refund() external whenNotPaused whenSaleNotCanceled whenRefundPeriodNotOver {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Cache the amount to refund
        uint256 amountToRefund = position.investedCapital;

        // Set the total invested capital for the investor to 0
        position.investedCapital = 0;

        // Flag that the investor has refunded
        s_investorPositions[positionId].hasRefunded = true;

        // Decrement total capital invested from investors
        s_saleStatus.totalCapitalInvested -= amountToRefund;

        // Emit CapitalRefunded event
        emit CapitalRefunded(amountToRefund, msg.sender, positionId);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_saleConfig.bidToken, msg.sender, amountToRefund);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function publishTgeDetails(
        address askToken,
        uint256 askTokenTotalSupply,
        uint256 totalTokensAllocated
    )
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
    {
        // Set the address of the token distributed to investors
        s_saleStatus.askToken = askToken;

        // Set the total supply of the token distributed to investors
        s_saleStatus.askTokenTotalSupply = askTokenTotalSupply;

        // Set the total allocated amount of token for distribution.
        s_saleStatus.totalTokensAllocated = totalTokensAllocated;

        // Emit TgeDetailsPublished event
        emit TgeDetailsPublished(askToken, askTokenTotalSupply, totalTokensAllocated);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function supplyTokens(
        uint256 amount,
        uint256 legionFee,
        uint256 referrerFee
    )
        external
        onlyProject
        whenNotPaused
        whenSaleNotCanceled
        whenTokensNotSupplied
    {
        // Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        // Flag that ask tokens have been supplied
        s_saleStatus.tokensSupplied = true;

        // Cache Legion Sale Configuration
        PreLiquidSaleConfig memory saleConfig = s_saleConfig;

        // Calculate the expected Legion Fee amount
        uint256 expectedLegionFeeAmount =
            (s_saleConfig.legionFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate the expected Referrer Fee amount
        uint256 expectedReferrerFeeAmount =
            (s_saleConfig.referrerFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        // Verify Legion Fee amount
        if (legionFee != expectedLegionFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(legionFee, expectedLegionFeeAmount);
        }

        // Verify Referrer Fee amount
        if (referrerFee != expectedReferrerFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(referrerFee, expectedReferrerFeeAmount);
        }

        // Emit TokensSuppliedForDistribution event
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        // Cache the sale status
        PreLiquidSaleStatus memory _saleStatus = s_saleStatus;

        // Transfer the allocated amount of tokens for distribution
        SafeTransferLib.safeTransferFrom(_saleStatus.askToken, msg.sender, address(this), amount);

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(_saleStatus.askToken, msg.sender, saleConfig.legionFeeReceiver, legionFee);
        }

        // Transfer the Referrer fee to the referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                _saleStatus.askToken, msg.sender, saleConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        // Emit EmergencyWithdraw event
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function withdrawRaisedCapital()
        external
        onlyProject
        whenNotPaused
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
    {
        // Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        // Cache value in memory
        uint256 _totalCapitalRaised = s_saleStatus.totalCapitalRaised;

        // Account for the capital withdrawn
        s_saleStatus.totalCapitalWithdrawn = _totalCapitalRaised;

        // Cache the sale configuration
        PreLiquidSaleConfig memory saleConfig = s_saleConfig;

        // Calculate Legion Fee
        uint256 legionFee =
            (saleConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate Referrer Fee
        uint256 referrerFee =
            (saleConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Emit CapitalWithdrawn event
        emit CapitalWithdrawn(_totalCapitalRaised);

        // Transfer the amount to the Project's address
        SafeTransferLib.safeTransfer(saleConfig.bidToken, msg.sender, (_totalCapitalRaised - legionFee - referrerFee));

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransfer(saleConfig.bidToken, saleConfig.legionFeeReceiver, legionFee);
        }

        // Transfer the Referrer fee to the referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransfer(saleConfig.bidToken, saleConfig.referrerFeeReceiver, referrerFee);
        }
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function claimTokenAllocation(
        uint256 investAmount,
        uint256 tokenAllocationRate,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes calldata claimSignature,
        bytes calldata vestingSignature
    )
        external
        whenNotPaused
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
        whenTokensSupplied
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the vesting configuration is valid
        _verifyValidVestingConfig(investorVestingConfig);

        // Verify that the investor can claim the token allocation
        _verifyCanClaimTokenAllocation(positionId);

        // Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate, positionId);

        // Verify that the investor position is valid
        _verifyValidPosition(claimSignature, positionId, SaleAction.CLAIM_TOKEN_ALLOCATION);

        // Verify that the investor vesting terms are valid
        _verifyValidVestingPosition(vestingSignature, positionId, investorVestingConfig);

        // Verify that the signature has not been used
        _verifySignatureNotUsed(claimSignature);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Mark the signature as used
        s_usedSignatures[msg.sender][claimSignature] = true;

        // Mark that the token amount has been settled
        position.hasSettled = true;

        // Cache the sale status
        PreLiquidSaleStatus memory _saleStatus = s_saleStatus;

        // Calculate the total token amount to be claimed
        uint256 totalAmount = _saleStatus.askTokenTotalSupply * position.cachedTokenAllocationRate
            / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        // Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim =
            totalAmount * investorVestingConfig.tokenAllocationOnTGERate / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        // Calculate the remaining amount to be vested
        uint256 amountToBeVested = totalAmount - amountToDistributeOnClaim;

        // Emit TokenAllocationClaimed event
        emit TokenAllocationClaimed(amountToBeVested, amountToDistributeOnClaim, msg.sender, positionId);

        // Deploy vesting and distribute tokens only if there is anything to distribute
        if (amountToBeVested != 0) {
            // Deploy a vesting contract for the investor
            address payable vestingAddress = _createVesting(investorVestingConfig, _saleStatus.askToken);

            // Save the vesting address for the investor
            position.vestingAddress = vestingAddress;

            // Transfer the allocated amount of tokens for distribution to the vesting contract
            SafeTransferLib.safeTransfer(_saleStatus.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            // Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(_saleStatus.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function cancel() external onlyProject whenNotPaused whenSaleNotCanceled whenTokensNotSupplied {
        // Cache the amount of funds to be returned to the capital raise
        // The project should return the total capital raised including the charged fees
        uint256 capitalToReturn = s_saleStatus.totalCapitalWithdrawn;

        // Mark the sale as canceled
        s_saleStatus.isCanceled = true;

        // Emit SaleCanceled event
        emit SaleCanceled();

        // In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            // Set the totalCapitalWithdrawn to zero
            s_saleStatus.totalCapitalWithdrawn = 0;
            // Transfer the raised capital back to the contract
            SafeTransferLib.safeTransferFrom(s_saleConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function withdrawInvestedCapitalIfCanceled() external whenNotPaused whenSaleCanceled {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Cache the amount to refund in memory
        uint256 amountToWithdraw = s_investorPositions[positionId].investedCapital;

        // Revert in case there's nothing to claim
        if (amountToWithdraw == 0) revert Errors.LegionSale__InvalidWithdrawAmount(0);

        // Set the total invested capital for the investor to 0
        s_investorPositions[positionId].investedCapital = 0;

        // Decrement total capital invested from all investors
        s_saleStatus.totalCapitalInvested -= amountToWithdraw;

        // Emit CapitalRefundedAfterCancel event
        emit CapitalRefundedAfterCancel(amountToWithdraw, msg.sender, positionId);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_saleConfig.bidToken, msg.sender, amountToWithdraw);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata withdrawSignature
    )
        external
        whenNotPaused
        whenSaleNotCanceled
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the signature has not been used
        _verifySignatureNotUsed(withdrawSignature);

        // Verify that the investor is eligible to get excess capital back
        _verifyCanClaimExcessCapital(positionId);

        // Mark the signature as used
        s_usedSignatures[msg.sender][withdrawSignature] = true;

        // Mark that the excess capital has been returned
        s_investorPositions[positionId].hasClaimedExcess = true;

        // Decrement total capital invested from investors
        s_saleStatus.totalCapitalInvested -= amount;

        // Decrement total investor capital for the investor
        s_investorPositions[positionId].investedCapital -= amount;

        // Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate, positionId);

        // Verify that the investor position is valid
        _verifyValidPosition(withdrawSignature, positionId, SaleAction.WITHDRAW_EXCESS_CAPITAL);

        // Emit ExcessCapitalWithdrawn event
        emit ExcessCapitalWithdrawn(amount, msg.sender, positionId);

        // Transfer the excess capital to the investor
        if (amount > 0) SafeTransferLib.safeTransfer(s_saleConfig.bidToken, msg.sender, amount);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function releaseVestedTokens() external whenNotPaused {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Get the investor vesting address
        address investorVestingAddress = s_investorPositions[positionId].vestingAddress;

        // Revert in case there's no vesting for the investor
        if (investorVestingAddress == address(0)) revert Errors.LegionSale__ZeroAddressProvided();

        // Release tokens to the investor account
        ILegionVesting(investorVestingAddress).release(s_saleStatus.askToken);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function end() external onlyLegionOrProject whenNotPaused whenSaleNotCanceled whenSaleNotEnded {
        // Update the `hasEnded` status to true
        s_saleStatus.hasEnded = true;

        // Set the `endTime` of the sale
        s_saleStatus.endTime = uint64(block.timestamp);

        // Set the `refundEndTime` of the sale
        s_saleStatus.refundEndTime = uint64(block.timestamp) + s_saleConfig.refundPeriodSeconds;

        // Emit SaleEnded event
        emit SaleEnded();
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function publishRaisedCapital(uint256 capitalRaised)
        external
        onlyLegion
        whenNotPaused
        whenSaleEnded
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
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
        whenSaleResultsNotPublished
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
        bytes calldata transferSignature
    )
        external
        virtual
        override
        whenNotPaused
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
        whenSaleResultsNotPublished
    {
        // Verify the signature for transferring the position
        _verifyTransferSignature(from, to, positionId, s_saleConfig.legionSigner, transferSignature);

        // Verify that the position can be transferred
        _verifyCanTransferInvestorPosition(positionId);

        // Burn or transfer the investor position
        _burnOrTransferInvestorPosition(from, to, positionId);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function pause() external virtual onlyLegion {
        // Pause the sale
        _pause();
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function unpause() external virtual onlyLegion {
        // Unpause the sale
        _unpause();
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function saleConfiguration() external view returns (PreLiquidSaleConfig memory) {
        return s_saleConfig;
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function saleStatus() external view returns (PreLiquidSaleStatus memory) {
        return s_saleStatus;
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function investorPosition(address investor) external view returns (InvestorPosition memory) {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investor);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        return s_investorPositions[positionId];
    }

    /// @inheritdoc ILegionPreLiquidApprovedSale
    function investorVestingStatus(address investor)
        external
        view
        returns (LegionInvestorVestingStatus memory vestingStatus)
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investor);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Get the investor position details
        address investorVestingAddress = s_investorPositions[positionId].vestingAddress;

        // Get the ask token address
        address askTokenAddress = s_saleStatus.askToken;

        // Return the investor vesting status
        investorVestingAddress != address(0)
            ? vestingStatus = LegionInvestorVestingStatus(
                ILegionVesting(investorVestingAddress).start(),
                ILegionVesting(investorVestingAddress).end(),
                ILegionVesting(investorVestingAddress).cliffEndTimestamp(),
                ILegionVesting(investorVestingAddress).duration(),
                ILegionVesting(investorVestingAddress).released(askTokenAddress),
                ILegionVesting(investorVestingAddress).releasable(askTokenAddress),
                ILegionVesting(investorVestingAddress).vestedAmount(askTokenAddress, uint64(block.timestamp))
            )
            : vestingStatus;
    }

    /// @dev Sets the sale parameters during initialization.
    /// @param _preLiquidSaleInitParams The initialization parameters for the sale.
    function _setLegionSaleConfig(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams)
        private
        onlyInitializing
    {
        // Verify if the sale configuration is valid
        _verifyValidConfig(_preLiquidSaleInitParams);

        // Initialize pre-liquid sale configuration
        s_saleConfig.refundPeriodSeconds = _preLiquidSaleInitParams.refundPeriodSeconds;
        s_saleConfig.legionFeeOnCapitalRaisedBps = _preLiquidSaleInitParams.legionFeeOnCapitalRaisedBps;
        s_saleConfig.legionFeeOnTokensSoldBps = _preLiquidSaleInitParams.legionFeeOnTokensSoldBps;
        s_saleConfig.referrerFeeOnCapitalRaisedBps = _preLiquidSaleInitParams.referrerFeeOnCapitalRaisedBps;
        s_saleConfig.referrerFeeOnTokensSoldBps = _preLiquidSaleInitParams.referrerFeeOnTokensSoldBps;
        s_saleConfig.bidToken = _preLiquidSaleInitParams.bidToken;
        s_saleConfig.projectAdmin = _preLiquidSaleInitParams.projectAdmin;
        s_saleConfig.addressRegistry = _preLiquidSaleInitParams.addressRegistry;
        s_saleConfig.referrerFeeReceiver = _preLiquidSaleInitParams.referrerFeeReceiver;

        // Initialize pre-liquid sale soulbound token configuration
        s_positionManagerConfig.name = _preLiquidSaleInitParams.saleName;
        s_positionManagerConfig.symbol = _preLiquidSaleInitParams.saleSymbol;
        s_positionManagerConfig.baseURI = _preLiquidSaleInitParams.saleBaseURI;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /// @dev Synchronizes Legion addresses from the address registry.
    function _syncLegionAddresses() private {
        // Cache Legion addresses from `LegionAddressRegistry`
        s_saleConfig.legionBouncer =
            ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        s_saleConfig.legionSigner =
            ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        s_saleConfig.legionFeeReceiver =
            ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);
        s_vestingConfig.vestingFactory =
            ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_VESTING_FACTORY_ID);
        s_vestingConfig.vestingController = ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(
            Constants.LEGION_VESTING_CONTROLLER_ID
        );

        // Emit LegionAddressesSynced event
        emit LegionAddressesSynced(
            s_saleConfig.legionBouncer,
            s_saleConfig.legionSigner,
            s_saleConfig.legionFeeReceiver,
            s_vestingConfig.vestingFactory,
            s_vestingConfig.vestingController
        );
    }

    /// @dev Updates an investor's position with SAFT data.
    /// @param _investAmount The maximum capital allowed per SAFT.
    /// @param _tokenAllocationRate The token allocation percentage (18 decimals).
    /// @param _positionId The ID of the investor position.
    function _updateInvestorPosition(
        uint256 _investAmount,
        uint256 _tokenAllocationRate,
        uint256 _positionId
    )
        private
    {
        // Load the investor position
        InvestorPosition storage position = s_investorPositions[_positionId];

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
            if (positionToUpdate.hasRefunded || positionToUpdate.hasSettled || !positionToUpdate.hasClaimedExcess) {
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

    /// @dev Validates an investor's vesting position using signature verification.
    /// @param _vestingSignature The signature proving vesting terms.
    /// @param _positionId The position ID of the investor.
    /// @param _investorVestingConfig The vesting configuration to verify.
    function _verifyValidVestingPosition(
        bytes calldata _vestingSignature,
        uint256 _positionId,
        LegionVestingManager.LegionInvestorVestingConfig calldata _investorVestingConfig
    )
        private
        view
    {
        // Construct the signed data
        bytes32 _data = keccak256(
            abi.encode(msg.sender, address(this), block.chainid, _positionId, _investorVestingConfig)
        ).toEthSignedMessageHash();

        // Verify the signature
        if (_data.recover(_vestingSignature) != s_saleConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_vestingSignature);
        }
    }

    /// @dev Validates the sale configuration parameters.
    /// @param _preLiquidSaleInitParams The initialization parameters to validate.
    function _verifyValidConfig(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams) private pure {
        // Check for zero addresses provided
        if (
            _preLiquidSaleInitParams.bidToken == address(0) || _preLiquidSaleInitParams.projectAdmin == address(0)
                || _preLiquidSaleInitParams.addressRegistry == address(0)
        ) revert Errors.LegionSale__ZeroAddressProvided();

        // Check for zero values provided
        if (
            _preLiquidSaleInitParams.refundPeriodSeconds == 0 || bytes(_preLiquidSaleInitParams.saleName).length == 0
                || bytes(_preLiquidSaleInitParams.saleSymbol).length == 0
                || bytes(_preLiquidSaleInitParams.saleBaseURI).length == 0
        ) {
            revert Errors.LegionSale__ZeroValueProvided();
        }
        // Check if the refund period is within range
        if (_preLiquidSaleInitParams.refundPeriodSeconds > 2 weeks) revert Errors.LegionSale__InvalidPeriodConfig();
    }

    /// @dev Verifies conditions for supplying tokens.
    /// @param _amount The amount of tokens to supply.
    function _verifyCanSupplyTokens(uint256 _amount) private view {
        // Cache the total amount of tokens allocated for distribution
        uint256 totalTokensAllocated = s_saleStatus.totalTokensAllocated;

        // Revert if Legion has not set the total amount of tokens allocated for distribution
        if (totalTokensAllocated == 0) revert Errors.LegionSale__TokensNotAllocated();

        // Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != totalTokensAllocated) {
            revert Errors.LegionSale__InvalidTokenAmountSupplied(_amount, totalTokensAllocated);
        }
    }

    /// @dev Verifies that the sale is not canceled.
    function _verifySaleNotCanceled() private view {
        if (s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsCanceled();
    }

    /// @dev Verifies that the sale is canceled.
    function _verifySaleIsCanceled() private view {
        if (!s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsNotCanceled();
    }

    /// @dev Verifies that the sale has not ended.
    function _verifySaleHasNotEnded() private view {
        if (s_saleStatus.hasEnded) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /// @dev Verifies that the sale has ended.
    function _verifySaleHasEnded() private view {
        if (!s_saleStatus.hasEnded) revert Errors.LegionSale__SaleHasNotEnded(block.timestamp);
    }

    /// @dev Verifies conditions for claiming token allocation.
    /// @param _positionId The ID of the investor's position.
    function _verifyCanClaimTokenAllocation(uint256 _positionId) private view {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.LegionSale__AlreadySettled(msg.sender);
    }

    /// @dev Verifies that tokens have been supplied to the sale.
    function _verifyTokensSupplied() private view {
        if (!s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensNotSupplied();
    }

    /// @dev Verifies that no tokens have been supplied.
    function _verifyTokensNotSupplied() private view {
        if (s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensAlreadySupplied();
    }

    /// @dev Verifies that a signature has not been used before.
    /// @param _signature The signature to verify.
    function _verifySignatureNotUsed(bytes calldata _signature) private view {
        // Check if the signature is used
        if (s_usedSignatures[msg.sender][_signature]) revert Errors.LegionSale__SignatureAlreadyUsed(_signature);
    }

    /// @dev Verifies conditions for withdrawing capital.
    function _verifyCanWithdrawCapital() private view {
        // Load the sale status
        PreLiquidSaleStatus memory _saleStatus = s_saleStatus;

        // Check if capital has not been withdrawn
        if (_saleStatus.totalCapitalWithdrawn > 0) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        // Check if capital raised has been published
        if (_saleStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalNotRaised();
    }

    /// @dev Verifies that the refund period has ended.
    function _verifyRefundPeriodIsOver() private view {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleStatus.refundEndTime;

        if (refundEndTime > 0 && block.timestamp < refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies that the refund period is still active.
    function _verifyRefundPeriodIsNotOver() private view {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleStatus.refundEndTime;

        if (refundEndTime > 0 && block.timestamp >= refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies that sale results have not been published.
    function _verifySaleResultsNotPublished() internal view virtual {
        if (s_saleStatus.totalTokensAllocated != 0) revert Errors.LegionSale__SaleResultsAlreadyPublished();
    }

    /// @dev Verifies that the investor has not refunded.
    /// @param _positionId The ID of the investor's position.
    function _verifyHasNotRefunded(uint256 _positionId) private view {
        if (s_investorPositions[_positionId].hasRefunded) revert Errors.LegionSale__InvestorHasRefunded(msg.sender);
    }

    /// @dev Verifies conditions for publishing capital raised.
    function _verifyCanPublishCapitalRaised() private view {
        if (s_saleStatus.totalCapitalRaised != 0) revert Errors.LegionSale__CapitalRaisedAlreadyPublished();
    }

    /// @dev Validates an investor's position using signature verification.
    /// @param _signature The signature to verify.
    /// @param _positionId The ID of the investor's position.
    /// @param _actionType The type of sale action being performed.
    function _verifyValidPosition(
        bytes calldata _signature,
        uint256 _positionId,
        SaleAction _actionType
    )
        private
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
        if (_data.recover(_signature) != s_saleConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_signature);
        }
    }

    /// @dev Verifies investor eligibility to claim excess capital.
    /// @param _positionId The position ID of the investor.
    function _verifyCanClaimExcessCapital(uint256 _positionId) internal view virtual {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Check if the investor has already settled their allocation
        if (position.hasClaimedExcess) revert Errors.LegionSale__AlreadyClaimedExcess(msg.sender);
    }

    /// @dev Verifies conditions for transferring an investor position.
    /// @param _positionId The ID of the investor's position.
    function _verifyCanTransferInvestorPosition(uint256 _positionId) private view {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Verify that the position is not settled or refunded
        if (position.hasRefunded || position.hasSettled || !position.hasClaimedExcess) {
            revert Errors.LegionSale__UnableToTransferInvestorPosition(_positionId);
        }
    }
}
