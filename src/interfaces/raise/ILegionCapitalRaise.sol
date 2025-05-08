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

/**
 * @title ILegionCapitalRaise
 * @author Legion
 * @notice Interface for managing raising capital for sales of ERC20 tokens before TGE in the Legion Protocol
 * @dev Defines events, structs, and functions for pre-liquid capital raise operations including investment, refunds,
 * and withdrawals
 */
interface ILegionCapitalRaise {
    /**
     * @notice Emitted when capital is successfully invested in the pre-liquid capital raise
     * @dev Logs investment details including token allocation rate
     * @param amount Amount of capital invested (in bid tokens)
     * @param investor Address of the investor
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investTimestamp Unix timestamp (in seconds) of the investment
     */
    event CapitalInvested(uint256 amount, address investor, uint256 tokenAllocationRate, uint256 investTimestamp);

    /**
     * @notice Emitted when excess capital is successfully withdrawn by an investor
     * @dev Logs withdrawal details including token allocation rate
     * @param amount Amount of excess capital withdrawn
     * @param investor Address of the investor
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investTimestamp Unix timestamp (in seconds) of the withdrawal
     */
    event ExcessCapitalWithdrawn(
        uint256 amount, address investor, uint256 tokenAllocationRate, uint256 investTimestamp
    );

    /**
     * @notice Emitted when capital is successfully refunded to an investor
     * @dev Logs refund details during the refund period
     * @param amount Amount of capital refunded
     * @param investor Address of the investor receiving the refund
     */
    event CapitalRefunded(uint256 amount, address investor);

    /**
     * @notice Emitted when capital is refunded after capital raise cancellation
     * @dev Logs refund details post-cancellation
     * @param amount Amount of capital refunded
     * @param investor Address of the investor receiving the refund
     */
    event CapitalRefundedAfterCancel(uint256 amount, address investor);

    /**
     * @notice Emitted when capital is successfully withdrawn by the Project
     * @dev Logs total capital withdrawn by the project admin
     * @param amount Total amount of capital withdrawn
     */
    event CapitalWithdrawn(uint256 amount);

    /**
     * @notice Emitted when the total capital raised is published by Legion
     * @dev Logs the finalized capital raised amount
     * @param capitalRaised Total capital raised by the project
     */
    event CapitalRaisedPublished(uint256 capitalRaised);

    /**
     * @notice Emitted during an emergency withdrawal by Legion
     * @dev Logs details of emergency token withdrawal
     * @param receiver Address receiving the withdrawn tokens
     * @param token Address of the token withdrawn
     * @param amount Amount of tokens withdrawn
     */
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /**
     * @notice Emitted when Legion addresses are successfully synced
     * @dev Logs updated addresses from the address registry
     * @param legionBouncer Updated Legion bouncer address
     * @param legionSigner Updated Legion signer address
     * @param legionFeeReceiver Updated Legion fee receiver address
     */
    event LegionAddressesSynced(address legionBouncer, address legionSigner, address legionFeeReceiver);

    /**
     * @notice Emitted when the capital raise is successfully canceled
     * @dev Indicates the capital raise has been terminated by the Project
     */
    event CapitalRaiseCanceled();

    /**
     * @notice Emitted when the capital raise has ended
     * @dev Logs the end timestamp of the capital raise
     * @param endTime Unix timestamp (in seconds) when the capital raise ended
     */
    event CapitalRaiseEnded(uint256 endTime);

    /// @notice Struct defining initialization parameters for the pre-liquid capital raise
    struct CapitalRaiseInitializationParams {
        /// @notice Duration of the refund period in seconds
        /// @dev Time window for investors to request refunds
        uint256 refundPeriodSeconds;
        /// @notice Legion's fee on capital raised in basis points (BPS)
        /// @dev Percentage fee applied to raised capital
        uint256 legionFeeOnCapitalRaisedBps;
        /// @notice Referrer's fee on capital raised in basis points (BPS)
        /// @dev Percentage fee for referrer on raised capital
        uint256 referrerFeeOnCapitalRaisedBps;
        /// @notice Address of the token used for raising capital
        /// @dev Bid token address
        address bidToken;
        /// @notice Admin address of the project raising capital
        /// @dev Project admin address
        address projectAdmin;
        /// @notice Address of Legion's Address Registry contract
        /// @dev Source of Legion-related addresses
        address addressRegistry;
        /// @notice Address of the referrer fee receiver
        /// @dev Destination for referrer fees
        address referrerFeeReceiver;
    }

    /// @notice Struct containing the runtime configuration of the pre-liquid capital raise
    struct CapitalRaiseConfig {
        /// @notice Duration of the refund period in seconds
        /// @dev Time window for refunds
        uint256 refundPeriodSeconds;
        /// @notice Legion's fee on capital raised in basis points (BPS)
        /// @dev Fee percentage on capital
        uint256 legionFeeOnCapitalRaisedBps;
        /// @notice Referrer's fee on capital raised in basis points (BPS)
        /// @dev Referrer fee on capital
        uint256 referrerFeeOnCapitalRaisedBps;
        /// @notice Address of the token used for raising capital
        /// @dev Bid token address
        address bidToken;
        /// @notice Admin address of the project raising capital
        /// @dev Project admin address
        address projectAdmin;
        /// @notice Address of Legion's Address Registry contract
        /// @dev Registry address
        address addressRegistry;
        /// @notice Address of the Legion Bouncer contract
        /// @dev Access control address
        address legionBouncer;
        /// @notice Signer address of Legion
        /// @dev Address for signature verification
        address legionSigner;
        /// @notice Address of Legion's fee receiver
        /// @dev Destination for Legion fees
        address legionFeeReceiver;
        /// @notice Address of the referrer fee receiver
        /// @dev Destination for referrer fees
        address referrerFeeReceiver;
    }

