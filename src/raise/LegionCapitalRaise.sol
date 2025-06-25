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
 * @notice A contract used to raise capital for sales of ERC20 tokens before TGE
 * @dev Manages pre-liquid capital raise lifecycle including investment, refunds, and withdrawals
 */
contract LegionCapitalRaise is ILegionCapitalRaise, LegionPositionManager, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the pre-liquid capital raise configuration
    /// @dev Stores capital raise parameters and settings
    CapitalRaiseConfig private s_capitalRaiseConfig;

    /// @notice Struct tracking the current capital raise status
    /// @dev Maintains runtime state of the capital raise
    CapitalRaiseStatus private s_capitalRaiseStatus;

    /// @notice Mapping of position ids to their positions
    /// @dev Investor position data
    mapping(uint256 s_positionId => InvestorPosition s_investorPosition) private s_investorPositions;

    /// @notice Mapping to track used signatures per investor
    /// @dev Nested mapping for signature usage status
    mapping(address s_investorAddress => mapping(bytes s_signature => bool s_used) s_usedSignature) private
        s_usedSignatures;

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to the Legion address only
     * @dev Reverts if caller is not the configured Legion bouncer address
     */
    modifier onlyLegion() {
        if (msg.sender != s_capitalRaiseConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /**
     * @notice Restricts function access to the Project admin only
     * @dev Reverts if caller is not the configured project admin address
     */
    modifier onlyProject() {
        if (msg.sender != s_capitalRaiseConfig.projectAdmin) revert Errors.LegionSale__NotCalledByProject();
        _;
    }

    /**
     * @notice Restricts function access to either Legion or Project admin
     * @dev Reverts if caller is neither the project admin nor Legion bouncer
     */
    modifier onlyLegionOrProject() {
        if (msg.sender != s_capitalRaiseConfig.projectAdmin && msg.sender != s_capitalRaiseConfig.legionBouncer) {
            revert Errors.LegionSale__NotCalledByLegionOrProject();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for LegionCapitalRaise
     * @dev Disables initializers to prevent uninitialized deployment
     */
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the capital raise contract with parameters
     * @dev Sets up capital raise configuration
     * @param capitalRaiseInitParams Calldata struct with capital raise initialization parameters
     */
    function initialize(CapitalRaiseInitializationParams calldata capitalRaiseInitParams) external initializer {
        _setLegionCapitalRaiseConfig(capitalRaiseInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows an investor to contribute capital to the capital raise
     * @dev Verifies conditions and updates state
     * @param amount Amount of capital to invest
     * @param investAmount Maximum capital allowed
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investSignature Signature verifying investor eligibility
     */
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata investSignature
    )
        external
        whenNotPaused
    {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the capital raise is not canceled
        _verifyCapitalRaisedNotCanceled();

        // Verify that the capital raise has not ended
        _verifyCapitalRaiseHasNotEnded();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the invest signature has not been used
        _verifySignatureNotUsed(investSignature);

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

        // Emit successfully CapitalInvested
        emit CapitalInvested(amount, msg.sender, positionId);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_capitalRaiseConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Processes a refund for an investor during the refund period
     * @dev Transfers invested capital back to the investor if conditions are met
     */
    function refund() external whenNotPaused {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the capital raise is not canceled
        _verifyCapitalRaisedNotCanceled();

        // Verify that the refund period is not over
        _verifyRefundPeriodIsNotOver();

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

        // Emit successfully CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender, positionId);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_capitalRaiseConfig.bidToken, msg.sender, amountToRefund);
    }

    /**
     * @notice Withdraws tokens in emergency situations
     * @dev Restricted to Legion; used for safety measures
     * @param receiver Address to receive withdrawn tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        // Emit successfully EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /**
     * @notice Withdraws raised capital to the Project
     * @dev Transfers capital and fees; restricted to Project
     */
    function withdrawRaisedCapital() external onlyProject whenNotPaused {
        // Verify that the capital raise is not canceled
        _verifyCapitalRaisedNotCanceled();

        // Verify that the capital raise has ended
        _verifyCapitalRaiseHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

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

        // Emit successfully CapitalWithdrawn
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

    /**
     * @notice Cancels the capital raise and handles capital return
     * @dev Restricted to Project; reverts if capital raise is canceled
     */
    function cancelSale() external onlyProject whenNotPaused {
        // Verify that the capital raise has not been canceled
        _verifyCapitalRaisedNotCanceled();

        // Cache the amount of funds to be returned to the capital raise
        // The project should return the total capital raised including the charged fees
        uint256 capitalToReturn = s_capitalRaiseStatus.totalCapitalWithdrawn;

        // Mark the capital raise as canceled
        s_capitalRaiseStatus.isCanceled = true;

        // Emit successfully CapitalRaiseCanceled
        emit CapitalRaiseCanceled();

        // In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            // Set the totalCapitalWithdrawn to zero
            s_capitalRaiseStatus.totalCapitalWithdrawn = 0;
            // Transfer the raised capital back to the contract
            SafeTransferLib.safeTransferFrom(s_capitalRaiseConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /**
     * @notice Allows investors to withdraw capital if capital raise is canceled
     * @dev Transfers invested capital back to investor
     */
    function withdrawInvestedCapitalIfCanceled() external whenNotPaused {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the capital raise has been canceled
        _verifyCapitalRaiseIsCanceled();

        // Cache the amount to refund in memory
        uint256 amountToClaim = s_investorPositions[positionId].investedCapital;

        // Revert in case there's nothing to claim
        if (amountToClaim == 0) revert Errors.LegionSale__InvalidWithdrawAmount(0);

        // Set the total invested capital for the investor to 0
        s_investorPositions[positionId].investedCapital = 0;

        // Decrement total capital invested from all investors
        s_capitalRaiseStatus.totalCapitalInvested -= amountToClaim;

        // Emit successfully CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToClaim, msg.sender, positionId);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_capitalRaiseConfig.bidToken, msg.sender, amountToClaim);
    }

    /**
     * @notice Withdraws excess invested capital back to investors
     * @dev Updates position and transfers excess; requires signature
     * @param amount Amount of excess capital to withdraw
     * @param investAmount Maximum capital allowed
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param claimExcessSignature Signature verifying eligibility to claim excess capital
     */
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata claimExcessSignature
    )
        external
        whenNotPaused
    {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the capital raise has not been canceled
        _verifyCapitalRaisedNotCanceled();

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

        // Emit successfully ExcessCapitalWithdrawn
        emit ExcessCapitalWithdrawn(amount, msg.sender, positionId);

        // Transfer the excess capital to the investor
        SafeTransferLib.safeTransfer(s_capitalRaiseConfig.bidToken, msg.sender, amount);
    }

    /**
     * @notice Ends the capital raise manually
     * @dev Sets end times; restricted to Legion or Project
     */
    function endSale() external onlyLegionOrProject whenNotPaused {
        // Verify that the capital raise has not ended
        _verifyCapitalRaiseHasNotEnded();

        // Verify that the capital raise has not been canceled
        _verifyCapitalRaisedNotCanceled();

        // Update the `hasEnded` status to ture
        s_capitalRaiseStatus.hasEnded = true;

        // Set the `endTime` of the capital raise
        s_capitalRaiseStatus.endTime = uint64(block.timestamp);

        // Set the `refundEndTime` of the capital raise
        s_capitalRaiseStatus.refundEndTime = uint64(block.timestamp) + s_capitalRaiseConfig.refundPeriodSeconds;

        // Emit successfully CapitalRaiseEnded
        emit CapitalRaiseEnded();
    }

    /**
     * @notice Publishes the total capital raised
     * @dev Sets capital raised; restricted to Legion
     * @param capitalRaised Total capital raised by the project
     */
    function publishCapitalRaised(uint256 capitalRaised) external onlyLegion whenNotPaused {
        // Verify that the capital raise is not canceled
        _verifyCapitalRaisedNotCanceled();

        // Verify that the capital raise has ended
        _verifyCapitalRaiseHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that capital raised can be published.
        _verifyCanPublishCapitalRaised();

        // Set the total capital raised to be withdrawn by the project
        s_capitalRaiseStatus.totalCapitalRaised = capitalRaised;

        // Emit successfully CapitalRaisedPublished
        emit CapitalRaisedPublished(capitalRaised);
    }

    /**
     * @notice Transfers an investor position from one address to another
     * @dev Allow transfers only between end of refund period and before TGE
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     */
    function transferInvestorPosition(
        address from,
        address to,
        uint256 positionId
    )
        external
        override
        onlyLegion
        whenNotPaused
    {
        // Verify that the capital raise is not canceled
        _verifyCapitalRaisedNotCanceled();

        // Verify that the capital raise has ended
        _verifyCapitalRaiseHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that the position can be transferred
        _verifyCanTransferInvestorPosition(positionId);

        // Burn or transfer the investor position
        _burnOrTransferInvestorPosition(from, to, positionId);
    }

    /**
     * @notice Transfers an investor position with authorization by Legion
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     * @param signature The signature authorizing the transfer
     */
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
    {
        // Verify that the capital raise is not canceled
        _verifyCapitalRaisedNotCanceled();

        // Verify that the capital raise has ended
        _verifyCapitalRaiseHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify the signature for transferring the position
        _verifyTransferSignature(from, to, positionId, s_capitalRaiseConfig.legionSigner, signature);

        // Verify that the position can be transferred
        _verifyCanTransferInvestorPosition(positionId);

        // Burn or transfer the investor position
        _burnOrTransferInvestorPosition(from, to, positionId);
    }

    /**
     * @notice Syncs Legion addresses from the address registry
     * @dev Updates configuration with latest addresses; restricted to Legion
     */
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /**
     * @notice Pauses the capital raise
     * @dev Triggers Pausable pause; restricted to Legion
     */
    function pauseSale() external virtual onlyLegion {
        // Pause the capital raise
        _pause();
    }

    /**
     * @notice Unpauses the capital raise
     * @dev Triggers Pausable unpause; restricted to Legion
     */
    function unpauseSale() external virtual onlyLegion {
        // Unpause the capital raise
        _unpause();
    }

    /**
     * @notice Returns the current capital raise configuration
     * @dev Provides read-only access to s_capitalRaiseConfig
     * @return CapitalRaiseConfig memory Struct containing capital raise configuration
     */
    function saleConfiguration() external view returns (CapitalRaiseConfig memory) {
        return s_capitalRaiseConfig;
    }

    /**
     * @notice Returns the current capital raise status
     * @dev Provides read-only access to s_capitalRaiseStatus
     * @return CapitalRaiseStatus memory Struct containing capital raise status
     */
    function saleStatusDetails() external view returns (CapitalRaiseStatus memory) {
        return s_capitalRaiseStatus;
    }

    /**
     * @notice Returns an investor's position details
     * @dev Provides read-only access to investor position
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory) {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investorAddress);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        return s_investorPositions[positionId];
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the capital raise parameters during initialization
     * @dev Internal function to configure capital raise
     * @param preLiquidSaleInitParams Calldata struct with initialization parameters
     */
    function _setLegionCapitalRaiseConfig(CapitalRaiseInitializationParams calldata preLiquidSaleInitParams)
        private
        onlyInitializing
    {
        // Verify if the capital raise configuration is valid
        _verifyValidConfig(preLiquidSaleInitParams);

        // Initialize the capital raise configuration
        s_capitalRaiseConfig.refundPeriodSeconds = preLiquidSaleInitParams.refundPeriodSeconds;
        s_capitalRaiseConfig.legionFeeOnCapitalRaisedBps = preLiquidSaleInitParams.legionFeeOnCapitalRaisedBps;
        s_capitalRaiseConfig.referrerFeeOnCapitalRaisedBps = preLiquidSaleInitParams.referrerFeeOnCapitalRaisedBps;
        s_capitalRaiseConfig.bidToken = preLiquidSaleInitParams.bidToken;
        s_capitalRaiseConfig.projectAdmin = preLiquidSaleInitParams.projectAdmin;
        s_capitalRaiseConfig.addressRegistry = preLiquidSaleInitParams.addressRegistry;
        s_capitalRaiseConfig.referrerFeeReceiver = preLiquidSaleInitParams.referrerFeeReceiver;

        // Initialize pre-liquid sale solbound token configuration
        s_positionManagerConfig.name = preLiquidSaleInitParams.saleName;
        s_positionManagerConfig.symbol = preLiquidSaleInitParams.saleSymbol;
        s_positionManagerConfig.baseURI = preLiquidSaleInitParams.saleBaseURI;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /**
     * @notice Syncs Legion addresses from the registry
     * @dev Updates configuration with latest addresses; virtual for overrides
     */
    function _syncLegionAddresses() private {
        // Cache Legion addresses from `LegionAddressRegistry`
        s_capitalRaiseConfig.legionBouncer =
            ILegionAddressRegistry(s_capitalRaiseConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        s_capitalRaiseConfig.legionSigner =
            ILegionAddressRegistry(s_capitalRaiseConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        s_capitalRaiseConfig.legionFeeReceiver = ILegionAddressRegistry(s_capitalRaiseConfig.addressRegistry)
            .getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);

        // Emit successfully LegionAddressesSynced
        emit LegionAddressesSynced(
            s_capitalRaiseConfig.legionBouncer,
            s_capitalRaiseConfig.legionSigner,
            s_capitalRaiseConfig.legionFeeReceiver
        );
    }

    /**
     * @notice Updates an investor's position
     * @dev Caches investment and allocation details
     * @param investAmount Maximum capital allowed to invest
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     */
    function _updateInvestorPosition(uint256 investAmount, uint256 tokenAllocationRate) private {
        // Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        // Verify that the position exists
        _verifyPositionExists(positionId);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Cache the SAFT amount the investor is allowed to invest
        if (position.cachedInvestAmount != investAmount) {
            position.cachedInvestAmount = investAmount;
        }

        // Cache the token allocation rate in 18 decimals precision
        if (position.cachedTokenAllocationRate != tokenAllocationRate) {
            position.cachedTokenAllocationRate = tokenAllocationRate;
        }
    }

    /**
     * @notice Burns or transfers an investor position based on conditions
     * @dev Handles position transfer logic; burns if receiver already has a position
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position to transfer or burn
     */
    function _burnOrTransferInvestorPosition(address from, address to, uint256 positionId) private {
        // Get the position ID of the receiver
        uint256 positionIdTo = s_investorPositionIds[to];

        // If the receiver already has a position, burn the transferred position
        // and update the existing position
        if (positionIdTo != 0) {
            // Load the investor positions
            InvestorPosition memory positionToBurn = s_investorPositions[positionId];
            InvestorPosition storage positionToUpdate = s_investorPositions[positionIdTo];

            // Update the existing position with the transferred values
            positionToUpdate.investedCapital += positionToBurn.investedCapital;
            positionToUpdate.cachedTokenAllocationRate += positionToBurn.cachedTokenAllocationRate;
            positionToUpdate.cachedInvestAmount += positionToBurn.cachedInvestAmount;

            // Delete the burned position
            delete s_investorPositions[positionId];

            // Burn the investor position from the `from` address
            _burnInvestorPosition(from);
        } else {
            // Transfer the investor position to the new address
            _transferInvestorPosition(from, to, positionId);
        }
    }

    /**
     * @notice Validates the capital raise configuration parameters
     * @dev Checks for invalid values and addresses
     * @param _preLiquidSaleInitParams Calldata struct with initialization parameters
     */
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

    /**
     * @notice Ensures the capital raise is not canceled
     * @dev Reverts if capital raise is marked as canceled
     */
    function _verifyCapitalRaisedNotCanceled() internal view {
        if (s_capitalRaiseStatus.isCanceled) revert Errors.LegionSale__SaleIsCanceled();
    }

    /**
     * @notice Ensures the capital raise is canceled
     * @dev Reverts if capital raise is not marked as canceled
     */
    function _verifyCapitalRaiseIsCanceled() internal view {
        if (!s_capitalRaiseStatus.isCanceled) revert Errors.LegionSale__SaleIsNotCanceled();
    }

    /**
     * @notice Ensures the capital raise has not ended
     * @dev Reverts if capital raise is marked as ended
     */
    function _verifyCapitalRaiseHasNotEnded() internal view {
        if (s_capitalRaiseStatus.hasEnded) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /**
     * @notice Ensures the capital raise has ended
     * @dev Reverts if capital raise is not marked as ended
     */
    function _verifyCapitalRaiseHasEnded() internal view {
        if (!s_capitalRaiseStatus.hasEnded) revert Errors.LegionSale__SaleHasNotEnded(block.timestamp);
    }

    /**
     * @notice Ensures a signature has not been used
     * @param signature Signature to verify
     */
    function _verifySignatureNotUsed(bytes calldata signature) private view {
        // Check if the signature is used
        if (s_usedSignatures[msg.sender][signature]) revert Errors.LegionSale__SignatureAlreadyUsed(signature);
    }

    /**
     * @notice Verifies conditions for withdrawing capital
     * @dev Ensures capital state allows withdrawal
     */
    function _verifyCanWithdrawCapital() internal view virtual {
        // Load the sale status
        CapitalRaiseStatus memory capitalRaiseStatus = s_capitalRaiseStatus;
        // Check if capital has not been withdrawn
        if (capitalRaiseStatus.totalCapitalWithdrawn > 0) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        // Check if capital raised has been published
        if (capitalRaiseStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalNotRaised();
    }

    /**
     * @notice Ensures the refund period is over
     * @dev Reverts if refund period is still active
     */
    function _verifyRefundPeriodIsOver() internal view {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_capitalRaiseStatus.refundEndTime;
        if (refundEndTime > 0 && block.timestamp < refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, refundEndTime);
        }
    }

    /**
     * @notice Ensures the refund period is not over
     * @dev Reverts if refund period has ended
     */
    function _verifyRefundPeriodIsNotOver() internal view {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_capitalRaiseStatus.refundEndTime;
        if (refundEndTime > 0 && block.timestamp >= refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, refundEndTime);
        }
    }

    /**
     * @notice Ensures the investor has not refunded
     * @param positionId ID of the investor's position
     * @dev Reverts if investor has already refunded; virtual for overrides
     */
    function _verifyHasNotRefunded(uint256 positionId) internal view virtual {
        if (s_investorPositions[positionId].hasRefunded) revert Errors.LegionSale__InvestorHasRefunded(msg.sender);
    }

    /**
     * @notice Verifies conditions for publishing capital raised
     * @dev Ensures capital raised is not already set
     */
    function _verifyCanPublishCapitalRaised() internal view {
        if (s_capitalRaiseStatus.totalCapitalRaised != 0) revert Errors.LegionSale__CapitalRaisedAlreadyPublished();
    }

    /**
     * @notice Validates an investor's position
     * @dev Verifies investment amount and signature
     * @param signature Signature to verify
     * @param positionId ID of the investor's position
     * @param actionType Type of capital raise action being performed
     */
    function _verifyValidPosition(
        bytes calldata signature,
        uint256 positionId,
        CapitalRaiseAction actionType
    )
        internal
        view
    {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[positionId];

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
                actionType
            )
        ).toEthSignedMessageHash();

        // Verify the signature
        if (_data.recover(signature) != s_capitalRaiseConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(signature);
        }
    }

    /**
     * @notice Verifies investor eligibility to claim excess capital
     * @param _positionId Position ID of the investor
     */
    function _verifyCanClaimExcessCapital(uint256 _positionId) internal view virtual {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Check if the investor has already claimed excess capital
        if (position.hasClaimedExcess) revert Errors.LegionSale__AlreadyClaimedExcess(msg.sender);
    }

    /**
     * @notice Verifies conditions for transferring an investor position
     * @dev Ensures position is not refunded
     * @param positionId ID of the investor's position
     */
    function _verifyCanTransferInvestorPosition(uint256 positionId) private view {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[positionId];

        // Verify that the position is not refunded
        if (position.hasRefunded) {
            revert Errors.LegionSale__UnableToTransferInvestorPosition(positionId);
        }
    }
}
