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
 * @notice Interface for the LegionPreLiquidApprovedSale contract.
 */
interface ILegionPreLiquidApprovedSale {
    /// @dev Struct defining initialization parameters for the pre-liquid sale
    struct PreLiquidSaleInitializationParams {
        // Address of the token used for raising capital
        address bidToken;
        // Admin address of the project raising capital
        address projectAdmin;
        // Address of Legion's Address Registry contract
        address addressRegistry;
        // Address of the referrer fee receiver
        address referrerFeeReceiver;
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
        // Name of the pre-liquid sale soulbound token
        string saleName;
        // Symbol of the pre-liquid sale soulbound token
        string saleSymbol;
        // Base URI for the pre-liquid sale soulbound token
        string saleBaseURI;
    }

    /// @dev Struct containing the runtime configuration of the pre-liquid sale
    struct PreLiquidSaleConfig {
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
    }

    /// @dev Struct tracking the current status of the pre-liquid sale
    struct PreLiquidSaleStatus {
        // Address of the token being sold to investors
        address askToken;
        // Total supply of the ask token
        uint256 askTokenTotalSupply;
        // Total capital invested by investors
        uint256 totalCapitalInvested;
        // Total capital raised from the sale
        uint256 totalCapitalRaised;
        // Total amount of tokens allocated to investors
        uint256 totalTokensAllocated;
        // Total capital withdrawn by the Project
        uint256 totalCapitalWithdrawn;
        // End time of the sale
        uint64 endTime;
        // Refund end time of the sale
        uint64 refundEndTime;
        // Indicates if the sale has been canceled
        bool isCanceled;
        // Indicates if ask tokens have been supplied
        bool tokensSupplied;
        // Indicates if the sale has ended
        bool hasEnded;
    }

    /// @dev Struct representing an investor's position in the sale
    struct InvestorPosition {
        // Address of the investor's vesting contract
        address vestingAddress;
        // Total capital invested by the investor
        uint256 investedCapital;
        // Amount of capital allowed per SAFT
        uint256 cachedInvestAmount;
        // Token allocation rate as percentage of total supply (18 decimals)
        uint256 cachedTokenAllocationRate;
        // Flag indicating if investor has claimed excess capital
        bool hasClaimedExcess;
        // Flag indicating if investor has refunded
        bool hasRefunded;
        // Flag indicating if investor has settled tokens
        bool hasSettled;
    }

    /// @dev Enum defining possible actions during the sale
    enum SaleAction {
        INVEST, // Investing capital
        WITHDRAW_EXCESS_CAPITAL, // Withdrawing excess capital
        CLAIM_TOKEN_ALLOCATION // Claiming token allocation

    }

    /// @notice Emitted when capital is successfully invested in the pre-liquid sale.
    /// @param amount The amount of capital invested (in bid tokens).
    /// @param investor The address of the investor.
    /// @param positionId The ID of the investor's position.
    event CapitalInvested(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when excess capital is successfully withdrawn by an investor.
    /// @param amount The amount of excess capital withdrawn.
    /// @param investor The address of the investor.
    /// @param positionId The ID of the investor's position.
    event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when capital is successfully refunded to an investor.
    /// @param amount The amount of capital refunded.
    /// @param investor The address of the investor receiving the refund.
    /// @param positionId The ID of the investor's position.
    event CapitalRefunded(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when capital is refunded after sale cancellation.
    /// @param amount The amount of capital refunded.
    /// @param investor The address of the investor receiving the refund.
    /// @param positionId The ID of the investor's position.
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
    /// @param vestingFactory The updated vesting factory address.
    /// @param vestingController The updated vesting controller address.
    event LegionAddressesSynced(
        address legionBouncer,
        address legionSigner,
        address legionFeeReceiver,
        address vestingFactory,
        address vestingController
    );

    /// @notice Emitted when the sale is successfully canceled.
    event SaleCanceled();

    /// @notice Emitted when token details are published after TGE by Legion.
    /// @param tokenAddress The address of the token distributed.
    /// @param totalSupply The total supply of the distributed token.
    /// @param allocatedTokenAmount The amount of tokens allocated for investors.
    event TgeDetailsPublished(address tokenAddress, uint256 totalSupply, uint256 allocatedTokenAmount);

    /// @notice Emitted when an investor successfully claims their token allocation.
    /// @param amountToBeVested The amount of tokens sent to vesting contract.
    /// @param amountOnClaim The amount of tokens distributed immediately.
    /// @param investor The address of the claiming investor.
    /// @param positionId The ID of the investor's position.
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor, uint256 positionId);

    /// @notice Emitted when tokens are supplied for distribution by the project.
    /// @param amount The amount of tokens supplied.
    /// @param legionFee The fee amount collected by Legion.
    /// @param referrerFee The fee amount collected by the referrer.
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);

