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
import { ILegionSale } from "./interfaces/ILegionSale.sol";
import { ILegionLinearVesting } from "./interfaces/ILegionLinearVesting.sol";
import { ILegionVestingFactory } from "./interfaces/ILegionVestingFactory.sol";

/**
 * @title Legion Sale
 * @author Legion
 * @notice A contract used for managing token sales in the Legion Protocol
 */
abstract contract LegionSale is ILegionSale, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev A struct describing the sale configuration.
    LegionSaleConfiguration internal saleConfig;

    /// @dev A struct describing the sale addresses configuration.
    LegionSaleAddressConfiguration internal addressConfig;

    /// @dev A struct describing the vesting configuration.
    LegionVestingConfiguration internal vestingConfig;

    /// @dev A struct describing the sale status.
    LegionSaleStatus internal saleStatus;

    /// @dev Mapping of investor address to investor position.
    mapping(address investorAddress => InvestorPosition investorPosition) internal investorPositions;

    /**
     * @notice Throws if called by any account other than Legion.
     */
    modifier onlyLegion() {
        if (msg.sender != addressConfig.legionBouncer) revert Errors.NotCalledByLegion();
        _;
    }

    /**
     * @notice Throws if called by any account other than the Project.
     */
    modifier onlyProject() {
        if (msg.sender != addressConfig.projectAdmin) revert Errors.NotCalledByProject();
        _;
    }

    /**
     * @notice Throws if called by any account other than Legion or the Project.
     */
    modifier onlyLegionOrProject() {
        if (msg.sender != addressConfig.projectAdmin && msg.sender != addressConfig.legionBouncer) {
            revert Errors.NotCalledByLegionOrProject();
        }
        _;
    }

    /**
     * @notice Throws when method is called and the `askToken` is unavailable.
     */
    modifier askTokenAvailable() {
        if (addressConfig.askToken == address(0)) revert Errors.AskTokenUnavailable();
        _;
    }

    /**
     * @notice LegionSale constructor.
     */
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /**
     * @notice Request a refund from the sale during the applicable time window.
     */
    function refund() external virtual whenNotPaused {
        // Verify that the refund period is not over
        _verifyRefundPeriodIsNotOver();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        // Cache the amount to refund in memory
        uint256 amountToRefund = investorPositions[msg.sender].investedCapital;

        // Revert in case there's nothing to refund
        if (amountToRefund == 0) revert Errors.InvalidRefundAmount();

        // Set the total invested capital for the investor to 0
        investorPositions[msg.sender].investedCapital = 0;

        // Flag that the investor has refunded
        investorPositions[msg.sender].hasRefunded = true;

        // Decrement total capital invested from investors
        saleStatus.totalCapitalInvested -= amountToRefund;

        // Emit CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(addressConfig.bidToken, msg.sender, amountToRefund);
    }

    /**
     * @notice Withdraw raised capital from the sale contract.
     *
     * @dev Can be called only by the Project admin address.
     */
    function withdrawRaisedCapital() external virtual onlyProject whenNotPaused {
        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that sale results have been published
        _verifySaleResultsArePublished();

        // Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        // Check if projects are withdrawing capital on the sale source chain
        if (addressConfig.askToken != address(0)) {
            // Allow projects to withdraw capital only in case they've supplied tokens
            _verifyTokensSupplied();
        }

        // Flag that the capital has been withdrawn
        saleStatus.capitalWithdrawn = true;

        // Cache value in memory
        uint256 _totalCapitalRaised = saleStatus.totalCapitalRaised;

        // Calculate Legion Fee
        uint256 _legionFee = (saleConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / 10_000;

        // Calculate Referrer Fee
        uint256 _referrerFee = (saleConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised) / 10_000;

        // Emit CapitalWithdrawn
        emit CapitalWithdrawn(_totalCapitalRaised, msg.sender);

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

    /**
     * @notice Claims the investor token allocation.
     *
     * @param amount The amount to be distributed.
     * @param proof The merkle proof verification for claiming.
     */
    function claimTokenAllocation(
        uint256 amount,
        bytes32[] calldata proof
    )
        external
        virtual
        askTokenAvailable
        whenNotPaused
    {
        // Verify that sales results have been published
        _verifySaleResultsArePublished();

        // Verify that the investor is eligible to claim the requested amount
        _verifyCanClaimTokenAllocation(msg.sender, amount, proof);

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the lockup period is over
        _verifyLockupPeriodIsOver();

        // Mark that the token amount has been settled
        investorPositions[msg.sender].hasSettled = true;

        // Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim = amount * vestingConfig.tokenAllocationOnTGERate / 1e18;

        // Calculate the remaining amount to be vested
        uint256 amountToBeVested = amount - amountToDistributeOnClaim;

        // Emit TokenAllocationClaimed
        emit TokenAllocationClaimed(amount, msg.sender);

        // Deploy vesting and distribute tokens only if there is anything to distribute
        if (amountToBeVested != 0) {
            // Deploy a linear vesting schedule contract
            address payable vestingAddress = _createVesting(
                msg.sender,
                uint64(vestingConfig.vestingStartTime),
                uint64(vestingConfig.vestingDurationSeconds),
                uint64(vestingConfig.vestingCliffDurationSeconds)
            );

            // Save the vesting address for the investor
            investorPositions[msg.sender].vestingAddress = vestingAddress;

            // Transfer the allocated amount of tokens for distribution
            SafeTransferLib.safeTransfer(addressConfig.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            // Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(addressConfig.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /**
     * @notice Withdraw excess capital back to the investor.
     *
     * @param amount The amount to be returned.
     * @param proof The merkle proof verification for the return.
     */
    function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external virtual whenNotPaused {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        // Verify that the investor is eligible to get excess capital back
        _verifyCanClaimExcessCapital(msg.sender, amount, proof);

        // Mark that the excess capital has been returned
        investorPositions[msg.sender].hasClaimedExcess = true;

        if (amount != 0) {
            // Decrement the total invested capital for the investor
            investorPositions[msg.sender].investedCapital -= amount;

            // Decrement total capital invested from investors
            saleStatus.totalCapitalInvested -= amount;

            // Emit ExcessCapitalWithdrawn
            emit ExcessCapitalWithdrawn(amount, msg.sender);

            // Transfer the excess capital back to the investor
            SafeTransferLib.safeTransfer(addressConfig.bidToken, msg.sender, amount);
        }
    }

    /**
     * @notice Releases tokens to the investor address.
     */
    function releaseVestedTokens() external virtual askTokenAvailable whenNotPaused {
        // Get the investor position details
        InvestorPosition memory position = investorPositions[msg.sender];

        // Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert Errors.ZeroAddressProvided();

        // Release tokens to the investor account
        ILegionLinearVesting(position.vestingAddress).release(addressConfig.askToken);
    }

    /**
     * @notice Supply tokens once the sale results have been published.
     *
     * @dev Can be called only by the Project admin address.
     *
     * @param amount The token amount supplied by the project.
     * @param legionFee The legion fee token amount supplied by the project.
     * @param referrerFee The referrer fee token amount supplied by the project.
     */
    function supplyTokens(
        uint256 amount,
        uint256 legionFee,
        uint256 referrerFee
    )
        external
        virtual
        onlyProject
        askTokenAvailable
        whenNotPaused
    {
        // Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that tokens have not been supplied
        _verifyTokensNotSupplied();

        // Flag that tokens have been supplied
        saleStatus.tokensSupplied = true;

        // Calculate and verify Legion Fee
        if (legionFee != (saleConfig.legionFeeOnTokensSoldBps * amount) / 10_000) revert Errors.InvalidFeeAmount();

        // Calculate and verify Legion Fee
        if (referrerFee != (saleConfig.referrerFeeOnTokensSoldBps * amount) / 10_000) revert Errors.InvalidFeeAmount();

        // Emit TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        // Transfer the allocated amount of tokens for distribution
        SafeTransferLib.safeTransferFrom(addressConfig.askToken, msg.sender, address(this), amount);

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(
                addressConfig.askToken, msg.sender, addressConfig.legionFeeReceiver, legionFee
            );
        }

        // Transfer the Referrer fee to the referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                addressConfig.askToken, msg.sender, addressConfig.referrerFeeReceiver, legionFee
            );
        }
    }

    /**
     * @notice Publish merkle root for accepted capital.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param merkleRoot The merkle root to verify against.
     */
    function setAcceptedCapital(bytes32 merkleRoot) external virtual onlyLegion {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Set the merkle root for accepted capital
        saleStatus.acceptedCapitalMerkleRoot = merkleRoot;

        // Emit AcceptedCapitalSet
        emit AcceptedCapitalSet(merkleRoot);
    }

    /**
     * @notice Cancels an ongoing sale.
     *
     * @dev Can be called only by the Project admin address.
     */
    function cancelSale() public virtual onlyProject whenNotPaused {
        // Allow the Project to cancel the sale at any time until results are published
        // Results are published after the refund period is over
        _verifySaleResultsNotPublished();

        // Verify sale has not already been canceled
        _verifySaleNotCanceled();

        // Mark sale as canceled
        saleStatus.isCanceled = true;

        // Emit SaleCanceled
        emit SaleCanceled();
    }

    /**
     * @notice Cancels a sale in case the project has not supplied tokens after the lockup period is over.
     */
    function cancelExpiredSale() external virtual whenNotPaused {
        // Verify that the lockup period is over
        _verifyLockupPeriodIsOver();

        // Verify sale has not already been canceled
        _verifySaleNotCanceled();

        if (addressConfig.askToken != address(0)) {
            // Verify that no tokens have been supplied by the project
            _verifyTokensNotSupplied();
        } else {
            // Verify that the sale results have not been published
            _verifySaleResultsNotPublished();
        }

        // Mark sale as canceled
        saleStatus.isCanceled = true;

        // Emit SaleCanceled
        emit SaleCanceled();
    }

    /**
     * @notice Withdraws back capital in case the sale has been canceled.
     */
    function withdrawInvestedCapitalIfCanceled() external virtual whenNotPaused {
        // Verify that the sale has been actually canceled
        _verifySaleIsCanceled();

        // Cache the amount to refund in memory
        uint256 amountToWithdraw = investorPositions[msg.sender].investedCapital;

        // Revert in case there's nothing to claim
        if (amountToWithdraw == 0) revert Errors.InvalidWithdrawAmount();

        // Set the total invested capital for the investor to 0
        investorPositions[msg.sender].investedCapital = 0;

        // Decrement total capital invested from investors
        saleStatus.totalCapitalInvested -= amountToWithdraw;

        // Emit CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToWithdraw, msg.sender);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(addressConfig.bidToken, msg.sender, amountToWithdraw);
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
    function emergencyWithdraw(address receiver, address token, uint256 amount) external virtual onlyLegion {
        // Emit EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /**
     * @notice Syncs active Legion addresses from `LegionAddressRegistry.sol`.
     */
    function syncLegionAddresses() external virtual onlyLegion {
        // Sync the Legion addresses
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
    function saleConfiguration() external view virtual returns (LegionSaleConfiguration memory) {
        return saleConfig;
    }

    /**
     * @notice Returns the vesting configuration.
     */
    function vestingConfiguration() external view virtual returns (LegionVestingConfiguration memory) {
        return vestingConfig;
    }

    /**
     * @notice Returns the sale status details.
     */
    function saleStatusDetails() external view virtual returns (LegionSaleStatus memory) {
        return saleStatus;
    }

    /**
     * @notice Returns an investor position.
     *
     * @param investorAddress The address of the investor.
     */
    function investorPositionDetails(address investorAddress) external view virtual returns (InvestorPosition memory) {
        return investorPositions[investorAddress];
    }

    /**
     * @notice Sets the sale and vesting params.
     */
    function _setLegionSaleConfig(
        LegionSaleInitializationParams calldata saleInitParams,
        LegionVestingInitializationParams calldata vestingInitParams
    )
        internal
        virtual
        onlyInitializing
    {
        // Verify if the sale common configuration is valid
        _verifyValidInitParams(saleInitParams);

        // Set the sale configuration
        saleConfig.legionFeeOnCapitalRaisedBps = saleInitParams.legionFeeOnCapitalRaisedBps;
        saleConfig.legionFeeOnTokensSoldBps = saleInitParams.legionFeeOnTokensSoldBps;
        saleConfig.referrerFeeOnCapitalRaisedBps = saleInitParams.referrerFeeOnCapitalRaisedBps;
        saleConfig.referrerFeeOnTokensSoldBps = saleInitParams.referrerFeeOnTokensSoldBps;
        saleConfig.minimumInvestAmount = saleInitParams.minimumInvestAmount;

        // Set the address configuration
        addressConfig.bidToken = saleInitParams.bidToken;
        addressConfig.askToken = saleInitParams.askToken;
        addressConfig.projectAdmin = saleInitParams.projectAdmin;
        addressConfig.addressRegistry = saleInitParams.addressRegistry;
        addressConfig.referrerFeeReceiver = saleInitParams.referrerFeeReceiver;

        // Set the vesting configuration
        vestingConfig.vestingDurationSeconds = vestingInitParams.vestingDurationSeconds;
        vestingConfig.vestingCliffDurationSeconds = vestingInitParams.vestingCliffDurationSeconds;
        vestingConfig.tokenAllocationOnTGERate = vestingInitParams.tokenAllocationOnTGERate;

        /// Verify that the vesting configuration is valid
        _verifyValidVestingConfig();

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /**
     * @notice Sync the Legion addresses from `LegionAddressRegistry`.
     */
    function _syncLegionAddresses() internal virtual {
        // Cache Legion addresses from `LegionAddressRegistry`
        addressConfig.legionBouncer =
            ILegionAddressRegistry(addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        addressConfig.legionSigner =
            ILegionAddressRegistry(addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        addressConfig.legionFeeReceiver =
            ILegionAddressRegistry(addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);
        vestingConfig.vestingFactory =
            ILegionAddressRegistry(addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_VESTING_FACTORY_ID);

        // Emit LegionAddressesSynced
        emit LegionAddressesSynced(
            addressConfig.legionBouncer,
            addressConfig.legionSigner,
            addressConfig.legionFeeReceiver,
            vestingConfig.vestingFactory
        );
    }

    /**
     * @notice Create a vesting schedule contract.
     *
     * @param _beneficiary The beneficiary.
     * @param _startTimestamp The Unix timestamp when the vesting starts.
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
        virtual
        returns (address payable vestingInstance)
    {
        // Deploy a vesting schedule instance
        vestingInstance = ILegionVestingFactory(vestingConfig.vestingFactory).createLinearVesting(
            _beneficiary, _startTimestamp, _durationSeconds, _cliffDurationSeconds
        );
    }

    /**
     * @notice Verify if an investor is eligible to claim tokens allocated from the sale.
     *
     * @param _investor The address of the investor.
     * @param _amount The amount to claim.
     * @param _proof The Merkle proof that the investor is part of the whitelist.
     */
    function _verifyCanClaimTokenAllocation(
        address _investor,
        uint256 _amount,
        bytes32[] calldata _proof
    )
        internal
        view
        virtual
    {
        // Generate the merkle leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, _amount))));

        // Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        // Verify the merkle proof
        if (!MerkleProofLib.verify(_proof, saleStatus.claimTokensMerkleRoot, leaf)) {
            revert Errors.NotInClaimWhitelist(_investor);
        }

        // Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.AlreadySettled(_investor);

        // Safeguard to check if the investor has invested capital
        if (position.investedCapital == 0) revert Errors.NoCapitalInvested(_investor);
    }

    /**
     * @notice Verify if an investor is eligible to get excess capital back.
     *
     * @param _investor The address of the investor trying to participate.
     * @param _amount The amount to claim.
     * @param _proof The Merkle proof that the investor is part of the whitelist.
     */
    function _verifyCanClaimExcessCapital(
        address _investor,
        uint256 _amount,
        bytes32[] calldata _proof
    )
        internal
        view
        virtual
    {
        // Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        // Check if the investor has already settled their allocation
        if (position.hasClaimedExcess) revert Errors.AlreadyClaimedExcess(_investor);

        // Safeguard to check if the investor has invested capital
        if (position.investedCapital == 0) revert Errors.NoCapitalInvested(_investor);

        // Generate the merkle leaf and verify accepted capital
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, (position.investedCapital - _amount)))));

        // Verify the merkle proof
        if (!MerkleProofLib.verify(_proof, saleStatus.acceptedCapitalMerkleRoot, leaf)) {
            revert Errors.CannotWithdrawExcessInvestedCapital(_investor);
        }
    }

    /**
     * @notice Verify that the amount invested is more than the minimum required.
     *
     * @param _amount The amount being invested.
     */
    function _verifyMinimumInvestAmount(uint256 _amount) internal view virtual {
        if (_amount < saleConfig.minimumInvestAmount) revert Errors.InvalidInvestAmount(_amount);
    }

    /**
     * @notice Verify that the sale has not ended.
     */
    function _verifySaleHasNotEnded() internal view virtual {
        if (block.timestamp >= saleConfig.endTime) revert Errors.SaleHasEnded();
    }

    /**
     * @notice Verify that the refund period is over.
     */
    function _verifyRefundPeriodIsOver() internal view virtual {
        if (block.timestamp < saleConfig.refundEndTime) revert Errors.RefundPeriodIsNotOver();
    }

    /**
     * @notice Verify that the refund period is not over.
     */
    function _verifyRefundPeriodIsNotOver() internal view virtual {
        if (block.timestamp >= saleConfig.refundEndTime) revert Errors.RefundPeriodIsOver();
    }

    /**
     * @notice Verify that the lockup period is over.
     */
    function _verifyLockupPeriodIsOver() internal view virtual {
        if (block.timestamp < saleConfig.lockupEndTime) revert Errors.LockupPeriodIsNotOver();
    }

    /**
     * @notice Verify if sale results are published.
     */
    function _verifySaleResultsArePublished() internal view virtual {
        if (saleStatus.totalTokensAllocated == 0) revert Errors.SaleResultsNotPublished();
    }

    /**
     * @notice Verify if sale results are not published.
     */
    function _verifySaleResultsNotPublished() internal view virtual {
        if (saleStatus.totalTokensAllocated != 0) revert Errors.SaleResultsAlreadyPublished();
    }

    /**
     * @notice Verify if the project can supply tokens for distribution.
     *
     * @param _amount The amount to supply.
     */
    function _verifyCanSupplyTokens(uint256 _amount) internal view virtual {
        // Revert if Legion has not set the total amount of tokens allocated for distribution
        if (saleStatus.totalTokensAllocated == 0) revert Errors.TokensNotAllocated();

        // Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != saleStatus.totalTokensAllocated) revert Errors.InvalidTokenAmountSupplied(_amount);
    }

    /**
     * @notice Verify if Legion can publish sale results.
     */
    function _verifyCanPublishSaleResults() internal view virtual {
        if (saleStatus.totalTokensAllocated != 0) revert Errors.TokensAlreadyAllocated();
    }

    /**
     * @notice Verify that the sale is not canceled.
     */
    function _verifySaleNotCanceled() internal view virtual {
        if (saleStatus.isCanceled) revert Errors.SaleIsCanceled();
    }

    /**
     * @notice Verify that the sale is canceled.
     */
    function _verifySaleIsCanceled() internal view virtual {
        if (!saleStatus.isCanceled) revert Errors.SaleIsNotCanceled();
    }

    /**
     * @notice Verify that the project has not supplied tokens to the sale.
     */
    function _verifyTokensNotSupplied() internal view virtual {
        if (saleStatus.tokensSupplied) revert Errors.TokensAlreadySupplied();
    }

    /**
     * @notice Verify that the project has supplied tokens to the sale.
     */
    function _verifyTokensSupplied() internal view virtual {
        if (!saleStatus.tokensSupplied) revert Errors.TokensNotSupplied();
    }

    /**
     * @notice Verify that the signature provided is signed by Legion.
     *
     * @param _signature The signature to verify.
     */
    function _verifyLegionSignature(bytes memory _signature) internal view virtual {
        bytes32 _data = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid)).toEthSignedMessageHash();
        if (_data.recover(_signature) != addressConfig.legionSigner) revert Errors.InvalidSignature();
    }

    /**
     * @notice Verify that the project can withdraw capital.
     */
    function _verifyCanWithdrawCapital() internal view virtual {
        if (saleStatus.capitalWithdrawn) revert Errors.CapitalAlreadyWithdrawn();
    }

    /**
     * @notice Verify that the investor has not received a refund.
     */
    function _verifyHasNotRefunded() internal view virtual {
        if (investorPositions[msg.sender].hasRefunded) revert Errors.InvestorHasRefunded(msg.sender);
    }

    /**
     * @notice Verify the common sale configuration is valid.
     */
    function _verifyValidInitParams(LegionSaleInitializationParams memory saleInitParams) internal view virtual {
        // Check for zero addresses provided
        if (
            saleInitParams.bidToken == address(0) || saleInitParams.projectAdmin == address(0)
                || saleInitParams.addressRegistry == address(0)
        ) {
            revert Errors.ZeroAddressProvided();
        }

        // Check for zero values provided
        if (
            saleInitParams.salePeriodSeconds == 0 || saleInitParams.refundPeriodSeconds == 0
                || saleInitParams.lockupPeriodSeconds == 0
        ) revert Errors.ZeroValueProvided();

        // Check if sale, refund and lockup periods are longer than allowed
        if (
            saleInitParams.salePeriodSeconds > Constants.THREE_MONTHS
                || saleInitParams.refundPeriodSeconds > Constants.TWO_WEEKS
                || saleInitParams.lockupPeriodSeconds > Constants.SIX_MONTHS
        ) {
            revert Errors.InvalidPeriodConfig();
        }

        // Check if sale, refund and lockup periods are shorter than allowed
        if (
            saleInitParams.salePeriodSeconds < Constants.ONE_HOUR
                || saleInitParams.refundPeriodSeconds < Constants.ONE_HOUR
                || saleInitParams.lockupPeriodSeconds < Constants.ONE_HOUR
        ) {
            revert Errors.InvalidPeriodConfig();
        }
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
}
