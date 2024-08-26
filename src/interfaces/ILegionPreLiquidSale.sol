// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * ██      ███████  ██████  ██  ██████  ███    ██
 * ██      ██      ██       ██ ██    ██ ████   ██
 * ██      █████   ██   ███ ██ ██    ██ ██ ██  ██
 * ██      ██      ██    ██ ██ ██    ██ ██  ██ ██
 * ███████ ███████  ██████  ██  ██████  ██   ████
 *
 * If you find a bug, please contact security(at)legion.cc
 * We will pay a fair bounty for any issue that puts user's funds at risk.
 *
 */
interface ILegionPreLiquidSale {
    /**
     * @notice This event is emitted when capital is successfully invested.
     *
     * @param amount The amount of capital invested.
     * @param investor The address of the investor.
     * @param tokenAllocationBps The token allocation the investor will receive as percentage of totalSupply, represented in Basis Points (BPS).
     * @param saftHash The hash of the SAFT signed by the investor
     * @param investTimestamp The unix timestamp (seconds) of the block when capital has been invested.
     */
    event CapitalInvested(
        uint256 amount, address investor, uint256 tokenAllocationBps, bytes32 saftHash, uint256 investTimestamp
    );

    /**
     * @notice This event is emitted when excess capital is successfully withdrawn.
     *
     * @param amount The amount of capital withdrawn.
     * @param investor The address of the investor.
     * @param tokenAllocationBps The token allocation the investor will receive as percentage of totalSupply, represented in Basis Points (BPS).
     * @param saftHash The hash of the SAFT signed by the investor
     * @param investTimestamp The unix timestamp (seconds) of the block when capital has been invested.
     */
    event ExcessCapitalWithdrawn(
        uint256 amount, address investor, uint256 tokenAllocationBps, bytes32 saftHash, uint256 investTimestamp
    );

    /**
     * @notice This event is emitted when capital is successfully refunded to the investor.
     *
     * @param amount The amount of capital refunded to the investor.
     * @param investor The address of the investor who requested the refund.
     */
    event CapitalRefunded(uint256 amount, address investor);