    /// @notice Emitted when the sale has ended.
    event SaleEnded();

    /// @notice Initializes the pre-liquid approved sale contract with parameters.
    /// @param preLiquidSaleInitParams The pre-liquid approved sale initialization parameters.
    function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external;

    /// @notice Allows an investor to invest capital in the pre-liquid approved sale.
    /// @param amount The amount of capital to invest.
    /// @param investAmount The maximum capital allowed.
    /// @param tokenAllocationRate The token allocation percentage (18 decimals).
    /// @param investSignature The signature verifying investor eligibility.
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata investSignature
    )
        external;

    /// @notice Processes a refund for an investor during the refund period.
    function refund() external;

    /// @notice Publishes token details after Token Generation Event (TGE).
    /// @param askToken The address of the token to be distributed.
    /// @param askTokenTotalSupply The total supply of the ask token.
    /// @param totalTokensAllocated The total tokens allocated for investors.
    function publishTgeDetails(address askToken, uint256 askTokenTotalSupply, uint256 totalTokensAllocated) external;

    /// @notice Supplies tokens for distribution after TGE.
    /// @param amount The amount of tokens to supply.
    /// @param legionFee The fee amount for Legion.
    /// @param referrerFee The fee amount for the referrer.
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;

    /// @notice Withdraws tokens in emergency situations.
    /// @param receiver The address to receive withdrawn tokens.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /// @notice Withdraws raised capital to the project admin.
    function withdrawRaisedCapital() external;

    /// @notice Allows investors to claim their token allocation.
    /// @param investAmount The maximum capital allowed per SAFT.
    /// @param tokenAllocationRate The token allocation percentage (18 decimals).
    /// @param investorVestingConfig The vesting configuration for the investor.
    /// @param claimSignature The signature verifying investment eligibility.
    /// @param vestingSignature The signature verifying vesting terms.
    function claimTokenAllocation(
        uint256 investAmount,
        uint256 tokenAllocationRate,
        ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes calldata claimSignature,
        bytes calldata vestingSignature
    )
        external;

    /// @notice Cancels the sale and handles capital return.
    function cancel() external;

    /// @notice Allows investors to withdraw capital if the sale is canceled.
    function withdrawInvestedCapitalIfCanceled() external;

    /// @notice Withdraws excess invested capital back to investors.
    /// @param amount The amount of excess capital to withdraw.
    /// @param investAmount The maximum capital allowed.
    /// @param tokenAllocationRate The token allocation percentage (18 decimals).
    /// @param withdrawSignature The signature verifying eligibility.
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes calldata withdrawSignature
    )
        external;

    /// @notice Releases vested tokens to the investor.
    function releaseVestedTokens() external;

    /// @notice Ends the sale manually.
    function end() external;

    /// @notice Publishes the total capital raised.
    /// @param capitalRaised The total capital raised by the project.
    function publishRaisedCapital(uint256 capitalRaised) external;

    /// @notice Synchronizes Legion addresses from the address registry.
    function syncLegionAddresses() external;

    /// @notice Pauses all sale operations.
    function pause() external;

    /// @notice Resumes all sale operations.
    function unpause() external;

    /// @notice Returns the current sale configuration.
    /// @return The complete sale configuration struct.
    function saleConfiguration() external view returns (PreLiquidSaleConfig memory);

    /// @notice Returns the current sale status.
    /// @return The complete sale status struct.
    function saleStatus() external view returns (PreLiquidSaleStatus memory);

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
}
