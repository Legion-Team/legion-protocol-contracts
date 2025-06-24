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

/**
 * @title ILegionCapitalRaise
 * @author Legion
 * @notice Interface for managing raising capital for sales of ERC20 tokens before TGE in the Legion Protocol
 * @dev Defines events, structs, and functions for pre-liquid capital raise operations including investment, refunds,
 * and withdrawals
 */
interface ILegionCapitalRaise {
    /// @notice Struct defining initialization parameters for the pre-liquid capital raise
    struct CapitalRaiseInitializationParams {
        /// @notice Duration of the refund period in seconds
        /// @dev Time window for investors to request refunds
        uint64 refundPeriodSeconds;
        /// @notice Legion's fee on capital raised in basis points (BPS)
        /// @dev Percentage fee applied to raised capital
        uint16 legionFeeOnCapitalRaisedBps;
        /// @notice Referrer's fee on capital raised in basis points (BPS)
        /// @dev Percentage fee for referrer on raised capital
        uint16 referrerFeeOnCapitalRaisedBps;
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
        /// @notice Name of the pre-liquid sale soulbound token
        /// @dev Name of the SBT representing the sale
        string saleName;
        /// @notice Symbol of the pre-liquid sale soulbound token
        /// @dev Symbol of the SBT representing the sale
        string saleSymbol;
        /// @notice Base URI for the pre-liquid sale soulbound token
        /// @dev URI prefix for the SBT metadata
        string saleBaseURI;
    }

    /// @notice Struct containing the runtime configuration of the pre-liquid capital raise
    struct CapitalRaiseConfig {
        /// @notice Duration of the refund period in seconds
        /// @dev Time window for refunds
        uint64 refundPeriodSeconds;
        /// @notice Legion's fee on capital raised in basis points (BPS)
        /// @dev Fee percentage on capital
        uint16 legionFeeOnCapitalRaisedBps;
        /// @notice Referrer's fee on capital raised in basis points (BPS)
        /// @dev Referrer fee on capital
        uint16 referrerFeeOnCapitalRaisedBps;
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
        /// @notice End time of the capital raise
        /// @dev Unix timestamp of capital raise end
        uint64 endTime;
        /// @notice Refund end time of the capital raise
        /// @dev Unix timestamp of refund period end
        uint64 refundEndTime;
        /// @notice Indicates if the capital raise has been canceled
        /// @dev Cancellation status
        bool isCanceled;
        /// @notice Indicates if the capital raise has ended
        /// @dev End status
        bool hasEnded;
        /// @notice Total capital invested by investors
        /// @dev Aggregate investment amount
        uint256 totalCapitalInvested;
        /// @notice Total capital raised from the capital raise
        /// @dev Final raised amount
        uint256 totalCapitalRaised;
        /// @notice Total capital withdrawn by the Project
        /// @dev Amount withdrawn by project
        uint256 totalCapitalWithdrawn;
    }

    /// @notice Struct representing an investor's position in the capital raise
    struct InvestorPosition {
        /// @notice Flag indicating if investor has claimed excess capital
        /// @dev Excess claim status
        bool hasClaimedExcess;
        /// @notice Flag indicating if investor has refunded
        /// @dev Refund status
        bool hasRefunded;
        /// @notice Total capital invested by the investor
        /// @dev Invested amount in bid tokens
        uint256 investedCapital;
        /// @notice Amount of capital allowed per SAFT
        /// @dev Cached SAFT investment limit
        uint256 cachedInvestAmount;
        /// @notice Token allocation rate as percentage of total supply (18 decimals)
        /// @dev Cached allocation rate
        uint256 cachedTokenAllocationRate;
    }

    /// @notice Enum defining possible actions during the capital raise
    enum CapitalRaiseAction {
        INVEST, // Investing capital
        WITHDRAW_EXCESS_CAPITAL // Withdrawing excess capital

    }

