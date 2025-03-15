// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

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
//
// If you find a bug, please contact security[at]legion.cc
// We will pay a fair bounty for any issue that puts users' funds at risk.

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MerkleProofLib } from "@solady/src/utils/MerkleProofLib.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionPreLiquidSaleV1 } from "../interfaces/sales/ILegionPreLiquidSaleV1.sol";
import { ILegionVesting } from "../interfaces/vesting/ILegionVesting.sol";
import { ILegionVestingFactory } from "../interfaces/factories/ILegionVestingFactory.sol";

import { LegionVestingManager } from "../vesting/LegionVestingManager.sol";

/**
 * @title Legion Pre-Liquid Sale V1
 * @author Legion
 * @notice A contract used to execute pre-liquid sales of ERC20 tokens before TGE
 * @dev Manages pre-liquid sale lifecycle including investment, refunds, token supply, and vesting; inherits from
 * multiple contracts
 */
contract LegionPreLiquidSaleV1 is ILegionPreLiquidSaleV1, LegionVestingManager, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the pre-liquid sale configuration
    /// @dev Stores internal sale parameters and settings
    PreLiquidSaleConfig internal saleConfig;

    /// @notice Struct tracking the current sale status
    /// @dev Maintains runtime state of the sale
    PreLiquidSaleStatus internal saleStatus;

    /// @notice Mapping of investor addresses to their positions
    /// @dev Publicly accessible investor data
    mapping(address investorAddress => InvestorPosition investorPosition) public investorPositions;

    /// @notice Mapping to track used signatures per investor to prevent replay attacks
    /// @dev Nested mapping for signature usage status
    mapping(address investorAddress => mapping(bytes signature => bool used) usedSignature) usedSignatures;

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to the Legion address only
     * @dev Reverts if caller is not the configured Legion bouncer address
     */
    modifier onlyLegion() {
        if (msg.sender != saleConfig.legionBouncer) revert Errors.NotCalledByLegion();
        _;
    }

    /**
     * @notice Restricts function access to the Project admin only
     * @dev Reverts if caller is not the configured project admin address
     */
    modifier onlyProject() {
        if (msg.sender != saleConfig.projectAdmin) revert Errors.NotCalledByProject();
        _;
    }

    /**
     * @notice Restricts function access to either Legion or Project admin
     * @dev Reverts if caller is neither the project admin nor Legion bouncer
     */
    modifier onlyLegionOrProject() {
        if (msg.sender != saleConfig.projectAdmin && msg.sender != saleConfig.legionBouncer) {
            revert Errors.NotCalledByLegionOrProject();
        }
        _;
    }

    /**
     * @notice Ensures the ask token is available before execution
     * @dev Reverts if askToken address is not set
     */
    modifier askTokenAvailable() {
        if (saleStatus.askToken == address(0)) revert Errors.AskTokenUnavailable();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for LegionPreLiquidSaleV1
     * @dev Disables initializers to prevent uninitialized deployment
     */
    constructor() {
        /// Disable initialization
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the pre-liquid sale contract with parameters
     * @dev Sets up sale configuration; callable only once during initialization
     * @param preLiquidSaleInitParams Calldata struct with pre-liquid sale initialization parameters
     */
    function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external initializer {
        _setLegionSaleConfig(preLiquidSaleInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows an investor to contribute capital to the pre-liquid sale
     * @dev Verifies conditions and updates state; uses SafeTransferLib for token transfer
     * @param amount Amount of capital (in bid tokens) to invest
     * @param investAmount Maximum capital allowed per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investSignature Signature verifying investor eligibility
     */
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes memory investSignature
    )
        external
        whenNotPaused
    {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(investSignature);

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Increment total capital invested from investors
        saleStatus.totalCapitalInvested += amount;

        /// Increment total capital for the investor
        position.investedCapital += amount;

        /// Mark the signature as used
        usedSignatures[msg.sender][investSignature] = true;

        /// Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate);

        /// Verify that the investor position is valid
        _verifyValidPosition(investSignature, SaleAction.INVEST);

        /// Emit successfully CapitalInvested
        emit CapitalInvested(amount, msg.sender, tokenAllocationRate, block.timestamp);

        /// Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(saleConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Processes a refund for an investor during the refund period
     * @dev Transfers invested capital back to the investor if conditions are met
     */
    function refund() external whenNotPaused {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the investor can get a refund
        _verifyRefundPeriodIsNotOver();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Cache the amount to refund in memory
        uint256 amountToRefund = position.investedCapital;

        /// Revert in case there's nothing to refund
        if (amountToRefund == 0) revert Errors.InvalidRefundAmount();

        /// Set the total invested capital for the investor to 0
        position.investedCapital = 0;

        // Flag that the investor has refunded
        investorPositions[msg.sender].hasRefunded = true;

        /// Decrement total capital invested from investors
        saleStatus.totalCapitalInvested -= amountToRefund;

        /// Emit successfully CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender);

        /// Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(saleConfig.bidToken, msg.sender, amountToRefund);
    }

    /**
     * @notice Publishes token details post-TGE
     * @dev Sets token-related data; restricted to Legion
     * @param _askToken Address of the token to be distributed
     * @param _askTokenTotalSupply Total supply of the ask token
     * @param _totalTokensAllocated Total tokens allocated for investors
     */
    function publishTgeDetails(
        address _askToken,
        uint256 _askTokenTotalSupply,
        uint256 _totalTokensAllocated
    )
        external
        onlyLegion
        whenNotPaused
    {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that the sale has ended
        _verifySaleHasEnded();

        /// Veriify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Set the address of the token distributed to investors
        saleStatus.askToken = _askToken;

        /// Set the total supply of the token distributed to investors
        saleStatus.askTokenTotalSupply = _askTokenTotalSupply;

        /// Set the total allocated amount of token for distribution.
        saleStatus.totalTokensAllocated = _totalTokensAllocated;

        /// Emit successfully TgeDetailsPublished
        emit TgeDetailsPublished(_askToken, _askTokenTotalSupply, _totalTokensAllocated);
    }

    /**
     * @notice Supplies tokens for distribution post-TGE
     * @dev Transfers tokens and fees; restricted to Project
     * @param amount Amount of tokens to supply
     * @param legionFee Fee amount for Legion
     * @param referrerFee Fee amount for referrer
     */
    function supplyTokens(
        uint256 amount,
        uint256 legionFee,
        uint256 referrerFee
    )
        external
        onlyProject
        whenNotPaused
        askTokenAvailable
    {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        /// Calculate and verify Legion Fee
        if (legionFee != (saleConfig.legionFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR) {
            revert Errors.InvalidFeeAmount();
        }

        /// Calculate and verify Referrer Fee
        if (referrerFee != (saleConfig.referrerFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR) {
            revert Errors.InvalidFeeAmount();
        }

        /// Flag that ask tokens have been supplied
        saleStatus.askTokensSupplied = true;

        /// Emit successfully TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        /// Transfer the allocated amount of tokens for distribution
        SafeTransferLib.safeTransferFrom(saleStatus.askToken, msg.sender, address(this), amount);

        /// Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(saleStatus.askToken, msg.sender, saleConfig.legionFeeReceiver, legionFee);
        }

        /// Transfer the Referrer fee to the Referer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                saleStatus.askToken, msg.sender, saleConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /**
     * @notice Withdraws tokens in emergency situations
     * @dev Restricted to Legion; used for safety measures
     * @param receiver Address to receive withdrawn tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        /// Emit successfully EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        /// Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /**
     * @notice Withdraws raised capital to the Project
     * @dev Transfers capital and fees; restricted to Project
     */
    function withdrawRaisedCapital() external onlyProject whenNotPaused {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        /// Account for the capital withdrawn
        saleStatus.totalCapitalWithdrawn = saleStatus.totalCapitalRaised;

        /// Calculate Legion Fee
        uint256 legionFee = (saleConfig.legionFeeOnCapitalRaisedBps * saleStatus.totalCapitalWithdrawn)
            / Constants.BASIS_POINTS_DENOMINATOR;

        /// Calculate Referrer Fee
        uint256 referrerFee = (saleConfig.referrerFeeOnCapitalRaisedBps * saleStatus.totalCapitalWithdrawn)
            / Constants.BASIS_POINTS_DENOMINATOR;

        /// Emit successfully CapitalWithdrawn
        emit CapitalWithdrawn(saleStatus.totalCapitalWithdrawn);

        /// Transfer the amount to the Project's address
        SafeTransferLib.safeTransfer(
            saleConfig.bidToken, msg.sender, (saleStatus.totalCapitalWithdrawn - legionFee - referrerFee)
        );

        /// Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) SafeTransferLib.safeTransfer(saleConfig.bidToken, saleConfig.legionFeeReceiver, legionFee);

        /// Transfer the Referrer fee to the Referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransfer(saleConfig.bidToken, saleConfig.referrerFeeReceiver, referrerFee);
        }
    }

    /**
     * @notice Allows investors to claim their token allocation
     * @dev Handles vesting and immediate distribution; requires signatures
     * @param investAmount Maximum capital allowed per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investorVestingConfig Vesting configuration for the investor
     * @param investSignature Signature verifying investment eligibility
     * @param vestingSignature Signature verifying vesting terms
     */
    function claimTokenAllocation(
        uint256 investAmount,
        uint256 tokenAllocationRate,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes memory investSignature,
        bytes memory vestingSignature
    )
        external
        whenNotPaused
        askTokenAvailable
    {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        // Verify that the vesting configuration is valid
        _verifyValidLinearVestingConfig(investorVestingConfig);

        /// Verify that the investor can claim the token allocation
        _verifyCanClaimTokenAllocation();

        /// Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate);

        /// Verify that the investor position is valid
        _verifyValidPosition(investSignature, SaleAction.CLAIM_TOKEN_ALLOCATION);

        /// Verify that the investor vesting terms are valid
        _verifyValidVestingPosition(vestingSignature, investorVestingConfig);

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(investSignature);

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Mark the signature as used
        usedSignatures[msg.sender][investSignature] = true;

        /// Mark that the token amount has been settled
        position.hasSettled = true;

        /// Calculate the total token amount to be claimed
        uint256 totalAmount = saleStatus.askTokenTotalSupply * position.cachedTokenAllocationRate
            / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        /// Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim =
            totalAmount * investorVestingConfig.tokenAllocationOnTGERate / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        /// Calculate the remaining amount to be vested
        uint256 amountToBeVested = totalAmount - amountToDistributeOnClaim;

        /// Emit successfully TokenAllocationClaimed
        emit TokenAllocationClaimed(amountToBeVested, amountToDistributeOnClaim, msg.sender);

        // Deploy vesting and distribute tokens only if there is anything to distribute
        if (amountToBeVested != 0) {
            /// Deploy a vesting schedule contract
            address payable vestingAddress = _createVesting(investorVestingConfig);

            /// Save the vesting address for the investor
            position.vestingAddress = vestingAddress;

            /// Transfer the allocated amount of tokens for distribution
            SafeTransferLib.safeTransfer(saleStatus.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            /// Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(saleStatus.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /**
     * @notice Cancels the sale and handles capital return
     * @dev Restricted to Project; reverts if tokens supplied
     */
    function cancelSale() external onlyProject whenNotPaused {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that no tokens have been supplied to the sale by the Project
        _verifyAskTokensNotSupplied();

        /// Cache the amount of funds to be returned to the sale
        uint256 capitalToReturn = saleStatus.totalCapitalWithdrawn;

        /// Mark the sale as canceled
        saleStatus.isCanceled = true;

        /// Emit successfully CapitalWithdrawn
        emit SaleCanceled();

        /// In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            /// Set the totalCapitalWithdrawn to zero
            saleStatus.totalCapitalWithdrawn = 0;
            /// Transfer the allocated amount of tokens for distribution
            SafeTransferLib.safeTransferFrom(saleConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /**
     * @notice Allows investors to withdraw capital if sale is canceled
     * @dev Transfers invested capital back to investor
     */
    function withdrawInvestedCapitalIfCanceled() external whenNotPaused {
        /// Verify that the sale has been actually canceled
        _verifySaleIsCanceled();

        /// Cache the amount to refund in memory
        uint256 amountToClaim = investorPositions[msg.sender].investedCapital;

        /// Revert in case there's nothing to claim
        if (amountToClaim == 0) revert Errors.NothingToClaim();

        /// Set the total pledged capital for the investor to 0
        investorPositions[msg.sender].investedCapital = 0;

        /// Decrement total capital pledged from investors
        saleStatus.totalCapitalInvested -= amountToClaim;

        /// Emit successfully CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToClaim, msg.sender);

        /// Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(saleConfig.bidToken, msg.sender, amountToClaim);
    }

    /**
     * @notice Withdraws excess invested capital back to investors
     * @dev Updates position and transfers excess; requires signature
     * @param amount Amount of excess capital to withdraw
     * @param investAmount Maximum capital allowed per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investSignature Signature verifying eligibility
     */
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes memory investSignature
    )
        external
        whenNotPaused
    {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(investSignature);

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Decrement total capital invested from investors
        saleStatus.totalCapitalInvested -= amount;

        /// Decrement total investor capital for the investor
        position.investedCapital -= amount;

        /// Mark the signature as used
        usedSignatures[msg.sender][investSignature] = true;

        /// Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate);

        /// Verify that the investor position is valid
        _verifyValidPosition(investSignature, SaleAction.WITHDRAW_EXCESS_CAPITAL);

        /// Emit successfully ExcessCapitalWithdrawn
        emit ExcessCapitalWithdrawn(amount, msg.sender, tokenAllocationRate, block.timestamp);

        /// Transfer the excess capital to the investor
        SafeTransferLib.safeTransfer(saleConfig.bidToken, msg.sender, amount);
    }

    /**
     * @notice Releases vested tokens to the investor
     * @dev Calls vesting contract to release tokens
     */
    function releaseVestedTokens() external whenNotPaused askTokenAvailable {
        /// Get the investor position details
        InvestorPosition memory position = investorPositions[msg.sender];

        /// Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert Errors.ZeroAddressProvided();

        /// Release tokens to the investor account
        ILegionVesting(position.vestingAddress).release(saleStatus.askToken);
    }

    /**
     * @notice Ends the sale manually
     * @dev Sets end times; restricted to Legion or Project
     */
    function endSale() external onlyLegionOrProject whenNotPaused {
        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        // Update the `hasEnded` status to false
        saleStatus.hasEnded = true;

        // Set the `endTime` of the sale
        saleStatus.endTime = block.timestamp;

        // Set the `refundEndTime` of the sale
        saleStatus.refundEndTime = block.timestamp + saleConfig.refundPeriodSeconds;

        /// Emit successfully SaleEnded
        emit SaleEnded(block.timestamp);
    }

    /**
     * @notice Publishes the total capital raised
     * @dev Sets capital raised; restricted to Legion
     * @param capitalRaised Total capital raised by the project
     */
    function publishCapitalRaised(uint256 capitalRaised) external onlyLegion whenNotPaused {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that capital raised can be published.
        _verifyCanPublishCapitalRaised();

        // Set the total capital raised to be withdrawn by the project
        saleStatus.totalCapitalRaised = capitalRaised;

        // Emit successfully CapitalRaisedPublished
        emit CapitalRaisedPublished(capitalRaised);
    }

    /**
     * @notice Syncs Legion addresses from the address registry
     * @dev Updates configuration with latest addresses; restricted to Legion
     */
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /**
     * @notice Pauses the sale
     * @dev Triggers Pausable pause; restricted to Legion
     */
    function pauseSale() external virtual onlyLegion {
        // Pause the sale
        _pause();
    }

    /**
     * @notice Unpauses the sale
     * @dev Triggers Pausable unpause; restricted to Legion
     */
    function unpauseSale() external virtual onlyLegion {
        // Unpause the sale
        _unpause();
    }

    /**
     * @notice Returns the current sale configuration
     * @dev Provides read-only access to saleConfig
     * @return PreLiquidSaleConfig memory Struct containing sale configuration
     */
    function saleConfiguration() external view returns (PreLiquidSaleConfig memory) {
        /// Get the pre-liquid sale config
        return saleConfig;
    }

    /**
     * @notice Returns the current sale status
     * @dev Provides read-only access to saleStatus
     * @return PreLiquidSaleStatus memory Struct containing sale status
     */
    function saleStatusDetails() external view returns (PreLiquidSaleStatus memory) {
        /// Get the pre-liquid sale status
        return saleStatus;
    }

    /**
     * @notice Returns an investor's position details
     * @dev Provides read-only access to investor position
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory) {
        return investorPositions[investorAddress];
    }

    /**
     * @notice Returns an investor's vesting status
     * @dev Queries vesting contract if applicable
     * @param investor Address of the investor
     * @return vestingStatus LegionInvestorVestingStatus memory Struct containing vesting status details
     */
    function investorVestingStatus(address investor)
        external
        view
        returns (LegionInvestorVestingStatus memory vestingStatus)
    {
        /// Get the investor position details
        address investorVestingAddress = investorPositions[investor].vestingAddress;

        // Return the investor vesting status
        investorVestingAddress != address(0)
            ? vestingStatus = LegionInvestorVestingStatus(
                ILegionVesting(investorVestingAddress).start(),
                ILegionVesting(investorVestingAddress).end(),
                ILegionVesting(investorVestingAddress).cliffEndTimestamp(),
                ILegionVesting(investorVestingAddress).duration(),
                ILegionVesting(investorVestingAddress).released(saleStatus.askToken),
                ILegionVesting(investorVestingAddress).releasable(saleStatus.askToken),
                ILegionVesting(investorVestingAddress).vestedAmount(saleStatus.askToken, uint64(block.timestamp))
            )
            : vestingStatus;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the sale parameters during initialization
     * @dev Internal function to configure sale; virtual for overrides
     * @param preLiquidSaleInitParams Calldata struct with initialization parameters
     */
    function _setLegionSaleConfig(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams)
        private
        onlyInitializing
    {
        /// Verify if the sale configuration is valid
        _verifyValidConfig(preLiquidSaleInitParams);

        /// Initialize pre-liquid sale configuration
        saleConfig.refundPeriodSeconds = preLiquidSaleInitParams.refundPeriodSeconds;
        saleConfig.legionFeeOnCapitalRaisedBps = preLiquidSaleInitParams.legionFeeOnCapitalRaisedBps;
        saleConfig.legionFeeOnTokensSoldBps = preLiquidSaleInitParams.legionFeeOnTokensSoldBps;
        saleConfig.referrerFeeOnCapitalRaisedBps = preLiquidSaleInitParams.referrerFeeOnCapitalRaisedBps;
        saleConfig.referrerFeeOnTokensSoldBps = preLiquidSaleInitParams.referrerFeeOnTokensSoldBps;
        saleConfig.bidToken = preLiquidSaleInitParams.bidToken;
        saleConfig.projectAdmin = preLiquidSaleInitParams.projectAdmin;
        saleConfig.addressRegistry = preLiquidSaleInitParams.addressRegistry;
        saleConfig.referrerFeeReceiver = preLiquidSaleInitParams.referrerFeeReceiver;

        /// Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /**
     * @notice Syncs Legion addresses from the registry
     * @dev Updates configuration with latest addresses; virtual for overrides
     */
    function _syncLegionAddresses() private {
        // Cache Legion addresses from `LegionAddressRegistry`
        saleConfig.legionBouncer =
            ILegionAddressRegistry(saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        saleConfig.legionSigner =
            ILegionAddressRegistry(saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        saleConfig.legionFeeReceiver =
            ILegionAddressRegistry(saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);
        vestingConfig.vestingFactory =
            ILegionAddressRegistry(saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_VESTING_FACTORY_ID);

        // Emit successfully LegionAddressesSynced
        emit LegionAddressesSynced(
            saleConfig.legionBouncer,
            saleConfig.legionSigner,
            saleConfig.legionFeeReceiver,
            vestingConfig.vestingFactory
        );
    }

    /**
     * @notice Updates an investor's position with SAFT data
     * @dev Caches investment and allocation details; virtual for overrides
     * @param investAmount Maximum capital allowed per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     */
    function _updateInvestorPosition(uint256 investAmount, uint256 tokenAllocationRate) private {
        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Cache the SAFT amount the investor is allowed to invest
        if (position.cachedInvestAmount != investAmount) {
            position.cachedInvestAmount = investAmount;
        }

        /// Cache the token allocation rate in 18 decimals precision
        if (position.cachedTokenAllocationRate != tokenAllocationRate) {
            position.cachedTokenAllocationRate = tokenAllocationRate;
        }
    }

    /**
     * @notice Validates an investor's vesting position
     * @dev Verifies vesting signature and configuration
     * @param vestingSignature Signature proving vesting terms
     * @param investorVestingConfig Vesting configuration to verify
     */
    function _verifyValidVestingPosition(
        bytes memory vestingSignature,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig
    )
        private
        view
    {
        /// Construct the signed data
        bytes32 _data = keccak256(abi.encode(msg.sender, address(this), block.chainid, investorVestingConfig))
            .toEthSignedMessageHash();

        /// Verify the signature
        if (_data.recover(vestingSignature) != saleConfig.legionSigner) {
            revert Errors.InvalidSignature(vestingSignature);
        }
    }

    /**
     * @notice Validates the sale configuration parameters
     * @dev Checks for invalid values and addresses
     * @param _preLiquidSaleInitParams Calldata struct with initialization parameters
     */
    function _verifyValidConfig(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams) private pure {
        /// Check for zero addresses provided
        if (
            _preLiquidSaleInitParams.bidToken == address(0) || _preLiquidSaleInitParams.projectAdmin == address(0)
                || _preLiquidSaleInitParams.addressRegistry == address(0)
        ) revert Errors.ZeroAddressProvided();

        /// Check for zero values provided
        if (_preLiquidSaleInitParams.refundPeriodSeconds == 0) {
            revert Errors.ZeroValueProvided();
        }

        /// Check if the refund period is within range
        if (_preLiquidSaleInitParams.refundPeriodSeconds > 2 weeks) revert Errors.InvalidPeriodConfig();
    }

    /**
     * @notice Verifies conditions for supplying tokens
     * @dev Ensures allocation and supply state are valid
     * @param _amount Amount of tokens to supply
     */
    function _verifyCanSupplyTokens(uint256 _amount) private view {
        /// Revert if Legion has not set the total amount of tokens allocated for distribution
        if (saleStatus.totalTokensAllocated == 0) revert Errors.TokensNotAllocated();

        /// Revert if tokens have already been supplied
        if (saleStatus.askTokensSupplied) revert Errors.TokensAlreadySupplied();

        /// Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != saleStatus.totalTokensAllocated) revert Errors.InvalidTokenAmountSupplied(_amount);
    }

    /**
     * @notice Ensures the sale is not canceled
     * @dev Reverts if sale is marked as canceled
     */
    function _verifySaleNotCanceled() internal view {
        if (saleStatus.isCanceled) revert Errors.SaleIsCanceled();
    }

    /**
     * @notice Ensures the sale is canceled
     * @dev Reverts if sale is not marked as canceled
     */
    function _verifySaleIsCanceled() internal view {
        if (!saleStatus.isCanceled) revert Errors.SaleIsNotCanceled();
    }

    /**
     * @notice Ensures the sale has not ended
     * @dev Reverts if sale is marked as ended
     */
    function _verifySaleHasNotEnded() internal view {
        if (saleStatus.hasEnded) revert Errors.SaleHasEnded(block.timestamp);
    }

    /**
     * @notice Ensures the sale has ended
     * @dev Reverts if sale is not marked as ended
     */
    function _verifySaleHasEnded() internal view {
        if (!saleStatus.hasEnded) revert Errors.SaleHasNotEnded();
    }

    /**
     * @notice Verifies conditions for claiming token allocation
     * @dev Checks supply and settlement status
     */
    function _verifyCanClaimTokenAllocation() internal view {
        /// Load the investor position
        InvestorPosition memory position = investorPositions[msg.sender];

        /// Check if the askToken has been supplied to the sale
        if (!saleStatus.askTokensSupplied) revert Errors.AskTokensNotSupplied();

        /// Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.AlreadySettled(msg.sender);
    }

    /**
     * @notice Ensures no tokens have been supplied
     * @dev Reverts if tokens are already supplied; virtual for overrides
     */
    function _verifyAskTokensNotSupplied() internal view virtual {
        if (saleStatus.askTokensSupplied) revert Errors.TokensAlreadySupplied();
    }

    /**
     * @notice Ensures a signature has not been used
     * @dev Prevents replay attacks by checking usage
     * @param signature Signature to verify
     */
    function _verifySignatureNotUsed(bytes memory signature) private view {
        /// Check if the signature is used
        if (usedSignatures[msg.sender][signature]) revert Errors.SignatureAlreadyUsed(signature);
    }

    /**
     * @notice Verifies conditions for withdrawing capital
     * @dev Ensures capital state allows withdrawal; virtual for overrides
     */
    function _verifyCanWithdrawCapital() internal view virtual {
        if (saleStatus.totalCapitalWithdrawn > 0) revert Errors.CapitalAlreadyWithdrawn();
        if (saleStatus.totalCapitalRaised == 0) revert Errors.CapitalNotRaised();
    }

    /**
     * @notice Ensures the refund period is over
     * @dev Reverts if refund period is still active
     */
    function _verifyRefundPeriodIsOver() internal view {
        if (saleStatus.refundEndTime > 0 && block.timestamp < saleStatus.refundEndTime) {
            revert Errors.RefundPeriodIsNotOver();
        }
    }

    /**
     * @notice Ensures the refund period is not over
     * @dev Reverts if refund period has ended
     */
    function _verifyRefundPeriodIsNotOver() internal view {
        if (saleStatus.refundEndTime > 0 && block.timestamp >= saleStatus.refundEndTime) {
            revert Errors.RefundPeriodIsOver();
        }
    }

    /**
     * @notice Ensures the investor has not refunded
     * @dev Reverts if investor has already refunded; virtual for overrides
     */
    function _verifyHasNotRefunded() internal view virtual {
        if (investorPositions[msg.sender].hasRefunded) revert Errors.InvestorHasRefunded(msg.sender);
    }

    /**
     * @notice Verifies conditions for publishing capital raised
     * @dev Ensures capital raised is not already set
     */
    function _verifyCanPublishCapitalRaised() internal view {
        if (saleStatus.totalCapitalRaised != 0) revert Errors.CapitalRaisedAlreadyPublished();
    }

    /**
     * @notice Validates an investor's position
     * @dev Verifies investment amount and signature
     * @param signature Signature to verify
     * @param actionType Type of sale action being performed
     */
    function _verifyValidPosition(bytes memory signature, SaleAction actionType) internal view {
        /// Load the investor position
        InvestorPosition memory position = investorPositions[msg.sender];

        /// Verify that the amount invested is equal to the SAFT amount
        if (position.investedCapital != position.cachedInvestAmount) {
            revert Errors.InvalidPositionAmount(msg.sender);
        }

        /// Construct the signed data
        bytes32 _data = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                block.chainid,
                uint256(position.cachedInvestAmount),
                uint256(position.cachedTokenAllocationRate),
                actionType
            )
        ).toEthSignedMessageHash();

        /// Verify the signature
        if (_data.recover(signature) != saleConfig.legionSigner) revert Errors.InvalidSignature(signature);
    }
}