    /**
     * @notice This event is emitted when capital is successfully refunded to the investor after a sale has been canceled.
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
     * @param vesting The address of the vesting instance deployed.
     */
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor, address vesting);

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
     * @param _tokenAllocationOnTGEBps The token allocation amount released to investors after TGE in BPS (Basis Points).
     */
    event VestingTermsUpdated(
        uint256 _vestingDurationSeconds, uint256 _vestingCliffDurationSeconds, uint256 _tokenAllocationOnTGEBps
    );

    /**
     * @notice This event is emitted when excess capital is successfully refunded by the project admin.
     *
     * @param amount The amount of excess capital refunded to the sale.
     */
    event ExcessCapitalRefunded(uint256 amount);

    /**
     * @notice This event is emitted when `investmentAccepted` status is changed.
     *
     * @param investmentAccepted Wheter investment is accepted by the Project.
     */
    event ToggleInvestmentAccepted(bool investmentAccepted);

    /**
     * @notice Throws when tokens already settled by investor.
     *
     * @param investor The address of the investor trying to invest.
     */
    error AlreadySettled(address investor);

    /**
     * @notice Throws when the ask tokens have not been supplied by the project.
     */
    error AskTokensNotSupplied();

    /**
     * @notice Throws when the Project tries to withdraw more than the allowed capital.
     */
    error CannotWithdrawCapital();

    /**
     * @notice Throws when an invalid amount has been requested for refund.
     */
    error InvalidRefundAmount();

    /**
     * @notice Throws when an invalid time config has been provided.
     */
    error InvalidPeriodConfig();

    /**
     * @notice Throws when an invalid amount of tokens has been supplied by the project.
     *
     * @param amount The amount of tokens supplied.
     */
    error InvalidTokenAmountSupplied(uint256 amount);

    /**
     * @notice Throws when an invalid amount has been requested for fee.
     */
    error InvalidFeeAmount();

    /**
     * @notice Throws when an invalid total supply has been provided.
     */
    error InvalidTotalSupply();

    /**
     * @notice Throws when an invalid amount of tokens has been claimed.
     */
    error InvalidClaimAmount();

    /**
     * @notice Throws when the Project is not accepting investments.
     */
    error InvestmentNotAccepted();

    /**
     * @notice Throws when the investor is not allowed to invest capital.
     *
     * @param investor The address of the investor.
     */
    error NotAllowedToInvestCapital(address investor);

    /**
     * @notice Throws when the investor is not allowed to withdraw excess capital.
     *
     * @param investor The address of the investor.
     */
    error NotAllowedToWithdrawExcessCapital(address investor);

    /**
     * @notice Throws when not called by the Legion admin.
     */
    error NotCalledByLegionAdmin();

    /**
     * @notice Throws when not called by the Project admin.
     */
    error NotCalledByProjectAdmin();

    /**
     * @notice Throws when the Project has withdrawn capital.
     */
    error ProjectHasWithdrawnCapital();

    /**
     * @notice Throws when no capital has been invested.
     *
     * @param investor The address of the investor
     */
    error CapitalNotInvested(address investor);

    /**
     * @notice Throws when capital has already been withdrawn for an investor.
     *
     * @param investor The address of the investor
     */
    error CapitalAlreadyWithdrawn(address investor);

    /**
     * @notice Throws when the refund period is over.
     */
    error RefundPeriodIsOver();

    /**
     * @notice Throws when the refund period is not over.
     */
    error RefundPeriodIsNotOver();

    /**
     * @notice Throws when the sale is canceled.
     */
    error SaleIsCanceled();

    /**
     * @notice Throws when the sale is not canceled.
     */
    error SaleIsNotCanceled();

    /**
     * @notice Throws when tokens have not been allocated.
     */
    error TokensNotAllocated();

    /**
     * @notice Throws when tokens have been allocated.
     */
    error TokensAlreadyAllocated();

    /**
     * @notice Throws when tokens have already been supplied.
     */
    error TokensAlreadySupplied();

    /**
     * @notice Throws when investor is unable to claim token allocation.
     */
    error UnableToClaimTokenAllocation();

    /**
     * @notice Throws when zero address has been provided.
     */
    error ZeroAddressProvided();

    /**
     * @notice Throws when zero value has been provided.
     */
    error ZeroValueProvided();

    /// @notice A struct describing the pre-liquid sale period and fee configuration.
    struct PreLiquidSaleConfig {
        /// @dev The refund period duration in seconds.
        uint256 refundPeriodSeconds;
        /// @dev The vesting schedule duration for the token sold in seconds.
        uint256 vestingDurationSeconds;
        /// @dev The vesting cliff duration for the token sold in seconds.
        uint256 vestingCliffDurationSeconds;
        /// @dev The token allocation amount released to investors after TGE in BPS (Basis Points).
        uint256 tokenAllocationOnTGEBps;
        /// @dev Legion's fee on capital raised in BPS (Basis Points).
        uint256 legionFeeOnCapitalRaisedBps;
        /// @dev Legion's fee on tokens sold in BPS (Basis Points).
        uint256 legionFeeOnTokensSoldBps;
        /// @dev The merkle root for verification of SAFT signers and percentage of token allocations.
        bytes32 saftMerkleRoot;
        /// @dev The address of the token used for raising capital.
        address bidToken;
        /// @dev The admin address of the project raising capital.
        address projectAdmin;
        /// @dev The admin address of Legion.
        address legionAdmin;
        /// @dev The address of Legion's Vesting Factory contract.
        address vestingFactory;
    }

    /// @notice A struct describing the pre-liquid sale status.
    struct PreLiquidSaleStatus {
        /// @dev The address of the token being sold to investors.
        address askToken;
        /// @dev The unix timestamp (seconds) of the block when the vesting starts.
        uint256 vestingStartTime;
        /// @dev The total supply of the ask token
        uint256 askTokenTotalSupply;
        /// @dev The total capital invested by investors.
        uint256 totalCapitalInvested;
        /// @dev The total amount of tokens allocated to investors.
        uint256 totalTokensAllocated;
        /// @dev The total capital withdrawn by the Project, from the sale.
        uint256 totalCapitalWithdrawn;
        /// @dev Whether the sale has been canceled or not.
        bool isCanceled;
        /// @dev Whether the ask tokens have been supplied to the sale.
        bool askTokensSupplied;
        /// @dev Whether investment is being accepted by the Project.
        bool investmentAccepted;
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
        uint256 cachedSAFTInvestAmount;
        /// @dev The token allocation the investor will receive as percentage of totalSupply, represented in Basis Points (BPS).
        uint256 cachedTokenAllocationBps;
        /// @dev The hash of the SAFT signed by the investor
        bytes32 cachedSAFTHash;
        /// @dev Flag if the investor has claimed the tokens allocated to them.
        bool hasSettled;
        /// @dev The address of the investor's vesting contract.
        address vestingAddress;
    }

    /**
     * @notice Initialized the contract with correct parameters.
     *
     * @param preLiquidSaleConfig The period and fee configuration for the pre-liquid sale.
     */
    function initialize(PreLiquidSaleConfig calldata preLiquidSaleConfig) external;

    /**
     * @notice Invest capital to the pre-liquid sale.
     *
     * @param amount The amount of capital invested.
     * @param saftInvestAmount The amount of capital the investor is allowed to invest, according to the SAFT.
     * @param tokenAllocationBps The token allocation the investor will receive as percentage of totalSupply, represented in Basis Points (BPS).
     * @param saftHash The hash of the SAFT signed by the investor
     * @param proof The merkle proof that the investor has signed a SAFT
     */
    function invest(
        uint256 amount,
        uint256 saftInvestAmount,
        uint256 tokenAllocationBps,
        bytes32 saftHash,
        bytes32[] calldata proof
    ) external;

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
    ) external;

    /**
     * @notice Supply tokens for distribution after the Token Generation Event (TGE).
     *
     * @dev Only callable by the Project.
     *
     * @param amount The amount of tokens to be supplied for distribution.
     * @param legionFee The Legion fee token amount.
     */
    function supplyAskTokens(uint256 amount, uint256 legionFee) external;

    /**
     * @notice Updates the SAFT merkle root.
     *
     * @dev Only callable by Legion.
     *
     * @param merkleRoot The merkle root used for investing capital.
     */
    function updateSAFTMerkleRoot(bytes32 merkleRoot) external;

    /**
     * @notice Updates the vesting terms.
     *
     * @dev Only callable by Legion, before the token have been supplied by the Project.
     *
     * @param vestingDurationSeconds The vesting schedule duration for the token sold in seconds.
     * @param vestingCliffDurationSeconds The vesting cliff duration for the token sold in seconds.
     * @param tokenAllocationOnTGEBps The token allocation amount released to investors after TGE in BPS (Basis Points).
     */
    function updateVestingTerms(
        uint256 vestingDurationSeconds,
        uint256 vestingCliffDurationSeconds,
        uint256 tokenAllocationOnTGEBps
    ) external;

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
     *
     * @param investors Array of the addresses of the investors' capital which will be withdrawn
     */
    function withdrawRaisedCapital(address[] calldata investors) external returns (uint256 amount);

    /**
     * @notice Claim token allocation by investors
     */
    function claimAskTokenAllocation() external;

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
     * @param saftInvestAmount The amount of capital the investor is allowed to invest, according to the SAFT.
     * @param tokenAllocationBps The token allocation the investor will receive as percentage of totalSupply, represented in Basis Points (BPS).
     * @param saftHash The hash of the SAFT signed by the investor
     * @param proof The merkle proof that the investor has signed a SAFT
     */
    function withdrawExcessCapital(
        uint256 amount,
        uint256 saftInvestAmount,
        uint256 tokenAllocationBps,
        bytes32 saftHash,
        bytes32[] calldata proof
    ) external;

    /**
     * @notice Releases tokens to the investor address.
     */
    function releaseTokens() external;

    /**
     * @notice Toggles the `investmentAccepted` status.
     */
    function toggleInvestmentAccepted() external;

    /**
     * @notice Returns the configuration for the pre-liquid token sale.
     */
    function saleConfig() external view returns (PreLiquidSaleConfig memory preLiquidSaleConfig);

    /**
     * @notice Returns the status of the pre-liquid token sale.
     */
    function saleStatus() external view returns (PreLiquidSaleStatus memory preLiquidSaleStatus);
}
