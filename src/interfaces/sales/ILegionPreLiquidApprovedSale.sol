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

import { ILegionVestingManager } from "../../interfaces/vesting/ILegionVestingManager.sol";

/**
 * @title ILegionPreLiquidApprovedSale
 * @author Legion
 * @notice Interface for managing pre-liquid approved sales of ERC20 tokens before TGE in the Legion Protocol
 */
interface ILegionPreLiquidApprovedSale {
    /// @notice Struct defining initialization parameters for the pre-liquid sale
    struct PreLiquidSaleInitializationParams {
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
        /// @notice Duration of the refund period in seconds
        /// @dev Time window for investors to request refunds
        uint64 refundPeriodSeconds;
        /// @notice Legion's fee on capital raised in basis points (BPS)
        /// @dev Percentage fee applied to raised capital
        uint16 legionFeeOnCapitalRaisedBps;
        /// @notice Legion's fee on tokens sold in basis points (BPS)
        /// @dev Percentage fee applied to sold tokens
        uint16 legionFeeOnTokensSoldBps;
        /// @notice Referrer's fee on capital raised in basis points (BPS)
        /// @dev Percentage fee for referrer on raised capital
        uint16 referrerFeeOnCapitalRaisedBps;
        /// @notice Referrer's fee on tokens sold in basis points (BPS)
        /// @dev Percentage fee for referrer on sold tokens
        uint16 referrerFeeOnTokensSoldBps;
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

    /// @notice Struct containing the runtime configuration of the pre-liquid sale
    struct PreLiquidSaleConfig {
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
        /// @notice Duration of the refund period in seconds
        /// @dev Time window for refunds
        uint64 refundPeriodSeconds;
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
    }

    /// @notice Struct tracking the current status of the pre-liquid sale
    struct PreLiquidSaleStatus {
        /// @notice Address of the token being sold to investors
        /// @dev Ask token address
        address askToken;
        /// @notice Total supply of the ask token
        /// @dev Total token supply
        uint256 askTokenTotalSupply;
        /// @notice Total capital invested by investors
        /// @dev Aggregate investment amount
        uint256 totalCapitalInvested;
        /// @notice Total capital raised from the sale
        /// @dev Final raised amount
        uint256 totalCapitalRaised;
        /// @notice Total amount of tokens allocated to investors
        /// @dev Allocation for distribution
        uint256 totalTokensAllocated;
        /// @notice Total capital withdrawn by the Project
        /// @dev Amount withdrawn by project
        uint256 totalCapitalWithdrawn;
        /// @notice End time of the sale
        /// @dev Unix timestamp of sale end
        uint64 endTime;
        /// @notice Refund end time of the sale
        /// @dev Unix timestamp of refund period end
        uint64 refundEndTime;
        /// @notice Indicates if the sale has been canceled
        /// @dev Cancellation status
        bool isCanceled;
        /// @notice Indicates if ask tokens have been supplied
        /// @dev Supply status
        bool tokensSupplied;
        /// @notice Indicates if the sale has ended
        /// @dev End status
        bool hasEnded;
    }

    /// @notice Struct representing an investor's position in the sale
    struct InvestorPosition {
        /// @notice Address of the investor's vesting contract
        /// @dev Vesting contract address
        address vestingAddress;
        /// @notice Total capital invested by the investor
        /// @dev Invested amount in bid tokens
        uint256 investedCapital;
        /// @notice Amount of capital allowed per SAFT
        /// @dev Cached SAFT investment limit
        uint256 cachedInvestAmount;
        /// @notice Token allocation rate as percentage of total supply (18 decimals)
        /// @dev Cached allocation rate
        uint256 cachedTokenAllocationRate;
        /// @notice Flag indicating if investor has claimed excess capital
        /// @dev Excess claim status
        bool hasClaimedExcess;
        /// @notice Flag indicating if investor has refunded
        /// @dev Refund status
        bool hasRefunded;
        /// @notice Flag indicating if investor has settled tokens
        /// @dev Settlement status
        bool hasSettled;
    }

    /// @notice Enum defining possible actions during the sale
    enum SaleAction {
        INVEST, // Investing capital
        WITHDRAW_EXCESS_CAPITAL, // Withdrawing excess capital
        CLAIM_TOKEN_ALLOCATION // Claiming token allocation

    }

