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
import { MerkleProofLib } from "@solady/src/utils/MerkleProofLib.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";
import { ILegionVesting } from "../interfaces/vesting/ILegionVesting.sol";

import { LegionPositionManager } from "../position/LegionPositionManager.sol";
import { LegionVestingManager } from "../vesting/LegionVestingManager.sol";

/**
 * @title Legion Abstract Sale
 * @author Legion
 * @notice Provides core functionality for token sales in the Legion Protocol.
 * @dev Abstract base contract that implements common sale operations including investments, refunds, token
 * distribution, and position management using soulbound NFTs.
 */
abstract contract LegionAbstractSale is
    ILegionAbstractSale,
    LegionVestingManager,
    LegionPositionManager,
    Initializable,
    Pausable
{
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev Struct containing the sale configuration
    LegionSaleConfiguration internal s_saleConfig;

    /// @dev Struct containing the sale addresses configuration
    LegionSaleAddressConfiguration internal s_addressConfig;

    /// @dev Struct tracking the current sale status
    LegionSaleStatus internal s_saleStatus;

    /// @dev Mapping of position IDs to their respective positions
    mapping(uint256 s_positionId => InvestorPosition s_investorPosition) internal s_investorPositions;

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

    /// @notice Restricts interaction to when tokens have not been supplied for distribution.
    /// @dev Reverts if tokens have been supplied.
    modifier whenTokensNotSupplied() {
        // Verify that no tokens have been supplied to the sale by the Project
        _verifyTokensNotSupplied();
        _;
    }

    /// @notice Restricts interaction to when tokens have been supplied for distribution.
    /// @dev Reverts if tokens have not been supplied.
    modifier whenTokensSupplied() {
        // Verify that tokens have been supplied to the sale by the Project
        _verifyTokensSupplied();
        _;
    }

    /// @notice Restricts interaction to when the sale results have been published.
    /// @dev Reverts if sale results have not been published.
    modifier whenSaleResultsArePublished() {
        // Verify that sale results have been published
        _verifySaleResultsArePublished();
        _;
    }

    /// @notice Restricts interaction to when the sale results have not been published.
    /// @dev Reverts if sale results have been published.
    modifier whenSaleResultsNotPublished() {
        // Verify that sale results have not been published
        _verifySaleResultsNotPublished();
        _;
    }

    /// @notice Constructor for the LegionAbstractSale contract.
    /// @dev Prevents the implementation contract from being initialized directly.
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /// @inheritdoc ILegionAbstractSale
    function refund() external virtual whenNotPaused whenRefundPeriodNotOver whenSaleNotCanceled {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Cache the amount to refund in memory
        uint256 amountToRefund = s_investorPositions[positionId].investedCapital;

        // Set the total invested capital for the investor to 0
        s_investorPositions[positionId].investedCapital = 0;

        // Flag that the investor has refunded
        s_investorPositions[positionId].hasRefunded = true;

        // Decrement total capital invested from investors
        s_saleStatus.totalCapitalInvested -= amountToRefund;

        // Emit CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender, positionId);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_addressConfig.bidToken, msg.sender, amountToRefund);
    }

    /// @inheritdoc ILegionAbstractSale
    function withdrawRaisedCapital()
        external
        virtual
        onlyProject
        whenNotPaused
        whenRefundPeriodIsOver
        whenSaleNotCanceled
        whenSaleResultsArePublished
        whenTokensSupplied
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
    function claimTokenAllocation(
        uint256 amount,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes32[] calldata proof
    )
        external
        virtual
        whenNotPaused
        whenSaleNotCanceled
        whenRefundPeriodIsOver
        whenSaleResultsArePublished
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the vesting configuration is valid
        _verifyValidVestingConfig(investorVestingConfig);

        // Verify that the investor is eligible to claim the requested amount
        _verifyCanClaimTokenAllocation(msg.sender, amount, investorVestingConfig, proof);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Cache Legion Sale Address Configuration
        LegionSaleAddressConfiguration memory addressConfig = s_addressConfig;

        // Mark that the token amount has been settled
        position.hasSettled = true;

        // Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim =
            amount * investorVestingConfig.tokenAllocationOnTGERate / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        // Calculate the remaining amount to be vested
        uint256 amountToBeVested = amount - amountToDistributeOnClaim;

        // Emit TokenAllocationClaimed
        emit TokenAllocationClaimed(amountToBeVested, amountToDistributeOnClaim, msg.sender, positionId);

        // Deploy vesting and distribute tokens only if there is anything to distribute
        if (amountToBeVested != 0) {
            // Deploy a vesting contract for the investor
            address payable vestingAddress = _createVesting(investorVestingConfig, addressConfig.askToken);

            // Save the vesting address for the investor
            position.vestingAddress = vestingAddress;

            // Transfer the allocated amount of tokens for distribution to the vesting contract
            SafeTransferLib.safeTransfer(addressConfig.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            // Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(addressConfig.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /// @inheritdoc ILegionAbstractSale
    function withdrawExcessInvestedCapital(
        uint256 amount,
        bytes32[] calldata proof
    )
        external
        virtual
        whenNotPaused
        whenSaleNotCanceled
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the investor is eligible to get excess capital back
        _verifyCanClaimExcessCapital(msg.sender, positionId, amount, proof);

        // Mark that the excess capital has been returned
        s_investorPositions[positionId].hasClaimedExcess = true;

        // Decrement the total invested capital for the investor
        s_investorPositions[positionId].investedCapital -= amount;

        // Decrement total capital invested from all investors
        s_saleStatus.totalCapitalInvested -= amount;

        // Emit ExcessCapitalWithdrawn
        emit ExcessCapitalWithdrawn(amount, msg.sender, positionId);

        // Transfer the excess capital back to the investor
        if (amount > 0) SafeTransferLib.safeTransfer(s_addressConfig.bidToken, msg.sender, amount);
    }

    /// @inheritdoc ILegionAbstractSale
    function releaseVestedTokens() external virtual whenNotPaused {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Get the investor vesting address
        address investorVestingAddress = s_investorPositions[positionId].vestingAddress;

        // Revert in case there's no vesting for the investor
        if (investorVestingAddress == address(0)) revert Errors.LegionSale__ZeroAddressProvided();

        // Release tokens to the investor account
        ILegionVesting(investorVestingAddress).release(s_addressConfig.askToken);
    }

    /// @inheritdoc ILegionAbstractSale
    function supplyTokens(
        uint256 amount,
        uint256 legionFee,
        uint256 referrerFee
    )
        external
        virtual
        onlyProject
        whenNotPaused
        whenSaleNotCanceled
        whenTokensNotSupplied
    {
        // Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        // Flag that tokens have been supplied
        s_saleStatus.tokensSupplied = true;

        // Cache Legion Sale Configuration
        LegionSaleConfiguration memory saleConfig = s_saleConfig;

        // Calculate the expected Legion Fee amount
        uint256 expectedLegionFeeAmount =
            (saleConfig.legionFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate the expected Referrer Fee amount
        uint256 expectedReferrerFeeAmount =
            (saleConfig.referrerFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        // Verify Legion Fee amount
        if (legionFee != expectedLegionFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(legionFee, expectedLegionFeeAmount);
        }

        // Verify Referrer Fee amount
        if (referrerFee != expectedReferrerFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(referrerFee, expectedReferrerFeeAmount);
        }

        // Emit TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        // Cache Legion Sale Address Configuration
        LegionSaleAddressConfiguration memory addressConfig = s_addressConfig;

        // Transfer the allocated amount of tokens for distribution
        SafeTransferLib.safeTransferFrom(addressConfig.askToken, msg.sender, address(this), amount);

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(
                addressConfig.askToken, msg.sender, addressConfig.legionFeeReceiver, legionFee
            );
        }

        // Transfer the Referrer fee to the Referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                addressConfig.askToken, msg.sender, addressConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /// @inheritdoc ILegionAbstractSale
    function setAcceptedCapital(bytes32 merkleRoot) external virtual onlyLegion whenSaleNotCanceled {
        // Set the merkle root for accepted capital
        s_saleStatus.acceptedCapitalMerkleRoot = merkleRoot;

        // Emit AcceptedCapitalSet
        emit AcceptedCapitalSet(merkleRoot);
    }

    /// @inheritdoc ILegionAbstractSale
    function withdrawInvestedCapitalIfCanceled() external virtual whenNotPaused whenSaleCanceled {
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

        // Emit CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToWithdraw, msg.sender);

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

    /// @inheritdoc LegionPositionManager
    function transferInvestorPosition(
        address from,
        address to,
        uint256 positionId
    )
        external
        virtual
        override
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
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
        whenRefundPeriodIsOver
        whenSaleResultsNotPublished
    {
        // Verify the signature for transferring the position
        _verifyTransferSignature(from, to, positionId, s_addressConfig.legionSigner, transferSignature);

        // Verify that the position can be transferred
        _verifyCanTransferInvestorPosition(positionId);

        // Burn or transfer the investor position
        _burnOrTransferInvestorPosition(from, to, positionId);
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
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investor);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        return s_investorPositions[positionId];
    }

    /// @inheritdoc ILegionAbstractSale
    function investorVestingStatus(address investor)
        external
        view
        virtual
        returns (LegionInvestorVestingStatus memory vestingStatus)
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investor);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Get the investor vesting address
        address investorVestingAddress = s_investorPositions[positionId].vestingAddress;

        // Get the ask token address
        address askTokenAddress = s_addressConfig.askToken;

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

    /// @inheritdoc ILegionAbstractSale
    function cancel() public virtual onlyProject whenNotPaused whenSaleResultsNotPublished whenSaleNotCanceled {
        // Mark the sale as canceled
        s_saleStatus.isCanceled = true;

        // Emit SaleCanceled
        emit SaleCanceled();
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
        s_saleConfig.legionFeeOnTokensSoldBps = _saleInitParams.legionFeeOnTokensSoldBps;
        s_saleConfig.referrerFeeOnCapitalRaisedBps = _saleInitParams.referrerFeeOnCapitalRaisedBps;
        s_saleConfig.referrerFeeOnTokensSoldBps = _saleInitParams.referrerFeeOnTokensSoldBps;
        s_saleConfig.minimumInvestAmount = _saleInitParams.minimumInvestAmount;

        // Set the address configuration
        s_addressConfig.bidToken = _saleInitParams.bidToken;
        s_addressConfig.askToken = _saleInitParams.askToken;
        s_addressConfig.projectAdmin = _saleInitParams.projectAdmin;
        s_addressConfig.addressRegistry = _saleInitParams.addressRegistry;
        s_addressConfig.referrerFeeReceiver = _saleInitParams.referrerFeeReceiver;

        // Initialize pre-liquid sale soulbound token configuration
        s_positionManagerConfig.name = _saleInitParams.saleName;
        s_positionManagerConfig.symbol = _saleInitParams.saleSymbol;
        s_positionManagerConfig.baseURI = _saleInitParams.saleBaseURI;

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
        s_vestingConfig.vestingFactory = ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(
            Constants.LEGION_VESTING_FACTORY_ID
        );
        s_vestingConfig.vestingController = ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(
            Constants.LEGION_VESTING_CONTROLLER_ID
        );

        // Emit LegionAddressesSynced
        emit LegionAddressesSynced(
            s_addressConfig.legionBouncer,
            s_addressConfig.legionSigner,
            s_addressConfig.legionFeeReceiver,
            s_vestingConfig.vestingFactory,
            s_vestingConfig.vestingController
        );
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

            // Delete the burned position
            delete s_investorPositions[_positionId];

            // Burn the investor position from the `from` address
            _burnInvestorPosition(_from);
        } else {
            // Transfer the investor position to the new address
            _transferInvestorPosition(_from, _to, _positionId);
        }
    }

    /// @dev Verifies investor eligibility to claim token allocation using Merkle proof.
    /// @param _investor The address of the investor.
    /// @param _amount The amount of tokens to claim.
    /// @param _investorVestingConfig The vesting configuration for the investor.
    /// @param _proof The Merkle proof for claim verification.
    function _verifyCanClaimTokenAllocation(
        address _investor,
        uint256 _amount,
        LegionVestingManager.LegionInvestorVestingConfig calldata _investorVestingConfig,
        bytes32[] calldata _proof
    )
        internal
        view
        virtual
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(_investor);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Generate the merkle leaf
        bytes32 leaf =
            keccak256(bytes.concat(keccak256(abi.encode(_investor, _amount, positionId, _investorVestingConfig))));

        // Load the investor position
        InvestorPosition memory position = s_investorPositions[positionId];

        // Verify the merkle proof
        if (!MerkleProofLib.verify(_proof, s_saleStatus.claimTokensMerkleRoot, leaf)) {
            revert Errors.LegionSale__NotInClaimWhitelist(_investor);
        }

        // Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.LegionSale__AlreadySettled(_investor);
    }

    /// @dev Verifies investor eligibility to claim excess capital using Merkle proof.
    /// @param _investor The address of the investor.
    /// @param _positionId The position ID of the investor.
    /// @param _amount The amount of excess capital to claim.
    /// @param _proof The Merkle proof for excess capital verification.
    function _verifyCanClaimExcessCapital(
        address _investor,
        uint256 _positionId,
        uint256 _amount,
        bytes32[] calldata _proof
    )
        internal
        view
        virtual
    {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Check if the investor has already settled their allocation
        if (position.hasClaimedExcess) revert Errors.LegionSale__AlreadyClaimedExcess(_investor);

        // Generate the merkle leaf and verify accepted capital
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, (position.investedCapital - _amount)))));

        // Verify the merkle proof
        if (!MerkleProofLib.verify(_proof, s_saleStatus.acceptedCapitalMerkleRoot, leaf)) {
            revert Errors.LegionSale__CannotWithdrawExcessInvestedCapital(_investor, _amount);
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
        if (
            _saleInitParams.salePeriodSeconds == 0 || _saleInitParams.refundPeriodSeconds == 0
                || bytes(_saleInitParams.saleName).length == 0 || bytes(_saleInitParams.saleSymbol).length == 0
                || bytes(_saleInitParams.saleBaseURI).length == 0
        ) {
            revert Errors.LegionSale__ZeroValueProvided();
        }

        // Check if sale and refund periods are longer than allowed
        if (_saleInitParams.salePeriodSeconds > 12 weeks || _saleInitParams.refundPeriodSeconds > 2 weeks) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }

        // Check if sale and refund periods are shorter than allowed
        if (_saleInitParams.salePeriodSeconds < 1 hours || _saleInitParams.refundPeriodSeconds < 1 hours) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }
    }

    /// @dev Verifies that the invested amount meets the minimum requirement.
    /// @param _amount The amount being invested.
    function _verifyMinimumInvestAmount(uint256 _amount) internal view virtual {
        if (_amount < s_saleConfig.minimumInvestAmount) revert Errors.LegionSale__InvalidInvestAmount(_amount);
    }

    /// @dev Verifies that the sale has not ended.
    function _verifySaleHasNotEnded() internal view virtual {
        if (block.timestamp >= s_saleConfig.endTime) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /// @dev Verifies that the refund period has ended.
    function _verifyRefundPeriodIsOver() internal view virtual {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleConfig.refundEndTime;

        if (block.timestamp < refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies that the refund period is still active.
    function _verifyRefundPeriodIsNotOver() internal view virtual {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleConfig.refundEndTime;

        if (block.timestamp >= refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies that sale results have been published.
    function _verifySaleResultsArePublished() internal view virtual {
        if (s_saleStatus.totalTokensAllocated == 0) revert Errors.LegionSale__SaleResultsNotPublished();
    }

    /// @dev Verifies that sale results have not been published.
    function _verifySaleResultsNotPublished() internal view virtual {
        if (s_saleStatus.totalTokensAllocated != 0) revert Errors.LegionSale__SaleResultsAlreadyPublished();
    }

    /// @dev Verifies conditions for supplying tokens.
    /// @param _amount The amount of tokens to supply.
    function _verifyCanSupplyTokens(uint256 _amount) internal view virtual {
        // Cache the total amount of tokens allocated for distribution
        uint256 totalTokensAllocated = s_saleStatus.totalTokensAllocated;

        // Revert if Legion has not set the total amount of tokens allocated for distribution
        if (totalTokensAllocated == 0) revert Errors.LegionSale__TokensNotAllocated();

        // Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != totalTokensAllocated) {
            revert Errors.LegionSale__InvalidTokenAmountSupplied(_amount, totalTokensAllocated);
        }
    }

    /// @dev Verifies conditions for publishing sale results.
    function _verifyCanPublishSaleResults() internal view virtual {
        if (s_saleStatus.totalTokensAllocated != 0) revert Errors.LegionSale__TokensAlreadyAllocated();
    }

    /// @dev Verifies that the sale is not canceled.
    function _verifySaleNotCanceled() internal view virtual {
        if (s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsCanceled();
    }

    /// @dev Verifies that the sale is canceled.
    function _verifySaleIsCanceled() internal view virtual {
        if (!s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsNotCanceled();
    }

    /// @dev Verifies that tokens have not been supplied.
    function _verifyTokensNotSupplied() internal view virtual {
        if (s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensAlreadySupplied();
    }

    /// @dev Verifies that tokens have been supplied.
    function _verifyTokensSupplied() internal view virtual {
        if (!s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensNotSupplied();
    }

    /// @dev Verifies that an investment signature is valid.
    /// @param _signature The signature to verify.
    function _verifyInvestSignature(bytes calldata _signature) internal view virtual {
        bytes32 _data = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid)).toEthSignedMessageHash();

        if (_data.recover(_signature) != s_addressConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_signature);
        }
    }

    /// @dev Verifies conditions for withdrawing capital.
    function _verifyCanWithdrawCapital() internal view virtual {
        // Load the sale status
        LegionSaleStatus memory _saleStatus = s_saleStatus;

        if (_saleStatus.capitalWithdrawn) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        if (_saleStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalNotRaised();
    }

    /// @dev Verifies that the investor has not refunded.
    /// @param _positionId The ID of the investor's position.
    function _verifyHasNotRefunded(uint256 _positionId) internal view virtual {
        if (s_investorPositions[_positionId].hasRefunded) revert Errors.LegionSale__InvestorHasRefunded(msg.sender);
    }

    /// @dev Verifies that the investor has not claimed excess capital.
    /// @param _positionId The ID of the investor's position.
    function _verifyHasNotClaimedExcess(uint256 _positionId) internal view virtual {
        if (s_investorPositions[_positionId].hasClaimedExcess) {
            revert Errors.LegionSale__InvestorHasClaimedExcess(msg.sender);
        }
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
