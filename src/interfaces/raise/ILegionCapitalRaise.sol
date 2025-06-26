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
 * @notice Interface for the LegionCapitalRaise contract.
 */
interface ILegionCapitalRaise {
    /// @dev Struct defining initialization parameters for the pre-liquid capital raise
    struct CapitalRaiseInitializationParams {
        // Duration of the refund period in seconds
        uint64 refundPeriodSeconds;
        // Legion's fee on capital raised in basis points (BPS)
        uint16 legionFeeOnCapitalRaisedBps;
        // Referrer's fee on capital raised in basis points (BPS)
        uint16 referrerFeeOnCapitalRaisedBps;
        // Address of the token used for raising capital
        address bidToken;
        // Admin address of the project raising capital
        address projectAdmin;
        // Address of Legion's Address Registry contract
        address addressRegistry;
        // Address of the referrer fee receiver
        address referrerFeeReceiver;
        // Name of the pre-liquid sale soulbound token
        string saleName;
        // Symbol of the pre-liquid sale soulbound token
        string saleSymbol;
        // Base URI for the pre-liquid sale soulbound token
        string saleBaseURI;
    }

    /// @dev Struct containing the runtime configuration of the pre-liquid capital raise
    struct CapitalRaiseConfig {
        // Duration of the refund period in seconds
        uint64 refundPeriodSeconds;
        // Legion's fee on capital raised in basis points (BPS)
        uint16 legionFeeOnCapitalRaisedBps;
        // Referrer's fee on capital raised in basis points (BPS)
        uint16 referrerFeeOnCapitalRaisedBps;
        // Address of the token used for raising capital
        address bidToken;
        // Admin address of the project raising capital
        address projectAdmin;
        // Address of Legion's Address Registry contract
        address addressRegistry;
        // Address of the Legion Bouncer contract
        address legionBouncer;
        // Signer address of Legion
        address legionSigner;
        // Address of Legion's fee receiver
        address legionFeeReceiver;
        // Address of the referrer fee receiver
        address referrerFeeReceiver;
    }

    /// @dev Struct tracking the current status of the pre-liquid capital raise
    struct CapitalRaiseStatus {
        // End time of the capital raise
        uint64 endTime;
        // Refund end time of the capital raise
        uint64 refundEndTime;
        // Indicates if the capital raise has been canceled
        bool isCanceled;
        // Indicates if the capital raise has ended
        bool hasEnded;
        // Total capital invested by investors
        uint256 totalCapitalInvested;
        // Total capital raised from the capital raise
        uint256 totalCapitalRaised;
        // Total capital withdrawn by the Project
        uint256 totalCapitalWithdrawn;
    }

    /// @dev Struct representing an investor's position in the capital raise
    struct InvestorPosition {
        // Flag indicating if investor has claimed excess capital
        bool hasClaimedExcess;
        // Flag indicating if investor has refunded
        bool hasRefunded;
        // Total capital invested by the investor
        uint256 investedCapital;
        // Amount of capital allowed per SAFT
        uint256 cachedInvestAmount;
        // Token allocation rate as percentage of total supply (18 decimals)
        uint256 cachedTokenAllocationRate;
    }

    /// @dev Enum defining possible actions during the capital raise
    enum CapitalRaiseAction {
        INVEST, // Investing capital
        WITHDRAW_EXCESS_CAPITAL // Withdrawing excess capital

    }

