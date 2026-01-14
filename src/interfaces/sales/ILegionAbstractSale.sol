// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

//       ___       ___           ___                       ___           ___
//      /\__\     /\  \         /\  \          ___        /\  \         /\__/
//     /:/  /    /::\  \       /::\  \        /\  \      /::\  \       /::|  |
//    /:/  /    /:/\:\  \     /:/\:\  \       \:\  \    /:/\:\  \     /:|:|  |
//   /:/  /    /::\~\:\  \   /:/  \:\  \      /::\__\  /:/  \:\  \   /:/|:|  |__
//  /:/__/    /:/\:\ \:\__\ /:/__/_\:\__\  __/:/\/__/ /:/__/ \:\__\ /:/ |:| /\__/
//  \:\  \    \:\~\:\ \/__/ \:\  /\ \/__/ /\/:/  /    \:\  \ /:/  / \/__|:|/:/  /
//   \:\  \    \:\ \:\__\    \:\ \:\__\   \::/__/      \:\  /:/  /      |:/:/  /
//    \:\  \    \:\ \/__/     \:\/:/  /    \:\__\       \:\/:/  /       |::/  /
//     \:\__\    \:\__\        \::/  /      \/__/        \::/  /        /:/  /
//      \/__/     \/__/         \/__/                     \/__/         \/__/

/**
 * @title ILegionAbstractSale
 * @author Legion
 * @notice Interface for the LegionAbstractSale contract.
 */
interface ILegionAbstractSale {
    /// @dev Struct defining initialization parameters for a Legion sale
    struct LegionSaleInitializationParams {
        // Duration of the refund period in seconds
        uint64 refundPeriodSeconds;
        // Legion's fee on capital raised in basis points (BPS)
        uint16 legionFeeOnCapitalRaisedBps;
        // Referrer's fee on capital raised in basis points (BPS)
        uint16 referrerFeeOnCapitalRaisedBps;
        // Minimum investment amount in bid token
        uint256 minimumInvestAmount;
        // Legion's operations fee in wei
        uint256 legionOpsFeeInWei;
        // Decimals of the bid token
        uint8 bidTokenDecimals;
        // Address of the token used for raising capital
        address bidToken;
        // Admin address of the project raising capital
        address projectAdmin;
        // Address of Legion's Address Registry contract
        address addressRegistry;
        // Address of the referrer fee receiver
        address referrerFeeReceiver;
    }

    /// @dev Struct containing the runtime configuration of the sale
    struct LegionSaleConfiguration {
        // Unix timestamp (seconds) when the sale start
        uint64 startTime;
        // Unix timestamp (seconds) when the sale ends
        uint64 endTime;
        // Unix timestamp (seconds) when the refund period ends
        uint64 refundEndTime;
        // Legion's fee on capital raised in basis points (BPS)
        uint16 legionFeeOnCapitalRaisedBps;
        // Referrer's fee on capital raised in basis points (BPS)
        uint16 referrerFeeOnCapitalRaisedBps;
        // Minimum investment amount in bid token
        uint256 minimumInvestAmount;
        // Legion's operations fee in wei
        uint256 legionOpsFeeInWei;
        // Decimals of the bid token
        uint8 bidTokenDecimals;
    }

    /// @dev Struct containing the address configuration for the sale
    struct LegionSaleAddressConfiguration {
        // Address of the token used for raising capital
        address bidToken;
        // Admin address of the project raising capital
        address projectAdmin;
        // Address of Legion's Address Registry contract
        address addressRegistry;
        // Address of Legion's Bouncer contract
        address legionBouncer;
        // Address of Legion's Signer contract
        address legionSigner;
        // Address of Legion's Fee Receiver contract
        address legionFeeReceiver;
        // Address of the referrer fee receiver
        address referrerFeeReceiver;
    }

    /// @dev Struct tracking the current status of the sale
    struct LegionSaleStatus {
        // Total capital invested by investors
        uint256 totalCapitalInvested;
        // Total capital raised from the sale
        uint256 totalCapitalRaised;
        // Total capital withdrawn by the Project
        uint256 totalCapitalWithdrawn;
        // Indicates if the sale has been canceled
        bool isCanceled;
        // Indicates if capital has been withdrawn by the project
        bool capitalWithdrawn;
        // Flag indicating whether the sale has ended
        bool hasEnded;
    }