    /// @notice Struct tracking the current status of the pre-liquid capital raise
    struct CapitalRaiseStatus {
        /// @notice Total capital invested by investors
        /// @dev Aggregate investment amount
        uint256 totalCapitalInvested;
        /// @notice Total capital raised from the capital raise
        /// @dev Final raised amount
        uint256 totalCapitalRaised;
        /// @notice Total capital withdrawn by the Project
        /// @dev Amount withdrawn by project
        uint256 totalCapitalWithdrawn;
        /// @notice End time of the capital raise
        /// @dev Unix timestamp of capital raise end
        uint256 endTime;
        /// @notice Refund end time of the capital raise
        /// @dev Unix timestamp of refund period end
        uint256 refundEndTime;
        /// @notice Indicates if the capital raise has been canceled
        /// @dev Cancellation status
        bool isCanceled;
        /// @notice Indicates if the capital raise has ended
        /// @dev End status
        bool hasEnded;
    }

    /// @notice Struct representing an investor's position in the capital raise
    struct InvestorPosition {
        /// @notice Total capital invested by the investor
        /// @dev Invested amount in bid tokens
        uint256 investedCapital;
        /// @notice Amount of capital allowed per SAFT
        /// @dev Cached SAFT investment limit
        uint256 cachedInvestAmount;
        /// @notice Token allocation rate as percentage of total supply (18 decimals)
        /// @dev Cached allocation rate
        uint256 cachedTokenAllocationRate;
        /// @notice Flag indicating if investor has refunded
        /// @dev Refund status
        bool hasRefunded;
        /// @notice Flag indicating if investor has settled tokens
        /// @dev Settlement status
        bool hasSettled;
        /// @notice Address of the investor's vesting contract
        /// @dev Vesting contract address
        address vestingAddress;
    }

    /// @notice Enum defining possible actions during the capital raise
    enum CapitalRaiseAction {
        INVEST, // Investing capital
        WITHDRAW_EXCESS_CAPITAL // Withdrawing excess capital

    }

    /**
     * @notice Initializes the pre-liquid capital raise with parameters
     * @dev Must be implemented to set up capital raise configuration; callable only once
     * @param preLiquidSaleInitParams Calldata struct with initialization parameters
     */
    function initialize(CapitalRaiseInitializationParams calldata preLiquidSaleInitParams) external;

    /**
     * @notice Allows investment into the pre-liquid capital raise
     * @dev Must verify eligibility and update investor position
     * @param amount Amount of capital to invest
     * @param investAmount Maximum allowed investment per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investSignature Signature verifying investor eligibility
     */
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes memory investSignature
    )
        external;

    /**
     * @notice Processes a refund request during the refund period
     * @dev Must return invested capital if conditions are met
     */
    function refund() external;

    /**
     * @notice Performs an emergency withdrawal of tokens
     * @dev Must be restricted to Legion; used for safety measures
     * @param receiver Address to receive tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /**
     * @notice Withdraws raised capital to the Project
     * @dev Must be restricted to Project; handles capital and fees
     */
    function withdrawRaisedCapital() external;

    /**
     * @notice Cancels the pre-liquid capital raise
     * @dev Must be restricted to Project; handles cancellation logic
     */
    function cancelRaise() external;

    /**
     * @notice Withdraws invested capital if the capital raise is canceled
     * @dev Must return capital to investors post-cancellation
     */
    function withdrawInvestedCapitalIfCanceled() external;

    /**
     * @notice Withdraws excess invested capital back to investors
     * @dev Must update position and transfer excess; requires signature
     * @param amount Amount of excess capital to withdraw
     * @param investAmount Maximum allowed investment per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investSignature Signature verifying eligibility
     */
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes memory investSignature
    )
        external;

    /**
     * @notice Ends the pre-liquid capital raise manually
     * @dev Must set capital raise end times and status
     */
    function endRaise() external;

    /**
     * @notice Publishes the total capital raised
     * @dev Must be restricted to Legion; sets final capital amount
     * @param capitalRaised Total capital raised by the project
     */
    function publishCapitalRaised(uint256 capitalRaised) external;

    /**
     * @notice Syncs Legion addresses from the address registry
     * @dev Must update configuration with latest addresses
     */
    function syncLegionAddresses() external;

    /**
     * @notice Pauses the pre-liquid capital raise
     * @dev Must halt capital raise operations
     */
    function pauseRaise() external;

    /**
     * @notice Unpauses the pre-liquid capital raise
     * @dev Must resume capital raise operations
     */
    function unpauseRaise() external;

    /**
     * @notice Retrieves the current capital raise configuration
     * @dev Must return the CapitalRaiseConfig struct
     * @return CapitalRaiseConfig memory Struct containing capital raise configuration
     */
    function raiseConfiguration() external view returns (CapitalRaiseConfig memory);

    /**
     * @notice Retrieves the current capital raise status
     * @dev Must return the CapitalRaiseStatus struct
     * @return CapitalRaiseStatus memory Struct containing capital raise status
     */
    function raiseStatusDetails() external view returns (CapitalRaiseStatus memory);

    /**
     * @notice Retrieves an investor's position details
     * @dev Must return the InvestorPosition struct for the specified address
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);
}
