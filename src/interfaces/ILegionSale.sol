// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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
//
// If you find a bug, please contact security[at]legion.cc
// We will pay a fair bounty for any issue that puts users' funds at risk.

interface ILegionSale {
    /// @notice A struct describing the Legion sale initialization params.
    struct LegionSaleInitializationParams {
        /// @dev The sale period duration in seconds.
        uint256 salePeriodSeconds;
        /// @dev The refund period duration in seconds.
        uint256 refundPeriodSeconds;
        /// @dev The lockup period duration in seconds.
        uint256 lockupPeriodSeconds;
        /// @dev Legion's fee on capital raised in BPS (Basis Points).
        uint256 legionFeeOnCapitalRaisedBps;
        /// @dev Legion's fee on tokens sold in BPS (Basis Points).
        uint256 legionFeeOnTokensSoldBps;
        /// @dev Referrer's fee on capital raised in BPS (Basis Points).
        uint256 referrerFeeOnCapitalRaisedBps;
        /// @dev Referrer's fee on tokens sold in BPS (Basis Points).
        uint256 referrerFeeOnTokensSoldBps;
        /// @dev The minimum invest amount denominated in the `bidToken`.
        uint256 minimumInvestAmount;
        /// @dev The address of the token used for raising capital.
        address bidToken;
        /// @dev The address of the token being sold to investors.
        address askToken;
        /// @dev The admin address of the project raising capital.
        address projectAdmin;
        /// @dev The address of Legion's Address Registry contract.
        address addressRegistry;
        /// @dev The address of the referrer.
        address referrerFeeReceiver;
    }

    /// @notice A struct describing the Legion vesting initialization params.
    struct LegionVestingInitializationParams {
        /// @dev The vesting schedule duration for the token sold in seconds.
        uint256 vestingDurationSeconds;
        /// @dev The vesting cliff duration for the token sold in seconds.
        uint256 vestingCliffDurationSeconds;
        /// @dev The token allocation amount released to investors after TGE in BPS (Basis Points).
        uint256 tokenAllocationOnTGERate;
    }

    /// @notice A struct describing the sale configuration.
    struct LegionSaleConfiguration {
        /// @dev The Unix timestamp (seconds) of the block when the sale starts.
        uint256 startTime;
        /// @dev The Unix timestamp (seconds) of the block when the sale ends.
        uint256 endTime;
        /// @dev The Unix timestamp (seconds) of the block when the refund period ends.
        uint256 refundEndTime;
        /// @dev The Unix timestamp (seconds) of the block when the lockup period ends.
        uint256 lockupEndTime;
        /// @dev Legion's fee on capital raised in BPS (Basis Points).
        uint256 legionFeeOnCapitalRaisedBps;
        /// @dev Legion's fee on tokens sold in BPS (Basis Points).
        uint256 legionFeeOnTokensSoldBps;
        /// @dev Referrer's fee on capital raised in BPS (Basis Points).
        uint256 referrerFeeOnCapitalRaisedBps;
        /// @dev Referrer's fee on tokens sold in BPS (Basis Points).
        uint256 referrerFeeOnTokensSoldBps;
        /// @dev The minimum invest amount denominated in the `bidToken`.
        uint256 minimumInvestAmount;
    }

    /// @notice A struct describing the sale address configuration.
    struct LegionSaleAddressConfiguration {
        /// @dev The address of the token used for raising capital.
        address bidToken;
        /// @dev The address of the token being sold to investors.
        address askToken;
        /// @dev The admin address of the project raising capital.
        address projectAdmin;
        /// @dev The address of Legion's Address Registry contract.
        address addressRegistry;
        /// @dev The address of Legion's Bouncer contract.
        address legionBouncer;
        /// @dev The address of Legion's Signer contract.
        address legionSigner;
        /// @dev The address of Legion's Fee Receiver contract.
        address legionFeeReceiver;
        /// @dev The address of the referrer.
        address referrerFeeReceiver;
    }

    /// @notice A struct describing the sale status.
    struct LegionSaleStatus {
        /// @dev The total capital invested.
        uint256 totalCapitalInvested;
        /// @dev The total amount of tokens allocated to investors.
        uint256 totalTokensAllocated;
        /// @dev The total capital raised from the sale.
        uint256 totalCapitalRaised;
        /// @dev The merkle root for verification of token distribution amounts.
        bytes32 claimTokensMerkleRoot;
        /// @dev The merkle root for verification of accepted capital distribution amounts.
        bytes32 acceptedCapitalMerkleRoot;
        /// @dev Whether the sale has been canceled.
        bool isCanceled;
        /// @dev Whether tokens have been supplied by the project.
        bool tokensSupplied;
        /// @dev Whether raised capital has been withdrawn from the sale by the project.
        bool capitalWithdrawn;
    }

    /// @notice A struct describing the vesting configuration.
    struct LegionVestingConfiguration {
        /// @dev The vesting schedule duration for the token sold in seconds.
        uint256 vestingDurationSeconds;
        /// @dev The vesting cliff duration for the token sold in seconds.
        uint256 vestingCliffDurationSeconds;
        /// @dev The token allocation amount released to investors after TGE in BPS (Basis Points).
        uint256 tokenAllocationOnTGERate;
        /// @dev The Unix timestamp (seconds) of the block when the vesting period starts.
        uint256 vestingStartTime;
        /// @dev The address of Legion's Vesting Factory contract.
        address vestingFactory;
    }

    /// @notice A struct describing the investor position during the sale.
    struct InvestorPosition {
        /// @dev The total amount of capital invested by the investor.
        uint256 investedCapital;
        /// @dev Flag indicating if the investor has settled.
        bool hasSettled;
        /// @dev Flag indicating if the investor has claimed excess capital.
        bool hasClaimedExcess;
        /// @dev Flag indicating if the investor has refunded.
        bool hasRefunded;
        /// @dev The address of the investor's vesting contract.
        address vestingAddress;
    }

