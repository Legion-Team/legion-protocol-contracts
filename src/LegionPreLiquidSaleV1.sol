// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MerkleProofLib } from "@solady/src/utils/MerkleProofLib.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "./utils/Constants.sol";
import { Errors } from "./utils/Errors.sol";
import { ILegionAddressRegistry } from "./interfaces/ILegionAddressRegistry.sol";
import { ILegionPreLiquidSaleV1 } from "./interfaces/ILegionPreLiquidSaleV1.sol";
import { ILegionLinearVesting } from "./interfaces/ILegionLinearVesting.sol";
import { ILegionVestingFactory } from "./interfaces/ILegionVestingFactory.sol";

/**
 * @title Legion Pre-Liquid Sale V1
 * @notice A contract used to execute pre-liquid sales of ERC20 tokens before TGE
 */
contract LegionPreLiquidSaleV1 is ILegionPreLiquidSaleV1, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev A struct describing the sale configuration.
    PreLiquidSaleConfig internal saleConfig;

    /// @dev A struct describing the vesting configuration.
    PreLiquidSaleVestingConfig internal vestingConfig;

    /// @dev A struct describing the sale status.
    PreLiquidSaleStatus internal saleStatus;

    /// @dev Mapping of investor address to investor position.
    mapping(address investorAddress => InvestorPosition investorPosition) public investorPositions;

    /// @dev Mapping of used signatures to prevent replay attacks.
    mapping(address investorAddress => mapping(bytes signature => bool used) usedSignature) usedSignatures;

    /**
     * @notice Throws if called by any account other than Legion.
     */
    modifier onlyLegion() {
        if (msg.sender != saleConfig.legionBouncer) revert Errors.NotCalledByLegion();
        _;
    }

    /**
     * @notice Throws if called by any account other than the Project.
     */
    modifier onlyProject() {
        if (msg.sender != saleConfig.projectAdmin) revert Errors.NotCalledByProject();
        _;
    }

    /**
     * @notice Throws if called by any account other than Legion or the Project.
     */
    modifier onlyLegionOrProject() {
        if (msg.sender != saleConfig.projectAdmin && msg.sender != saleConfig.legionBouncer) {
            revert Errors.NotCalledByLegionOrProject();
        }
        _;
    }

    /**
     * @notice Throws when method is called and the `askToken` is unavailable.
     */
    modifier askTokenAvailable() {
        if (saleStatus.askToken == address(0)) revert Errors.AskTokenUnavailable();
        _;
    }

    /**
     * @notice LegionPreLiquidSale constructor.
     */
    constructor() {
        /// Disable initialization
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with correct parameters.
     *
     * @param preLiquidSaleInitParams The pre-liquid sale initialization parameters.
     */
    function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external initializer {
        _setLegionSaleConfig(preLiquidSaleInitParams);
    }

    /**
     * @notice Invest capital to the pre-liquid sale.
     *
     * @param amount The amount of capital invested.
     * @param investAmount The amount of capital the investor is allowed to invest, according to the SAFT.
     * @param tokenAllocationRate The token allocation the investor will receive as a percentage of totalSupply,
     * represented in 18 decimals precision.
     * @param saftHash The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.
     * @param signature The signature proving that the investor is allowed to participate.
     */
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes32 saftHash,
        bytes memory signature
    )
        external
        whenNotPaused
    {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(signature);

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Increment total capital invested from investors
        saleStatus.totalCapitalInvested += amount;

        /// Increment total capital for the investor
        position.investedCapital += amount;

        /// Mark the signature as used
        usedSignatures[msg.sender][signature] = true;

        // Cache the capital invest timestamp
        if (position.cachedInvestTimestamp == 0) {
            position.cachedInvestTimestamp = block.timestamp;
        }

        /// Cache the SAFT amount the investor is allowed to invest
        if (position.cachedInvestAmount != investAmount) {
            position.cachedInvestAmount = investAmount;
        }

        /// Cache the token allocation rate in 18 decimals precision
        if (position.cachedTokenAllocationRate != tokenAllocationRate) {
            position.cachedTokenAllocationRate = tokenAllocationRate;
        }

        /// Cache the hash of the SAFT signed by the investor
        if (position.cachedSAFTHash != saftHash) {
            position.cachedSAFTHash = saftHash;
        }

        /// Verify that the investor position is valid
        _verifyValidPosition(signature, SaleAction.INVEST);

        /// Emit successfully CapitalInvested
        emit CapitalInvested(amount, msg.sender, tokenAllocationRate, saftHash, block.timestamp);

        /// Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(saleConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Get a refund from the sale during the applicable time window.
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
     * @notice Updates the token details after Token Generation Event (TGE).
     *
     * @dev Only callable by Legion.
     *
     * @param _askToken The address of the token distributed to investors.
     * @param _askTokenTotalSupply The total supply of the token distributed to investors.
     * @param _vestingStartTime The Unix timestamp (seconds) of the block when the vesting starts.
     * @param _totalTokensAllocated The allocated token amount for distribution to investors.
     */
    function publishTgeDetails(
        address _askToken,
        uint256 _askTokenTotalSupply,
        uint256 _vestingStartTime,
        uint256 _totalTokensAllocated
    )
        external
        onlyLegion
        whenNotPaused
    {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Veriify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Set the address of the token distributed to investors
        saleStatus.askToken = _askToken;

        /// Set the total supply of the token distributed to investors
        saleStatus.askTokenTotalSupply = _askTokenTotalSupply;

        /// Set the vesting start time block timestamp
        vestingConfig.vestingStartTime = _vestingStartTime;

        /// Set the total allocated amount of token for distribution.
        saleStatus.totalTokensAllocated = _totalTokensAllocated;

        /// Set `hasEnded` status to true
        if (!saleStatus.hasEnded) saleStatus.hasEnded = true;

        /// Emit successfully TgeDetailsPublished
        emit TgeDetailsPublished(_askToken, _askTokenTotalSupply, _vestingStartTime, _totalTokensAllocated);
    }

    /**
     * @notice Supply tokens for distribution after the Token Generation Event (TGE).
     *
     * @dev Only callable by the Project.
     *
     * @param amount The amount of tokens to be supplied for distribution.
     * @param legionFee The Legion fee token amount.
     * @param referrerFee The Referrer fee token amount.
     */
    function supplyAskTokens(
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
        if (legionFee != (saleConfig.legionFeeOnTokensSoldBps * amount) / 10_000) revert Errors.InvalidFeeAmount();

        /// Calculate and verify Legion Fee
        if (referrerFee != (saleConfig.referrerFeeOnTokensSoldBps * amount) / 10_000) revert Errors.InvalidFeeAmount();

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

        /// Transfer the Legion fee to the Legion fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                saleStatus.askToken, msg.sender, saleConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /**
     * @notice Updates the vesting terms.
     *
     * @dev Only callable by Legion, before the tokens have been supplied by the Project.
     *
     * @param _vestingDurationSeconds The vesting schedule duration for the token sold in seconds.
     * @param _vestingCliffDurationSeconds The vesting cliff duration for the token sold in seconds.
     * @param _tokenAllocationOnTGERate The token allocation amount released to investors after TGE in 18 decimals
     * precision.
     */
    function updateVestingTerms(
        uint256 _vestingDurationSeconds,
        uint256 _vestingCliffDurationSeconds,
        uint256 _tokenAllocationOnTGERate
    )
        external
        onlyProject
        whenNotPaused
    {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the project has not withdrawn any capital
        _verifyNoCapitalWithdrawn();

        /// Verify that tokens for distribution have not been allocated
        _verifyTokensNotAllocated();

        /// Set the vesting duration in seconds
        vestingConfig.vestingDurationSeconds = _vestingDurationSeconds;

        /// Set the vesting cliff duration in seconds
        vestingConfig.vestingCliffDurationSeconds = _vestingCliffDurationSeconds;

        /// Set the token allocation on TGE
        vestingConfig.tokenAllocationOnTGERate = _tokenAllocationOnTGERate;

        /// Verify that the vesting configuration is valid
        _verifyValidVestingConfig();

        /// Emit successfully VestingTermsUpdated
        emit VestingTermsUpdated(_vestingDurationSeconds, _vestingCliffDurationSeconds, _tokenAllocationOnTGERate);
    }

    /**
     * @notice Withdraw tokens from the contract in case of emergency.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param receiver The address of the receiver.
     * @param token The address of the token to be withdrawn.
     * @param amount The amount to be withdrawn.
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        /// Emit successfully EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        /// Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /**
     * @notice Withdraw capital from the contract.
     *
     * @dev Can be called only by the Project admin address.
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
        saleStatus.totalCapitalWithdrawn = saleStatus.totalCapitalInvested;

        /// Calculate Legion Fee
        uint256 legionFee = (saleConfig.legionFeeOnCapitalRaisedBps * saleStatus.totalCapitalWithdrawn) / 10_000;

        /// Calculate Referrer Fee
        uint256 referrerFee = (saleConfig.referrerFeeOnCapitalRaisedBps * saleStatus.totalCapitalWithdrawn) / 10_000;

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
     * @notice Claim token allocation by investors.
     *
     * @param investAmount The amount of capital the investor is allowed to invest, according to the SAFT.
     * @param tokenAllocationRate The token allocation the investor will receive as a percentage of totalSupply,
     * represented in 18 decimals precision.
     * @param saftHash The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.
     * @param signature The signature proving that the investor has signed a SAFT.
     */
    function claimAskTokenAllocation(
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes32 saftHash,
        bytes memory signature
    )
        external
        whenNotPaused
        askTokenAvailable
    {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

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

        /// Cache the hash of the SAFT signed by the investor
        if (position.cachedSAFTHash != saftHash) {
            position.cachedSAFTHash = saftHash;
        }

        /// Verify that the investor can claim the token allocation
        _verifyCanClaimTokenAllocation();

        /// Verify that the investor position is valid
        _verifyValidPosition(signature, SaleAction.CLAIM_TOKEN_ALLOCATION);

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(signature);

        /// Mark the signature as used
        usedSignatures[msg.sender][signature] = true;

        /// Mark that the token amount has been settled
        position.hasSettled = true;

        /// Calculate the total token amount to be claimed
        uint256 totalAmount = saleStatus.askTokenTotalSupply * position.cachedTokenAllocationRate / 1e18;

        /// Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim = totalAmount * vestingConfig.tokenAllocationOnTGERate / 1e18;

        /// Calculate the remaining amount to be vested
        uint256 amountToBeVested = totalAmount - amountToDistributeOnClaim;

        /// Emit successfully TokenAllocationClaimed
        emit TokenAllocationClaimed(amountToBeVested, amountToDistributeOnClaim, msg.sender);

        // Deploy vesting and distribute tokens only if there is anything to distribute
        if (amountToBeVested != 0) {
            /// Deploy a linear vesting schedule contract
            address payable vestingAddress = _createVesting(
                msg.sender,
                uint64(vestingConfig.vestingStartTime),
                uint64(vestingConfig.vestingDurationSeconds),
                uint64(vestingConfig.vestingCliffDurationSeconds)
            );

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
     * @notice Cancel the sale.
     *
     * @dev Can be called only by the Project admin address.
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
     * @notice Withdraw capital if the sale has been canceled.
     */
    function withdrawCapitalIfSaleIsCanceled() external whenNotPaused {
        /// Verify that the sale has been actually canceled
        _verifySaleIsCanceled();

        /// Cache the amount to refund in memory
        uint256 amountToClaim = investorPositions[msg.sender].investedCapital;

        /// Revert in case there's nothing to claim
        if (amountToClaim == 0) revert Errors.InvalidClaimAmount();

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
     * @notice Withdraw back excess capital from investors.
     *
     * @param amount The amount of excess capital to be withdrawn.
     * @param investAmount The amount of capital the investor is allowed to invest, according to the SAFT.
     * @param tokenAllocationRate The token allocation the investor will receive as a percentage of totalSupply,
     * represented in 18 decimals precision.
     * @param saftHash The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.
     * @param signature The signature proving that the investor is allowed to participate.
     */
    function withdrawExcessCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes32 saftHash,
        bytes memory signature
    )
        external
        whenNotPaused
    {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(signature);

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Decrement total capital invested from investors
        saleStatus.totalCapitalInvested -= amount;

        /// Decrement total investor capital for the investor
        position.investedCapital -= amount;

        /// Mark the signature as used
        usedSignatures[msg.sender][signature] = true;

        /// Cache the maximum amount the investor is allowed to invest
        if (position.cachedInvestAmount != investAmount) {
            position.cachedInvestAmount = investAmount;
        }

        /// Cache the token allocation rate in 18 decimals precision
        if (position.cachedTokenAllocationRate != tokenAllocationRate) {
            position.cachedTokenAllocationRate = tokenAllocationRate;
        }

        /// Cache the hash of the SAFT signed by the investor
        if (position.cachedSAFTHash != saftHash) {
            position.cachedSAFTHash = saftHash;
        }

        /// Verify that the investor position is valid
        _verifyValidPosition(signature, SaleAction.WITHDRAW_EXCESS_CAPITAL);

        /// Emit successfully ExcessCapitalWithdrawn
        emit ExcessCapitalWithdrawn(amount, msg.sender, tokenAllocationRate, saftHash, block.timestamp);

        /// Transfer the excess capital to the investor
        SafeTransferLib.safeTransfer(saleConfig.bidToken, msg.sender, amount);
    }

    /**
     * @notice Releases tokens from vesting to the investor address.
     */
    function releaseTokens() external whenNotPaused askTokenAvailable {
        /// Get the investor position details
        InvestorPosition memory position = investorPositions[msg.sender];

        /// Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert Errors.ZeroAddressProvided();

        /// Release tokens to the investor account
        ILegionLinearVesting(position.vestingAddress).release(saleStatus.askToken);
    }

    /**
     * @notice Ends the sale.
     */
    function endSale() external onlyLegionOrProject {
        /// Verify that tokens for distribution have not been allocated
        _verifyTokensNotAllocated();

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

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
     * @notice Syncs active Legion addresses from `LegionAddressRegistry.sol`.
     */
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /**
     * @notice Pauses the sale.
     */
    function pauseSale() external virtual onlyLegion {
        // Pause the sale
        _pause();
    }

    /**
     * @notice Unpauses the sale.
     */
    function unpauseSale() external virtual onlyLegion {
        // Unpause the sale
        _unpause();
    }

    /**
     * @notice Returns the sale configuration.
     */
    function saleConfiguration() external view returns (PreLiquidSaleConfig memory) {
        /// Get the pre-liquid sale config
        return saleConfig;
    }

    /**
     * @notice Returns the sale status details.
     */
    function saleStatusDetails() external view returns (PreLiquidSaleStatus memory) {
        /// Get the pre-liquid sale status
        return saleStatus;
    }

    /**
     * @notice Returns the sale vesting configuration.
     */
    function vestingConfiguration() external view returns (PreLiquidSaleVestingConfig memory) {
        /// Get the pre-liquid sale vesting config
        return vestingConfig;
    }

    /**
     * @notice Returns an investor position details.
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory) {
        return investorPositions[investorAddress];
    }

    /**
     * @notice Create a vesting schedule contract.
     *
     * @param _beneficiary The beneficiary.
     * @param _startTimestamp The start timestamp.
     * @param _durationSeconds The duration in seconds.
     * @param _cliffDurationSeconds The cliff duration in seconds.
     *
     * @return vestingInstance The address of the deployed vesting instance.
     */
    function _createVesting(
        address _beneficiary,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        uint64 _cliffDurationSeconds
    )
        internal
        returns (address payable vestingInstance)
    {
        /// Deploy a vesting schedule instance
        vestingInstance = ILegionVestingFactory(saleConfig.vestingFactory).createLinearVesting(
            _beneficiary, _startTimestamp, _durationSeconds, _cliffDurationSeconds
        );
    }

    /**
     * @notice Sets the sale and vesting params.
     */
    function _setLegionSaleConfig(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams)
        internal
        virtual
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

        /// Initialize pre-liquid sale vesting configuration
        vestingConfig.vestingDurationSeconds = preLiquidSaleInitParams.vestingDurationSeconds;
        vestingConfig.vestingCliffDurationSeconds = preLiquidSaleInitParams.vestingCliffDurationSeconds;
        vestingConfig.tokenAllocationOnTGERate = preLiquidSaleInitParams.tokenAllocationOnTGERate;

        /// Verify that the vesting configuration is valid
        _verifyValidVestingConfig();

        /// Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /**
     * @notice Sync Legion addresses from `LegionAddressRegistry`.
     */
    function _syncLegionAddresses() internal virtual {
        // Cache Legion addresses from `LegionAddressRegistry`
        saleConfig.legionBouncer =
            ILegionAddressRegistry(saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        saleConfig.legionSigner =
            ILegionAddressRegistry(saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        saleConfig.legionFeeReceiver =
            ILegionAddressRegistry(saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);
        saleConfig.vestingFactory =
            ILegionAddressRegistry(saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_VESTING_FACTORY_ID);

        // Emit successfully LegionAddressesSynced
        emit LegionAddressesSynced(
            saleConfig.legionBouncer, saleConfig.legionSigner, saleConfig.legionFeeReceiver, saleConfig.vestingFactory
        );
    }

    /**
     * @notice Verify if the sale configuration is valid.
     *
     * @param _preLiquidSaleInitParams The configuration for the pre-liquid sale.
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
        if (_preLiquidSaleInitParams.refundPeriodSeconds > Constants.TWO_WEEKS) revert Errors.InvalidPeriodConfig();
    }

    /**
     * @notice Verify if the project can supply tokens for distribution.
     *
     * @param _amount The amount to supply.
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
     * @notice Verify if the tokens for distribution have not been allocated.
     */
    function _verifyTokensNotAllocated() private view {
        /// Revert if the tokens for distribution have already been allocated
        if (saleStatus.totalTokensAllocated > 0) revert Errors.TokensAlreadyAllocated();
    }

    /**
     * @notice Verify that the sale is not canceled.
     */
    function _verifySaleNotCanceled() internal view {
        if (saleStatus.isCanceled) revert Errors.SaleIsCanceled();
    }

    /**
     * @notice Verify that the sale is canceled.
     */
    function _verifySaleIsCanceled() internal view {
        if (!saleStatus.isCanceled) revert Errors.SaleIsNotCanceled();
    }

    /**
     * @notice Verify that the Project has not withdrawn any capital.
     */
    function _verifyNoCapitalWithdrawn() internal view {
        if (saleStatus.totalCapitalWithdrawn > 0) revert Errors.ProjectHasWithdrawnCapital();
    }
    /**
     * @notice Verify that the sale has not ended.
     */

    function _verifySaleHasNotEnded() internal view {
        if (saleStatus.hasEnded) revert Errors.SaleHasEnded();
    }

    /**
     * @notice Verify that the sale has ended.
     */
    function _verifySaleHasEnded() internal view {
        if (!saleStatus.hasEnded) revert Errors.SaleHasNotEnded();
    }

    /**
     * @notice Verify if an investor is eligible to claim token allocation.
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
     * @notice Verify that the project has not supplied ask tokens to the sale.
     */
    function _verifyAskTokensNotSupplied() internal view virtual {
        if (saleStatus.askTokensSupplied) revert Errors.TokensAlreadySupplied();
    }

    /**
     * @notice Verify that the signature has not been used.
     *
     * @param signature The signature proving the investor is part of the whitelist
     */
    function _verifySignatureNotUsed(bytes memory signature) private view {
        /// Check if the signature is used
        if (usedSignatures[msg.sender][signature]) revert Errors.SignatureAlreadyUsed(signature);
    }

    /**
     * @notice Verify that the project can withdraw capital.
     */
    function _verifyCanWithdrawCapital() internal view virtual {
        if (saleStatus.totalCapitalWithdrawn > 0) revert Errors.CapitalAlreadyWithdrawn();
    }

    /**
     * @notice Verify that the refund period is over.
     */
    function _verifyRefundPeriodIsOver() internal view {
        if (saleStatus.refundEndTime > 0 && block.timestamp < saleStatus.refundEndTime) {
            revert Errors.RefundPeriodIsNotOver();
        }
    }

    /**
     * @notice Verify that the refund period is not over.
     */
    function _verifyRefundPeriodIsNotOver() internal view {
        if (saleStatus.refundEndTime > 0 && block.timestamp >= saleStatus.refundEndTime) {
            revert Errors.RefundPeriodIsOver();
        }
    }

    /**
     * @notice Verify that the investor has not received a refund.
     */
    function _verifyHasNotRefunded() internal view virtual {
        if (investorPositions[msg.sender].hasRefunded) revert Errors.InvestorHasRefunded(msg.sender);
    }

    /**
     * @notice Verify that the vesting configuration is valid.
     */
    function _verifyValidVestingConfig() internal view virtual {
        /// Check if vesting duration is no more than 10 years, if vesting cliff duration is not more than vesting
        /// duration or the token allocation on TGE rate is no more than 100%
        if (
            vestingConfig.vestingDurationSeconds > Constants.TEN_YEARS
                || vestingConfig.vestingCliffDurationSeconds > vestingConfig.vestingDurationSeconds
                || vestingConfig.tokenAllocationOnTGERate > 1e18
        ) revert Errors.InvalidVestingConfig();
    }

    /**
     * @notice Verify if the investor position is valid
     *
     * @param signature The signature proving the investor is part of the whitelist
     * @param actionType The type of sale action
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
                bytes32(uint256(position.cachedSAFTHash)),
                actionType
            )
        ).toEthSignedMessageHash();

        /// Verify the signature
        if (_data.recover(signature) != saleConfig.legionSigner) revert Errors.InvalidSignature();
    }
}
