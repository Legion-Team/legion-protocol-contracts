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

interface ILegionPreLiquidSaleV1 {
    /**
     * @notice This event is emitted when capital is successfully invested.
     *
     * @param amount The amount of capital invested.
     * @param investor The address of the investor.
     * @param tokenAllocationRate The token allocation the investor will receive as percentage of totalSupply,
     * represented in 18 decimals precision.
     * @param saftHash The hash of the SAFT signed by the investor
     * @param investTimestamp The unix timestamp (seconds) of the block when capital has been invested.
     */
    event CapitalInvested(
        uint256 amount, address investor, uint256 tokenAllocationRate, bytes32 saftHash, uint256 investTimestamp
    );

    /**
     * @notice This event is emitted when excess capital is successfully withdrawn.
     *
     * @param amount The amount of capital withdrawn.
     * @param investor The address of the investor.
     * @param tokenAllocationRate The token allocation the investor will receive as percentage of totalSupply,
     * represented in 18 decimals precision.
     * @param saftHash The hash of the SAFT signed by the investor
     * @param investTimestamp The unix timestamp (seconds) of the block when capital has been invested.
     */
    event ExcessCapitalWithdrawn(
        uint256 amount, address investor, uint256 tokenAllocationRate, bytes32 saftHash, uint256 investTimestamp
    );

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
     * @notice This event is emitted when capital is successfully withdrawn by the Project.
     *
     * @param amount The amount of capital withdrawn by the project.
     */
    event CapitalWithdrawn(uint256 amount);

    /**
     * @notice This event is emitted when excess capital results are successfully published by the Legion admin.
     *
     * @param receiver The address of the receiver.
     * @param token The address of the token to be withdrawn.
     * @param amount The amount to be withdrawn.
     */
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /**
     * @notice This event is emitted when excess capital results are successfully published by the Legion admin.
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
     * @notice This event is emitted when the SAFT merkle root is updated by the Legion admin.
     *
     * @param merkleRoot The new SAFT merkle root.
     */
    event SAFTMerkleRootUpdated(bytes32 merkleRoot);

    /**
     * @notice This event is emitted when a sale is successfully canceled.
     */
    event SaleCanceled();

    /**
     * @notice This event is emitted when the token details have been set by the Legion admin.
     *
     * @param tokenAddress The address of the token distributed to investors
     * @param totalSupply The total supply of the token distributed to investors
     * @param vestingStartTime The unix timestamp (seconds) of the block when the vesting starts.
     * @param allocatedTokenAmount The allocated token amount for distribution to investors.
     */
    event TgeDetailsPublished(
        address tokenAddress, uint256 totalSupply, uint256 vestingStartTime, uint256 allocatedTokenAmount
    );