    /// @notice Emitted when capital is successfully invested in the pre-liquid capital raise.
    /// @param amount The amount of capital invested (in bid tokens).
    /// @param investor The address of the investor.
    /// @param positionId The unique identifier for the investor's position.
    event CapitalInvested(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when excess capital is successfully withdrawn by an investor.
    /// @param amount The amount of excess capital withdrawn.
    /// @param investor The address of the investor.
    /// @param positionId The unique identifier for the investor's position.
    event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when capital is successfully refunded to an investor.
    /// @param amount The amount of capital refunded.
    /// @param investor The address of the investor receiving the refund.
    /// @param positionId The unique identifier for the investor's position.
    event CapitalRefunded(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when capital is refunded after capital raise cancellation.
    /// @param amount The amount of capital refunded.
    /// @param investor The address of the investor receiving the refund.
    /// @param positionId The unique identifier for the investor's position.
    event CapitalRefundedAfterCancel(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when capital is successfully withdrawn by the project.
    /// @param amount The total amount of capital withdrawn.
    event CapitalWithdrawn(uint256 amount);

    /// @notice Emitted when the total capital raised is published by Legion.
    /// @param capitalRaised The total capital raised by the project.
    event CapitalRaisedPublished(uint256 capitalRaised);

    /// @notice Emitted during an emergency withdrawal by Legion.
    /// @param receiver The address receiving the withdrawn tokens.
    /// @param token The address of the token withdrawn.
    /// @param amount The amount of tokens withdrawn.
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /// @notice Emitted when Legion addresses are successfully synced.
    /// @param legionBouncer The updated Legion bouncer address.
    /// @param legionSigner The updated Legion signer address.
    /// @param legionFeeReceiver The updated Legion fee receiver address.
    event LegionAddressesSynced(address legionBouncer, address legionSigner, address legionFeeReceiver);

    /// @notice Emitted when the capital raise is successfully canceled.
    event CapitalRaiseCanceled();

    /// @notice Emitted when the capital raise has ended.
    event CapitalRaiseEnded();

    /// @notice Initializes the capital raise contract with configuration parameters.
    /// @param capitalRaiseInitParams The initialization parameters for the capital raise.
    function initialize(CapitalRaiseInitializationParams calldata capitalRaiseInitParams) external;

    /// @notice Allows an investor to contribute capital to the capital raise.
    /// @param amount The amount of capital to invest.
    /// @param investAmount The maximum capital allowed for this investor.
    /// @param tokenAllocationRate The token allocation percentage (18 decimals precision).
    /// @param investSignature The signature verifying investor eligibility and terms.
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata investSignature
    )
        external;

    /// @notice Processes a refund for an investor during the refund period.
    function refund() external;

    /// @notice Withdraws tokens in emergency situations.
    /// @param receiver The address to receive the withdrawn tokens.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /// @notice Withdraws raised capital to the project admin.
    function withdrawRaisedCapital() external;

    /// @notice Cancels the capital raise and handles capital return.
    function cancel() external;

    /// @notice Allows investors to withdraw capital if the capital raise is canceled.
    function withdrawInvestedCapitalIfCanceled() external;

    /// @notice Withdraws excess invested capital back to investors.
    /// @param amount The amount of excess capital to withdraw.
    /// @param investAmount The maximum capital allowed for this investor.
    /// @param tokenAllocationRate The token allocation percentage (18 decimals precision).
    /// @param claimExcessSignature The signature verifying eligibility to claim excess capital.
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata claimExcessSignature
    )
        external;

    /// @notice Ends the capital raise manually.
    function end() external;

    /// @notice Publishes the total capital raised amount.
    /// @param capitalRaised The total capital raised by the project.
    function publishRaisedCapital(uint256 capitalRaised) external;

    /// @notice Synchronizes Legion addresses from the address registry.
    function syncLegionAddresses() external;

    /// @notice Pauses all capital raise operations.
    function pause() external;

    /// @notice Resumes all capital raise operations.
    function unpause() external;

    /// @notice Returns the current capital raise configuration.
    /// @return The complete capital raise configuration struct.
    function saleConfiguration() external view returns (CapitalRaiseConfig memory);

    /// @notice Returns the current capital raise status.
    /// @return The complete capital raise status struct.
    function saleStatus() external view returns (CapitalRaiseStatus memory);

    /// @notice Returns an investor's position details.
    /// @param investor The address of the investor.
    /// @return The complete investor position struct.
    function investorPosition(address investor) external view returns (InvestorPosition memory);
}
