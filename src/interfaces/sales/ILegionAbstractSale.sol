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
 * @notice Interface for managing token sales within the Legion Protocol
 */
interface ILegionAbstractSale {
    /// @notice Struct defining initialization parameters for a Legion sale
    struct LegionSaleInitializationParams {
        /// @notice Duration of the sale period in seconds
        /// @dev Time window during which investments are accepted
        uint64 salePeriodSeconds;
        /// @notice Duration of the refund period in seconds
        /// @dev Time window for refund requests post-sale
        uint64 refundPeriodSeconds;
        /// @notice Legion's fee on capital raised in basis points (BPS)
        /// @dev Fee percentage applied to raised capital (1 BPS = 0.01%)
        uint16 legionFeeOnCapitalRaisedBps;
        /// @notice Legion's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage applied to sold tokens
        uint16 legionFeeOnTokensSoldBps;
        /// @notice Referrer's fee on capital raised in basis points (BPS)
        /// @dev Fee percentage for referrer on raised capital
        uint16 referrerFeeOnCapitalRaisedBps;
        /// @notice Referrer's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage for referrer on sold tokens
        uint16 referrerFeeOnTokensSoldBps;
        /// @notice Minimum investment amount in bid token
        /// @dev Threshold for individual investments
        uint256 minimumInvestAmount;
        /// @notice Address of the token used for raising capital
        /// @dev Bid token address
        address bidToken;
        /// @notice Address of the token being sold to investors
        /// @dev Ask token address, can be zero if set later
        address askToken;
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

    /// @notice Struct containing the runtime configuration of the sale
    struct LegionSaleConfiguration {
        /// @notice Unix timestamp (seconds) when the sale starts
        /// @dev Set at initialization
        uint64 startTime;
        /// @notice Unix timestamp (seconds) when the sale ends
        /// @dev Set when sale concludes
        uint64 endTime;
        /// @notice Unix timestamp (seconds) when the refund period ends
        /// @dev Calculated as endTime + refundPeriodSeconds
        uint64 refundEndTime;
        /// @notice Legion's fee on capital raised in basis points (BPS)
        /// @dev Fee percentage on capital
        uint16 legionFeeOnCapitalRaisedBps;
        /// @notice Legion's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage on tokens
        uint16 legionFeeOnTokensSoldBps;
        /// @notice Referrer's fee on capital raised in basis points (BPS)
        /// @dev Referrer fee on capital
        uint16 referrerFeeOnCapitalRaisedBps;
        /// @notice Referrer's fee on tokens sold in basis points (BPS)
        /// @dev Referrer fee on tokens
        uint16 referrerFeeOnTokensSoldBps;
        /// @notice Minimum investment amount in bid token
        /// @dev Minimum threshold for investments
        uint256 minimumInvestAmount;
    }

    /// @notice Struct containing the address configuration for the sale
    struct LegionSaleAddressConfiguration {
        /// @notice Address of the token used for raising capital
        /// @dev Bid token address
        address bidToken;
        /// @notice Address of the token being sold to investors
        /// @dev Ask token address
        address askToken;
        /// @notice Admin address of the project raising capital
        /// @dev Project admin address
        address projectAdmin;
        /// @notice Address of Legion's Address Registry contract
        /// @dev Registry address
        address addressRegistry;
        /// @notice Address of Legion's Bouncer contract
        /// @dev Access control address
        address legionBouncer;
        /// @notice Address of Legion's Signer contract
        /// @dev Address for signature verification
        address legionSigner;
        /// @notice Address of Legion's Fee Receiver contract
        /// @dev Destination for Legion fees
        address legionFeeReceiver;
        /// @notice Address of the referrer fee receiver
        /// @dev Destination for referrer fees
        address referrerFeeReceiver;
    }

    /// @notice Struct tracking the current status of the sale
    struct LegionSaleStatus {
        /// @notice Total capital invested by investors
        /// @dev Aggregate investment amount
        uint256 totalCapitalInvested;
        /// @notice Total amount of tokens allocated to investors
        /// @dev Allocation for distribution
        uint256 totalTokensAllocated;
        /// @notice Total capital raised from the sale
        /// @dev Final raised amount
        uint256 totalCapitalRaised;
        /// @notice Total capital withdrawn by the Project
        /// @dev Amount withdrawn by project
        uint256 totalCapitalWithdrawn;
        /// @notice Merkle root for verifying token distribution amounts
        /// @dev Used for claim verification
        bytes32 claimTokensMerkleRoot;
        /// @notice Merkle root for verifying accepted capital amounts
        /// @dev Used for excess capital verification
        bytes32 acceptedCapitalMerkleRoot;
        /// @notice Indicates if the sale has been canceled
        /// @dev Cancellation status
        bool isCanceled;
        /// @notice Indicates if tokens have been supplied by the project
        /// @dev Supply status
        bool tokensSupplied;
        /// @notice Indicates if capital has been withdrawn by the project
        /// @dev Withdrawal status
        bool capitalWithdrawn;
    }