    /**
     * @notice This event is emitted when capital is successfully withdrawn by the project owner.
     *
     * @param amountToWithdraw The amount of capital withdrawn.
     * @param projectOwner The address of the project owner.
     */
    event CapitalWithdrawn(uint256 amountToWithdraw, address projectOwner);

    /**
     * @notice This event is emitted when capital is successfully refunded to the investor.
     *
     * @param amount The amount of capital refunded to the investor.
     * @param investor The address of the investor who requested the refund.
     */
    event CapitalRefunded(uint256 amount, address investor);

    /**
     * @notice This event is emitted when capital is successfully refunded to the investor after a sale has been
     * canceled.
     *
     * @param amount The amount of capital refunded to the investor.
     * @param investor The address of the investor who requested the refund.
     */
    event CapitalRefundedAfterCancel(uint256 amount, address investor);

    /**
     * @notice This event is emitted when excess capital is successfully claimed by the investor after a sale has ended.
     *
     * @param amount The amount of capital refunded to the investor.
     * @param investor The address of the investor who requested the refund.
     */
    event ExcessCapitalWithdrawn(uint256 amount, address investor);

    /**
     * @notice This event is emitted when accepted capital has been successfully published by the Legion admin.
     *
     * @param merkleRoot The accepted capital merkle root published.
     */
    event AcceptedCapitalSet(bytes32 merkleRoot);

    /**
     * @notice This event is emitted when an emergency withdrawal of funds is performed by Legion.
     *
     * @param receiver The address of the receiver.
     * @param token The address of the token to be withdrawn.
     * @param amount The amount to be withdrawn.
     */
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /**
     * @notice This event is emitted when Legion addresses are successfully synced.
     *
     * @param legionBouncer The updated Legion bouncer address.
     * @param legionSigner The updated Legion signer address.
     * @param legionFeeReceiver The updated fee receiver address of Legion.
     * @param vestingFactory The updated vesting factory address.
     */
    event LegionAddressesSynced(
        address legionBouncer, address legionSigner, address legionFeeReceiver, address vestingFactory
    );

    /**
     * @notice This event is emitted when a sale is successfully canceled.
     */
    event SaleCanceled();

    /**
     * @notice This event is emitted when tokens are successfully supplied for distribution by the project admin.
     *
     * @param amount The amount of tokens supplied for distribution.
     * @param legionFee The fee amount collected by Legion.
     * @param referrerFee The fee amount collected by the referrer.
     */
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);

    /**
     * @notice This event is emitted when tokens are successfully claimed by the investor.
     *
     * @param amount The amount of tokens distributed to the vesting contract.
     * @param investor The address of the investor owning the vesting contract.
     */
    event TokenAllocationClaimed(uint256 amount, address investor);

    /**
     * @notice Request a refund from the sale during the applicable time window.
     */
    function refund() external;

    /**
     * @notice Withdraw raised capital from the sale contract.
     *
     * @dev Can be called only by the Project admin address.
     */
    function withdrawRaisedCapital() external;

    /**
     * @notice Claims the investor token allocation.
     *
     * @param amount The amount to be distributed.
     * @param proof The merkle proof verification for claiming.
     */
    function claimTokenAllocation(uint256 amount, bytes32[] calldata proof) external;

    /**
     * @notice Withdraw excess capital back to the investor.
     *
     * @param amount The amount to be returned.
     * @param proof The merkle proof verification for the return.
     */
    function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external;

    /**
     * @notice Releases tokens to the investor address.
     */
    function releaseVestedTokens() external;

    /**
     * @notice Supply tokens once the sale results have been published.
     *
     * @dev Can be called only by the Project admin address.
     *
     * @param amount The token amount supplied by the project.
     * @param legionFee The legion fee token amount supplied by the project.
     * @param referrerFee The referrer fee token amount supplied by the project.
     */
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;

    /**
     * @notice Publish merkle root for accepted capital.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param merkleRoot The merkle root to verify against.
     */
    function setAcceptedCapital(bytes32 merkleRoot) external;

    /**
     * @notice Cancels an ongoing sale.
     *
     * @dev Can be called only by the Project admin address.
     */
    function cancelSale() external;

    /**
     * @notice Cancels a sale in case the project has not supplied tokens after the lockup period is over.
     */
    function cancelExpiredSale() external;

    /**
     * @notice Claims back capital in case the sale has been canceled.
     */
    function withdrawInvestedCapitalIfCanceled() external;

    /**
     * @notice Withdraw tokens from the contract in case of emergency.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param receiver The address of the receiver.
     * @param token The address of the token to be withdrawn.
     * @param amount The amount to be withdrawn.
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /**
     * @notice Syncs active Legion addresses from `LegionAddressRegistry.sol`.
     */
    function syncLegionAddresses() external;

    /**
     * @notice Pauses the sale.
     */
    function pauseSale() external;

    /**
     * @notice Unpauses the sale.
     */
    function unpauseSale() external;

    /**
     * @notice Returns the sale configuration.
     */
    function saleConfiguration() external view returns (LegionSaleConfiguration memory);

    /**
     * @notice Returns the vesting configuration.
     */
    function vestingConfiguration() external view returns (LegionVestingConfiguration memory);

    /**
     * @notice Returns the sale status details.
     */
    function saleStatusDetails() external view returns (LegionSaleStatus memory);

    /**
     * @notice Returns an investor position.
     *
     * @param investorAddress The address of the investor.
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);
}