    /**
     * @notice This event is emitted when tokens are successfully claimed by the investor.
     *
     * @param amountToBeVested The amount of tokens distributed to the vesting contract.
     * @param amountOnClaim The amount of tokens to be deiistributed directly to the investor on claim
     * @param investor The address of the investor owning the vesting contract.
     */
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor);

    /**
     * @notice This event is emitted when tokens are successfully supplied for distribution by the project admin.
     *
     * @param amount The amount of tokens supplied for distribution.
     * @param legionFee The fee amount collected by Legion.
     */
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee);

    /**
     * @notice This event is emitted when tokens are successfully supplied for distribution by the project admin.
     *
     * @param _vestingDurationSeconds The vesting schedule duration for the token sold in seconds.
     * @param _vestingCliffDurationSeconds The vesting cliff duration for the token sold in seconds.
     * @param _tokenAllocationOnTGERate The token allocation amount released to investors after TGE in 18 decimals
     * precision.
     */
    event VestingTermsUpdated(
        uint256 _vestingDurationSeconds, uint256 _vestingCliffDurationSeconds, uint256 _tokenAllocationOnTGERate
    );

    /**
     * @notice This event is emitted when excess capital is successfully refunded by the project admin.
     *
     * @param amount The amount of excess capital refunded to the sale.
     */
    event ExcessCapitalRefunded(uint256 amount);

    /**
     * @notice This event is emitted when the sale has been closed.
     *
     * @param endTime The unix timestamp (seconds) of the block when the sale has been closed.
     */
    event SaleEnded(uint256 endTime);

    /// @notice A struct describing the pre-liquid sale initialization params.
    struct PreLiquidSaleInitializationParams {
        /// @dev The refund period duration in seconds.
        uint256 refundPeriodSeconds;
        /// @dev The vesting schedule duration for the token sold in seconds.
        uint256 vestingDurationSeconds;
        /// @dev The vesting cliff duration for the token sold in seconds.
        uint256 vestingCliffDurationSeconds;
        /// @dev The token allocation amount released to investors after TGE in 18 decimals precision.
        uint256 tokenAllocationOnTGERate;
        /// @dev Legion's fee on capital raised in BPS (Basis Points).
        uint256 legionFeeOnCapitalRaisedBps;
        /// @dev Legion's fee on tokens sold in BPS (Basis Points).
        uint256 legionFeeOnTokensSoldBps;
        /// @dev Referrer's fee on capital raised in BPS (Basis Points).
        uint256 referrerFeeOnCapitalRaisedBps;
        /// @dev Referrer's fee on tokens sold in BPS (Basis Points).
        uint256 referrerFeeOnTokensSoldBps;
        /// @dev The address of the token used for raising capital.
        address bidToken;
        /// @dev The admin address of the project raising capital.
        address projectAdmin;
        /// @dev The address of Legion's Address Registry contract.
        address addressRegistry;
        /// @dev The address of the referrer.
        address referrerFeeReceiver;
    }

    /// @notice A struct describing the pre-liquid sale period and fee configuration.
    struct PreLiquidSaleConfig {
        /// @dev The refund period duration in seconds.
        uint256 refundPeriodSeconds;
        /// @dev Legion's fee on capital raised in BPS (Basis Points).
        uint256 legionFeeOnCapitalRaisedBps;
        /// @dev Legion's fee on tokens sold in BPS (Basis Points).
        uint256 legionFeeOnTokensSoldBps;
        /// @dev Referrer's fee on capital raised in BPS (Basis Points).
        uint256 referrerFeeOnCapitalRaisedBps;
        /// @dev Referrer's fee on tokens sold in BPS (Basis Points).
        uint256 referrerFeeOnTokensSoldBps;
        /// @dev The address of the token used for raising capital.
        address bidToken;
        /// @dev The admin address of the project raising capital.
        address projectAdmin;
        /// @dev The address of Legion's Address Registry contract.
        address addressRegistry;
        /// @dev The admin address of Legion.
        address legionBouncer;
        /// @dev The signer address of Legion.
        address legionSigner;
        /// @dev The address of Legion fee receiver.
        address legionFeeReceiver;
        /// @dev The address of the referrer.
        address referrerFeeReceiver;
        /// @dev The address of Legion's Vesting Factory contract.
        address vestingFactory;
    }

    /// @notice A struct describing the pre-liquid sale status.
    struct PreLiquidSaleStatus {
        /// @dev The address of the token being sold to investors.
        address askToken;
        /// @dev The total supply of the ask token
        uint256 askTokenTotalSupply;
        /// @dev The total capital invested by investors.
        uint256 totalCapitalInvested;
        /// @dev The total amount of tokens allocated to investors.
        uint256 totalTokensAllocated;
        /// @dev The total capital withdrawn by the Project, from the sale.
        uint256 totalCapitalWithdrawn;
        /// @dev The end time of the sale.
        uint256 endTime;
        /// @dev The refund end time of the sale.
        uint256 refundEndTime;
        /// @dev Whether the sale has been canceled or not.
        bool isCanceled;
        /// @dev Whether the ask tokens have been supplied to the sale.
        bool askTokensSupplied;
        /// @dev Whether investment is being accepted by the Project.
        bool hasEnded;
    }

    /// @notice A struct describing the pre-liquid sale vesting configuration.
    struct PreLiquidSaleVestingConfig {
        /// @dev The unix timestamp (seconds) of the block when the vesting starts.
        uint256 vestingStartTime;
        /// @dev The vesting schedule duration for the token sold in seconds.
        uint256 vestingDurationSeconds;
        /// @dev The vesting cliff duration for the token sold in seconds.
        uint256 vestingCliffDurationSeconds;
        /// @dev The token allocation amount released to investors after TGE in 18 decimals precision.
        uint256 tokenAllocationOnTGERate;
    }

    /// @notice A struct describing the investor position during the sale.
    struct InvestorPosition {
        /// @dev The total amount of capital invested by the investor.
        uint256 investedCapital;
        /// @dev The amount of capital withdrawn from the investor position by the Project.
        uint256 withdrawnCapital;
        /// @dev The unix timestamp (seconds) of the block when the latest invest ocurred.
        uint256 cachedInvestTimestamp;
        /// @dev The amount of capital the investor is allowed to invest, according to the SAFT.
        uint256 cachedInvestAmount;
        /// @dev The token allocation rate the investor will receive as percentage of totalSupply, represented in 18
        /// decimals precision.
        uint256 cachedTokenAllocationRate;
        /// @dev The hash of the SAFT signed by the investor
        bytes32 cachedSAFTHash;
        /// @dev Flag if the investor has refunded.
        bool hasRefunded;
        /// @dev Flag if the investor has claimed the tokens allocated to them.
        bool hasSettled;
        /// @dev The address of the investor's vesting contract.
        address vestingAddress;
    }

    /// @notice An enum describing possible actions during the sale.
    enum SaleAction {
        INVEST,
        WITHDRAW_EXCESS_CAPITAL,
        CLAIM_TOKEN_ALLOCATION
    }

    /**
     * @notice Initialized the contract with correct parameters.
     *
     * @param preLiquidSaleInitParams The period and fee configuration for the pre-liquid sale.
     */
    function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external;

    /**
     * @notice Invest capital to the pre-liquid sale.
     *
     * @param amount The amount of capital invested.
     * @param investAmount The amount of capital the investor is allowed to invest, according to the SAFT.
     * @param tokenAllocationRate The token allocation the investor will receive as percentage of totalSupply,
     * represented in 18 decimals precision.
     * @param saftHash The hash of the SAFT signed by the investor
     * @param signature The signature proving that the investor has signed a SAFT
     */
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes32 saftHash,
        bytes memory signature
    )
        external;

    /**
     * @notice Get a refund from the sale during the applicable time window.
     */
    function refund() external;

    /**
     * @notice Updates the token details after Token Generation Event (TGE).
     *
     * @dev Only callable by Legion.
     *
     * @param tokenAddress The address of the token distributed to investors
     * @param totalSupply The total supply of the token distributed to investors
     * @param vestingStartTime The unix timestamp (seconds) of the block when the vesting starts.
     * @param allocatedTokenAmount The allocated token amount for distribution to investors.
     */
    function publishTgeDetails(
        address tokenAddress,
        uint256 totalSupply,
        uint256 vestingStartTime,
        uint256 allocatedTokenAmount
    )
        external;

    /**
     * @notice Supply tokens for distribution after the Token Generation Event (TGE).
     *
     * @dev Only callable by the Project.
     *
     * @param amount The amount of tokens to be supplied for distribution.
     * @param legionFee The Legion fee token amount.
     * @param referrerFee The Referrer fee token amount.
     */
    function supplyAskTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;

    /**
     * @notice Updates the vesting terms.
     *
     * @dev Only callable by Legion, before the token have been supplied by the Project.
     *
     * @param vestingDurationSeconds The vesting schedule duration for the token sold in seconds.
     * @param vestingCliffDurationSeconds The vesting cliff duration for the token sold in seconds.
     * @param tokenAllocationOnTGERate The token allocation amount released to investors after TGE in 18 decimals
     * precision.
     */
    function updateVestingTerms(
        uint256 vestingDurationSeconds,
        uint256 vestingCliffDurationSeconds,
        uint256 tokenAllocationOnTGERate
    )
        external;

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
     * @notice Withdraw capital from the contract.
     *
     * @dev Can be called only by the Project admin address.
     */
    function withdrawRaisedCapital() external;

    /**
     * @notice Claim token allocation by investors
     *
     * @param investAmount The amount of capital the investor is allowed to invest, according to the SAFT.
     * @param tokenAllocationRate The token allocation the investor will receive as percentage of totalSupply,
     * represented in 18 decimals precision.
     * @param saftHash The hash of the SAFT signed by the investor
     * @param signature The signature proving that the investor has signed a SAFT
     */
    function claimAskTokenAllocation(
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes32 saftHash,
        bytes memory signature
    )
        external;

    /**
     * @notice Cancel the sale.
     *
     * @dev Can be called only by the Project admin address.
     */
    function cancelSale() external;

    /**
     * @notice Claim back capital from investors if the sale has been canceled.
     */
    function withdrawCapitalIfSaleIsCanceled() external;

    /**
     * @notice Withdraw back excess capital from investors.
     *
     * @param amount The amount of excess capital to be withdrawn.
     * @param investAmount The amount of capital the investor is allowed to invest, according to the SAFT.
     * @param tokenAllocationRate The token allocation the investor will receive as percentage of totalSupply,
     * represented in 18 decimals precision.
     * @param saftHash The hash of the SAFT signed by the investor
     * @param signature The signature proving that the investor has signed a SAFT
     */
    function withdrawExcessCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes32 saftHash,
        bytes memory signature
    )
        external;

    /**
     * @notice Releases tokens to the investor address.
     */
    function releaseTokens() external;

    /**
     * @notice Toggles the `hasEnded` status.
     */
    function endSale() external;

    /**
     * @notice Syncs active Legion addresses from `LegionAddressRegistry.sol`
     */
    function syncLegionAddresses() external;
}