    /// @notice Struct representing an investor's position in the sale
    struct InvestorPosition {
        /// @notice Total capital invested by the investor
        /// @dev Invested amount in bid tokens
        uint256 investedCapital;
        /// @notice Flag indicating if investor has settled tokens
        /// @dev Settlement status
        bool hasSettled;
        /// @notice Flag indicating if investor has claimed excess capital
        /// @dev Excess claim status
        bool hasClaimedExcess;
        /// @notice Flag indicating if investor has refunded
        /// @dev Refund status
        bool hasRefunded;
        /// @notice Address of the investor's vesting contract
        /// @dev Vesting contract address
        address vestingAddress;
    }

    /**
     * @notice Emitted when capital is withdrawn by the project owner
     * @param amount Amount of capital withdrawn
     */
    event CapitalWithdrawn(uint256 amount);

    /**
     * @notice Emitted when capital is refunded to an investor
     * @param amount Amount of capital refunded
     * @param investor Address of the investor receiving refund
     * @param positionId ID of the investor's position
     */
    event CapitalRefunded(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when capital is refunded after sale cancellation
     * @param amount Amount of capital refunded
     * @param investor Address of the investor receiving refund
     */
    event CapitalRefundedAfterCancel(uint256 amount, address investor);

    /**
     * @notice Emitted when excess capital is claimed by an investor post-sale
     * @param amount Amount of excess capital withdrawn
     * @param investor Address of the investor claiming excess
     * @param positionId ID of the investor's position
     */
    event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when accepted capital Merkle root is published by Legion
     * @param merkleRoot Merkle root for accepted capital verification
     */
    event AcceptedCapitalSet(bytes32 merkleRoot);

    /**
     * @notice Emitted during an emergency withdrawal by Legion
     * @param receiver Address receiving withdrawn tokens
     * @param token Address of the token withdrawn
     * @param amount Amount of tokens withdrawn
     */
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /**
     * @notice Emitted when Legion addresses are synced from the registry
     * @param legionBouncer Updated Legion bouncer address
     * @param legionSigner Updated Legion signer address
     * @param legionFeeReceiver Updated Legion fee receiver address
     * @param vestingFactory Updated vesting factory address
     */
    event LegionAddressesSynced(
        address legionBouncer, address legionSigner, address legionFeeReceiver, address vestingFactory
    );

    /**
     * @notice Emitted when a sale is canceled
     */
    event SaleCanceled();

    /**
     * @notice Emitted when tokens are supplied for distribution by the project
     * @param amount Amount of tokens supplied
     * @param legionFee Fee amount collected by Legion
     * @param referrerFee Fee amount collected by referrer
     */
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);

    /**
     * @notice Emitted when an investor successfully claims their token allocation
     * @param amountToBeVested Amount of tokens sent to vesting contract
     * @param amountOnClaim Amount of tokens distributed immediately
     * @param investor Address of the claiming investor
     * @param positionId ID of the investor's position
     */
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor, uint256 positionId);

    /**
     * @notice Requests a refund from the sale during the refund period
     */
    function refund() external;

    /**
     * @notice Withdraws raised capital from the sale contract
     */
    function withdrawRaisedCapital() external;

    /**
     * @notice Claims investor token allocation
     * @param amount Total amount of tokens to claim
     * @param investorVestingConfig Vesting configuration for the investor
     * @param proof Merkle proof for claim verification
     */
    function claimTokenAllocation(
        uint256 amount,
        ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes32[] calldata proof
    )
        external;

    /**
     * @notice Withdraws excess invested capital back to the investor
     * @param amount Amount of excess capital to withdraw
     * @param proof Merkle proof for excess capital verification
     */
    function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external;

    /**
     * @notice Releases vested tokens to the investor
     */
    function releaseVestedTokens() external;

    /**
     * @notice Supplies tokens for distribution post-sale
     * @param amount Amount of tokens to supply
     * @param legionFee Fee amount for Legion
     * @param referrerFee Fee amount for referrer
     */
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;

    /**
     * @notice Publishes Merkle root for accepted capital
     * @param merkleRoot Merkle root for accepted capital verification
     */
    function setAcceptedCapital(bytes32 merkleRoot) external;

    /**
     * @notice Cancels an ongoing sale
     */
    function cancelSale() external;

    /**
     * @notice Withdraws invested capital if the sale is canceled
     */
    function withdrawInvestedCapitalIfCanceled() external;

    /**
     * @notice Performs an emergency withdrawal of tokens
     * @param receiver Address to receive withdrawn tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /**
     * @notice Syncs active Legion addresses from the registry
     */
    function syncLegionAddresses() external;

    /**
     * @notice Pauses the sale
     */
    function pauseSale() external;

    /**
     * @notice Unpauses the sale
     */
    function unpauseSale() external;

    /**
     * @notice Retrieves the current sale configuration
     * @return LegionSaleConfiguration memory Struct containing sale configuration
     */
    function saleConfiguration() external view returns (LegionSaleConfiguration memory);

    /**
     * @notice Retrieves the current sale status
     * @return LegionSaleStatus memory Struct containing sale status
     */
    function saleStatusDetails() external view returns (LegionSaleStatus memory);

    /**
     * @notice Retrieves an investor's position details
     * @param investor Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investor) external view returns (InvestorPosition memory);

    /**
     * @notice Retrieves an investor's vesting status
     * @param investor Address of the investor
     * @return ILegionVestingManager.LegionInvestorVestingStatus memory Struct containing vesting status
     */
    function investorVestingStatus(address investor)
        external
        view
        returns (ILegionVestingManager.LegionInvestorVestingStatus memory);
}