    /// @dev Struct representing an investor's position in the sale
    struct InvestorPosition {
        // Total capital invested by the investor
        uint256 investedCapital;
        // Flag indicating if investor has claimed excess capital
        bool hasClaimedExcess;
        // Flag indicating if investor has refunded
        bool hasRefunded;
    }

    /// @dev Enum defining possible actions during the sale
    enum SaleAction {
        INVEST, // Investing capital
        WITHDRAW_EXCESS_CAPITAL // Withdrawing excess capital

    }

    /// @notice Emitted when capital is withdrawn by the project owner.
    /// @param amount The amount of capital withdrawn.
    event CapitalWithdrawn(uint256 amount);

    /// @notice Emitted when capital is refunded to an investor.
    /// @param amount The amount of capital refunded.
    /// @param investor The address of the investor receiving refund.
    event CapitalRefunded(uint256 amount, address investor);

    /// @notice Emitted when capital is refunded after sale cancellation.
    /// @param amount The amount of capital refunded.
    /// @param investor The address of the investor receiving refund.
    event CapitalRefundedAfterCancel(uint256 amount, address investor);

    /// @notice Emitted when excess capital is claimed by an investor after sale completion.
    /// @param amount The amount of excess capital withdrawn.
    /// @param investor The address of the investor claiming excess.
    event ExcessCapitalWithdrawn(uint256 amount, address investor);

    /// @notice Emitted during an emergency withdrawal by Legion.
    /// @param receiver The address receiving withdrawn tokens.
    /// @param token The address of the token withdrawn.
    /// @param amount The amount of tokens withdrawn.
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /// @notice Emitted when Legion addresses are synced from the registry.
    /// @param legionBouncer The updated Legion bouncer address.
    /// @param legionSigner The updated Legion signer address.
    /// @param legionFeeReceiver The updated Legion fee receiver address.
    event LegionAddressesSynced(address legionBouncer, address legionSigner, address legionFeeReceiver);

    /// @notice Emitted when Legion's operations fee is updated.
    /// @param oldFee The previous fee amount in wei.
    /// @param newFee The new fee amount in wei.
    event LegionOpsFeeUpdated(uint256 oldFee, uint256 newFee);

    /// @notice Emitted when a sale is canceled.
    event SaleCanceled();

    /// @notice Requests a refund from the sale during the refund window.
    function refund() external;

    /// @notice Withdraws raised capital to the project admin.
    function withdrawRaisedCapital() external;

    /// @notice Withdraws excess invested capital back to the investor.
    /// @param amount The amount of excess capital to withdraw.
    /// @param signature The signature authorizing the withdrawal.
    function withdrawExcessInvestedCapital(uint256 amount, bytes calldata signature) external;

    /// @notice Withdraws invested capital if the sale is canceled.
    function withdrawInvestedCapitalIfCanceled() external;

    /// @notice Performs an emergency withdrawal of tokens.
    /// @param receiver The address to receive tokens.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /// @notice Synchronizes Legion addresses from the address registry.
    function syncLegionAddresses() external;

    /// @notice Pauses all sale operations.
    function pause() external;

    /// @notice Resumes all sale operations.
    function unpause() external;

    /// @notice Returns the current sale configuration.
    /// @return The complete sale configuration struct.
    function saleConfiguration() external view returns (LegionSaleConfiguration memory);

    /// @notice Returns the current sale status.
    /// @return The complete sale status struct.
    function saleStatus() external view returns (LegionSaleStatus memory);

    /// @notice Returns an investor's position details.
    /// @param investor The address of the investor.
    /// @return The complete investor position struct.
    function investorPosition(address investor) external view returns (InvestorPosition memory);

    /// @notice Cancels the ongoing sale.
    /// @dev Allows cancellation before results are published; only callable by the project admin.
    function cancel() external;

    /// @notice Updates Legion's operations fee.
    /// @param newFee The new fee amount in wei.
    function updateLegionOpsFee(uint256 newFee) external;
}
