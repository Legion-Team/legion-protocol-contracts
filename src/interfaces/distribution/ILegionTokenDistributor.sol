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
 * @title ILegionTokenDistributor
 * @author Legion
 * @notice Interface for the LegionTokenDistributor contract.
 */
interface ILegionTokenDistributor {
    /// @dev Struct for initializing the Token Distributor.
    struct TokenDistributorInitializationParams {
        // Legion's fee on tokens sold in basis points (BPS).
        uint16 legionFeeOnTokensSoldBps;
        // Referrer's fee on tokens sold in basis points (BPS).
        uint16 referrerFeeOnTokensSoldBps;
        // Address of the referrer fee receiver.
        address referrerFeeReceiver;
        // Address of the token being sold to investors.
        address askToken;
        // Address of Legion's Address Registry contract.
        address addressRegistry;
        // Admin address of the project raising capital.
        address projectAdmin;
        // The total amount of tokens to be distributed.
        uint256 totalAmountToDistribute;
    }

    /// @dev Struct for storing the configuration of the Token Distributor.
    struct TokenDistributorConfig {
        // Legion's fee on tokens sold in basis points (BPS).
        uint16 legionFeeOnTokensSoldBps;
        // Referrer's fee on tokens sold in basis points (BPS).
        uint16 referrerFeeOnTokensSoldBps;
        // Indicates if tokens have been supplied by the project.
        bool tokensSupplied;
        // The total amount of tokens to be distributed.
        uint256 totalAmountToDistribute;
        // The total amount of tokens already claimed.
        uint256 totalAmountClaimed;
        // Address of the token being sold to investors.
        address askToken;
        // Admin address of the project raising capital.
        address projectAdmin;
        // Address of the Legion Bouncer contract.
        address legionBouncer;
        // Address of Legion's Fee Receiver contract.
        address legionFeeReceiver;
        // Address of the referrer fee receiver.
        address referrerFeeReceiver;
        // Signer address of Legion.
        address legionSigner;
        // Address of Legion's Address Registry contract.
        address addressRegistry;
    }

    /// @dev Struct representing an investor's position in the distribution.
    struct InvestorPosition {
        // Flag indicating if investor has settled tokens.
        bool hasSettled;
        // Address of the investor's vesting contract.
        address vestingAddress;
    }

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
    event LegionAddressesSynced(
        address legionBouncer, address legionSigner, address legionFeeReceiver, address vestingFactory
    );

    /// @notice Emitted when an investor successfully claims their token allocation.
    /// @param amountToBeVested The amount of tokens sent to vesting contract.
    /// @param amountOnClaim The amount of tokens distributed immediately.
    /// @param investor The address of the claiming investor.
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor);

    /// @notice Emitted when tokens are supplied for distribution by the project.
    /// @param amount The amount of tokens supplied.
    /// @param legionFee The fee amount collected by Legion.
    /// @param referrerFee The fee amount collected by the referrer.
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);

    /// @notice Initializes the token distributor with parameters.
    /// @param tokenDistributorInitParams The initialization parameters for the distributor.
    function initialize(TokenDistributorInitializationParams calldata tokenDistributorInitParams) external;

    /// @notice Supplies tokens for distribution after TGE.
    /// @param amount The amount of tokens to supply.
    /// @param legionFee The fee amount for Legion.
    /// @param referrerFee The fee amount for referrer.
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;

    /// @notice Performs an emergency withdrawal of tokens.
    /// @param receiver The address to receive tokens.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /// @notice Allows investors to claim their token allocation.
    /// @param claimAmount The amount of tokens to claim.
    /// @param investorVestingConfig The vesting configuration for the investor.
    /// @param claimSignature The signature verifying investment eligibility.
    /// @param vestingSignature The signature verifying vesting terms.
    function claimTokenAllocation(
        uint256 claimAmount,
        ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes calldata claimSignature,
        bytes calldata vestingSignature
    )
        external;

    /// @notice Releases vested tokens to the investor.
    function releaseVestedTokens() external;

    /// @notice Synchronizes Legion addresses from the address registry.
    function syncLegionAddresses() external;

    /// @notice Pauses the distribution.
    function pause() external;

    /// @notice Resumes the distribution.
    function unpause() external;

    /// @notice Retrieves the current distributor configuration.
    /// @return The complete distributor configuration struct.
    function distributorConfiguration() external view returns (TokenDistributorConfig memory);

    /// @notice Retrieves an investor's position details.
    /// @param investorAddress The address of the investor.
    /// @return The complete investor position struct.
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);

    /// @notice Retrieves an investor's vesting status.
    /// @param investor The address of the investor.
    /// @return The complete vesting status struct.
    function investorVestingStatus(address investor)
        external
        view
        returns (ILegionVestingManager.LegionInvestorVestingStatus memory);
}