    /**
     * @notice Emitted when capital is successfully invested in the pre-liquid sale
     * @param amount Amount of capital invested (in bid tokens)
     * @param investor Address of the investor
     * @param positionId ID of the investor's position
     */
    event CapitalInvested(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when excess capital is successfully withdrawn by an investor
     * @param amount Amount of excess capital withdrawn
     * @param investor Address of the investor
     * @param positionId ID of the investor's position
     */
    event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when capital is successfully refunded to an investor
     * @param amount Amount of capital refunded
     * @param investor Address of the investor receiving the refund
     * @param positionId ID of the investor's position
     */
    event CapitalRefunded(uint256 amount, address investor, uint256 positionId);

    /**
     * @notice Emitted when capital is refunded after sale cancellation
     * @param amount Amount of capital refunded
     * @param investor Address of the investor receiving the refund
     * @param positionId ID of the investor's position
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
     * @param vestingFactory Updated vesting factory address
     */
    event LegionAddressesSynced(
        address legionBouncer, address legionSigner, address legionFeeReceiver, address vestingFactory
    );

    /**
     * @notice Emitted when the sale is successfully canceled
     */
    event SaleCanceled();

    /**
     * @notice Emitted when token details are published post-TGE by Legion
     * @param tokenAddress Address of the token distributed
     * @param totalSupply Total supply of the distributed token
     * @param allocatedTokenAmount Amount of tokens allocated for investors
     */
    event TgeDetailsPublished(address tokenAddress, uint256 totalSupply, uint256 allocatedTokenAmount);

    /**
     * @notice Emitted when an investor successfully claims their token allocation
     * @param amountToBeVested Amount of tokens sent to vesting contract
     * @param amountOnClaim Amount of tokens distributed immediately
     * @param investor Address of the claiming investor
     * @param positionId ID of the investor's position
     */
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor, uint256 positionId);

    /**
     * @notice Emitted when tokens are supplied for distribution by the Project
     * @param amount Amount of tokens supplied
     * @param legionFee Fee amount collected by Legion
     * @param referrerFee Fee amount collected by the referrer
     */
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);

    /**
     * @notice Emitted when the sale has ended
     */
    event SaleEnded();

    /**
     * @notice Initializes the pre-liquid sale with parameters
     * @param preLiquidSaleInitParams Calldata struct with initialization parameters
     */
    function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external;

    /**
     * @notice Allows investment into the pre-liquid sale
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
     * @notice Publishes token details after TGE
     * @param _askToken Address of the token to distribute
     * @param _askTokenTotalSupply Total supply of the token
     * @param _totalTokensAllocated Total tokens allocated for investors
     */
    function publishTgeDetails(
        address _askToken,
        uint256 _askTokenTotalSupply,
        uint256 _totalTokensAllocated
    )
        external;

    /**
     * @notice Supplies tokens for distribution post-TGE
     * @param amount Amount of tokens to supply
     * @param legionFee Fee amount for Legion
     * @param referrerFee Fee amount for referrer
     */
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;

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
     * @notice Allows investors to claim their token allocation
     * @param investAmount Maximum allowed investment per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investorVestingConfig Vesting configuration for the investor
     * @param claimSignature Signature verifying claiming eligibility
     * @param vestingSignature Signature verifying vesting terms
     */
    function claimTokenAllocation(
        uint256 investAmount,
        uint256 tokenAllocationRate,
        ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes calldata claimSignature,
        bytes calldata vestingSignature
    )
        external;

    /**
     * @notice Cancels the pre-liquid sale
     */
    function cancelSale() external;

    /**
     * @notice Withdraws invested capital if the sale is canceled
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
     * @notice Releases vested tokens to the investor
     */
    function releaseVestedTokens() external;

    /**
     * @notice Ends the pre-liquid sale manually
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
     * @notice Pauses the pre-liquid sale
     */
    function pauseSale() external;

    /**
     * @notice Unpauses the pre-liquid sale
     */
    function unpauseSale() external;

    /**
     * @notice Retrieves the current sale configuration
     * @return PreLiquidSaleConfig memory Struct containing sale configuration
     */
    function saleConfiguration() external view returns (PreLiquidSaleConfig memory);

    /**
     * @notice Retrieves the current sale status
     * @return PreLiquidSaleStatus memory Struct containing sale status
     */
    function saleStatusDetails() external view returns (PreLiquidSaleStatus memory);

    /**
     * @notice Retrieves an investor's position details
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);

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