    /**
     * @notice Emitted when capital is successfully invested in the pre-liquid capital raise
     * @param amount Amount of capital invested (in bid tokens)
     * @param investor Address of the investor
     * @param positionId Unique identifier for the investor's position
     */
    event CapitalInvested(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when excess capital is successfully withdrawn by an investor
     * @param amount Amount of excess capital withdrawn
     * @param investor Address of the investor
     * @param positionId Unique identifier for the investor's position
     */
    event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when capital is successfully refunded to an investor
     * @param amount Amount of capital refunded
     * @param investor Address of the investor receiving the refund
     * @param positionId Unique identifier for the investor's position
     */
    event CapitalRefunded(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when capital is refunded after capital raise cancellation
     * @param amount Amount of capital refunded
     * @param investor Address of the investor receiving the refund
     * @param positionId Unique identifier for the investor's position
     */
    event CapitalRefundedAfterCancel(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when capital is successfully withdrawn by the Project
     * @param amount Total amount of capital withdrawn
     */
    event CapitalWithdrawn(uint256 amount);

    /**
     * @notice Emitted when the total capital raised is published by Legion
     * @param capitalRaised Total capital raised by the project
     */
    event CapitalRaisedPublished(uint256 capitalRaised);

    /**
     * @notice Emitted during an emergency withdrawal by Legion
     * @param receiver Address receiving the withdrawn tokens
     * @param token Address of the token withdrawn
     * @param amount Amount of tokens withdrawn
     */
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /**
     * @notice Emitted when Legion addresses are successfully synced
     * @param legionBouncer Updated Legion bouncer address
     * @param legionSigner Updated Legion signer address
     * @param legionFeeReceiver Updated Legion fee receiver address
     */
    event LegionAddressesSynced(address legionBouncer, address legionSigner, address legionFeeReceiver);

    /**
     * @notice Emitted when the capital raise is successfully canceled
     */
    event CapitalRaiseCanceled();

    /**
     * @notice Emitted when the capital raise has ended
     */
    event CapitalRaiseEnded();

    /**
     * @notice Initializes the pre-liquid capital raise with parameters
     * @param preLiquidSaleInitParams Calldata struct with initialization parameters
     */
    function initialize(CapitalRaiseInitializationParams calldata preLiquidSaleInitParams) external;

    /**
     * @notice Allows investment into the pre-liquid capital raise
     * @param amount Amount of capital to invest
     * @param investAmount Maximum allowed investment per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investSignature Signature verifying investor eligibility
     */
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata investSignature
    )
        external;

    /**
     * @notice Processes a refund request during the refund period
     */
    function refund() external;

    /**
     * @notice Performs an emergency withdrawal of tokens
     * @param receiver Address to receive tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /**
     * @notice Withdraws raised capital to the Project
     */
    function withdrawRaisedCapital() external;

    /**
     * @notice Cancels the pre-liquid capital raise
     */
    function cancelSale() external;

    /**
     * @notice Withdraws invested capital if the capital raise is canceled
     */
    function withdrawInvestedCapitalIfCanceled() external;

    /**
     * @notice Withdraws excess invested capital back to investors
     * @param amount Amount of excess capital to withdraw
     * @param investAmount Maximum allowed investment per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param withdrawSignature Signature verifying eligibility
     */
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata withdrawSignature
    )
        external;

    /**
     * @notice Ends the pre-liquid capital raise manually
     */
    function endSale() external;

    /**
     * @notice Publishes the total capital raised
     * @param capitalRaised Total capital raised by the project
     */
    function publishCapitalRaised(uint256 capitalRaised) external;

    /**
     * @notice Syncs Legion addresses from the address registry
     */
    function syncLegionAddresses() external;

    /**
     * @notice Pauses the pre-liquid capital raise
     */
    function pauseSale() external;

    /**
     * @notice Unpauses the pre-liquid capital raise
     */
    function unpauseSale() external;

    /**
     * @notice Retrieves the current capital raise configuration
     * @return CapitalRaiseConfig memory Struct containing capital raise configuration
     */
    function saleConfiguration() external view returns (CapitalRaiseConfig memory);

    /**
     * @notice Retrieves the current capital raise status
     * @return CapitalRaiseStatus memory Struct containing capital raise status
     */
    function saleStatusDetails() external view returns (CapitalRaiseStatus memory);

    /**
     * @notice Retrieves an investor's position details
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);
}
