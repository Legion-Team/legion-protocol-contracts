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

import { ILegionVestingManager } from "../../interfaces/vesting/ILegionVestingManager.sol";

/**
 * @title ILegionAbstractSale
 * @author Legion
 * @notice Interface for the LegionAbstractSale contract.
 */
interface ILegionAbstractSale {
    /// @dev Struct defining initialization parameters for a Legion sale
    struct LegionSaleInitializationParams {
        // Duration of the sale period in seconds
        uint64 salePeriodSeconds;
        // Duration of the refund period in seconds
        uint64 refundPeriodSeconds;
        // Legion's fee on capital raised in basis points (BPS)
        uint16 legionFeeOnCapitalRaisedBps;
        // Legion's fee on tokens sold in basis points (BPS)
        uint16 legionFeeOnTokensSoldBps;
        // Referrer's fee on capital raised in basis points (BPS)
        uint16 referrerFeeOnCapitalRaisedBps;
        // Referrer's fee on tokens sold in basis points (BPS)
        uint16 referrerFeeOnTokensSoldBps;
        // Minimum investment amount in bid token
        uint256 minimumInvestAmount;
        // Address of the token used for raising capital
        address bidToken;
        // Address of the token being sold to investors
        address askToken;
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
        // Legion's fee on tokens sold in basis points (BPS)
        uint16 legionFeeOnTokensSoldBps;
        // Referrer's fee on capital raised in basis points (BPS)
        uint16 referrerFeeOnCapitalRaisedBps;
        // Referrer's fee on tokens sold in basis points (BPS)
        uint16 referrerFeeOnTokensSoldBps;
        // Minimum investment amount in bid token
        uint256 minimumInvestAmount;
    }

    /// @dev Struct containing the address configuration for the sale
    struct LegionSaleAddressConfiguration {
        // Address of the token used for raising capital
        address bidToken;
        // Address of the token being sold to investors
        address askToken;
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
        // Total amount of tokens allocated to investors
        uint256 totalTokensAllocated;
        // Total capital raised from the sale
        uint256 totalCapitalRaised;
        // Total capital withdrawn by the Project
        uint256 totalCapitalWithdrawn;
        // Merkle root for verifying token distribution amounts
        bytes32 claimTokensMerkleRoot;
        // Merkle root for verifying accepted capital amounts
        bytes32 acceptedCapitalMerkleRoot;
        // Indicates if the sale has been canceled
        bool isCanceled;
        // Indicates if tokens have been supplied by the project
        bool tokensSupplied;
        // Indicates if capital has been withdrawn by the project
        bool capitalWithdrawn;
    }

    /// @dev Struct representing an investor's position in the sale
    struct InvestorPosition {
        // Total capital invested by the investor
        uint256 investedCapital;
        // Flag indicating if investor has settled tokens
        bool hasSettled;
        // Flag indicating if investor has claimed excess capital
        bool hasClaimedExcess;
        // Flag indicating if investor has refunded
        bool hasRefunded;
        // Address of the investor's vesting contract
        address vestingAddress;
    }

    /// @notice Emitted when capital is withdrawn by the project owner.
    /// @param amount The amount of capital withdrawn.
    event CapitalWithdrawn(uint256 amount);

    /// @notice Emitted when capital is refunded to an investor.
    /// @param amount The amount of capital refunded.
    /// @param investor The address of the investor receiving refund.
    /// @param positionId The ID of the investor's position.
    event CapitalRefunded(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when capital is refunded after sale cancellation.
    /// @param amount The amount of capital refunded.
    /// @param investor The address of the investor receiving refund.
    event CapitalRefundedAfterCancel(uint256 amount, address investor);

    /// @notice Emitted when excess capital is claimed by an investor after sale completion.
    /// @param amount The amount of excess capital withdrawn.
    /// @param investor The address of the investor claiming excess.
    /// @param positionId The ID of the investor's position.
    event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when accepted capital Merkle root is published by Legion.
    /// @param merkleRoot The Merkle root for accepted capital verification.
    event AcceptedCapitalSet(bytes32 merkleRoot);

    /// @notice Emitted during an emergency withdrawal by Legion.
    /// @param receiver The address receiving withdrawn tokens.
    /// @param token The address of the token withdrawn.
    /// @param amount The amount of tokens withdrawn.
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /// @notice Emitted when Legion addresses are synced from the registry.
    /// @param legionBouncer The updated Legion bouncer address.
    /// @param legionSigner The updated Legion signer address.
    /// @param legionFeeReceiver The updated Legion fee receiver address.
    /// @param vestingFactory The updated vesting factory address.
    /// @param vestingController The updated vesting controller address.
    event LegionAddressesSynced(
        address legionBouncer,
        address legionSigner,
        address legionFeeReceiver,
        address vestingFactory,
        address vestingController
    );

    /// @notice Emitted when a sale is canceled.
    event SaleCanceled();

    /// @notice Emitted when tokens are supplied for distribution by the project.
    /// @param amount The amount of tokens supplied.
    /// @param legionFee The fee amount collected by Legion.
    /// @param referrerFee The fee amount collected by referrer.
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);

    /// @notice Emitted when an investor successfully claims their token allocation.
    /// @param amountToBeVested The amount of tokens sent to vesting contract.
    /// @param amountOnClaim The amount of tokens distributed immediately.
    /// @param investor The address of the claiming investor.
    /// @param positionId The ID of the investor's position.
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor, uint256 positionId);

    /// @notice Requests a refund from the sale during the refund window.
    function refund() external;

    /// @notice Withdraws raised capital to the project admin.
    function withdrawRaisedCapital() external;

    /// @notice Claims token allocation for an investor.
    /// @param amount The total amount of tokens to claim.
    /// @param investorVestingConfig The vesting configuration for the investor.
    /// @param proof The Merkle proof for claim verification.
    function claimTokenAllocation(
        uint256 amount,
        ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes32[] calldata proof
    )
        external;

    /// @notice Withdraws excess invested capital back to the investor.
    /// @param amount The amount of excess capital to withdraw.
    /// @param proof The Merkle proof for excess capital verification.
    function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external;

    /// @notice Releases vested tokens to the investor.
    /// @dev Interacts with the investor's vesting contract to release available tokens.
    function releaseVestedTokens() external;

    /// @notice Supplies tokens for distribution after the sale.
    /// @param amount The amount of tokens to supply.
    /// @param legionFee The fee amount for Legion.
    /// @param referrerFee The fee amount for the referrer.
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;

    /// @notice Sets the Merkle root for accepted capital verification.
    /// @param merkleRoot The Merkle root for accepted capital verification.
    function setAcceptedCapital(bytes32 merkleRoot) external;

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

    /// @notice Returns an investor's vesting status.
    /// @param investor The address of the investor.
    /// @return vestingStatus The complete vesting status including timestamps, amounts, and release information.
    function investorVestingStatus(address investor)
        external
        view
        returns (ILegionVestingManager.LegionInvestorVestingStatus memory);

    /// @notice Cancels the ongoing sale.
    /// @dev Allows cancellation before results are published; only callable by the project admin.
    function cancel() external;
}
