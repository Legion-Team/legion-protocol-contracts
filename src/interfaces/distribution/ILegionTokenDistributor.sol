// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

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

import { ILegionVestingManager } from "../../interfaces/vesting/ILegionVestingManager.sol";

/**
 * @title ILegionTokenDistributor
 * @author Legion
 * @notice Interface for managing token distribution of ERC20 tokens sold through the Legion Protocol
 */
interface ILegionTokenDistributor {
    /**
     * @notice Emitted during an emergency withdrawal by Legion
     * @dev Logs details of emergency token withdrawal
     * @param receiver Address receiving the withdrawn tokens
     * @param token Address of the token withdrawn
     * @param amount Amount of tokens withdrawn
     */
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /**
     * @notice Emitted when Legion addresses are successfully synced
     * @dev Logs updated addresses from the address registry
     * @param legionBouncer Updated Legion bouncer address
     * @param legionSigner Updated Legion signer address
     * @param legionFeeReceiver Updated Legion fee receiver address
     * @param vestingFactory Updated vesting factory address
     */
    event LegionAddressesSynced(
        address legionBouncer, address legionSigner, address legionFeeReceiver, address vestingFactory
    );

    /**
     * @notice Emitted when an investor successfully claims their token allocation
     * @dev Logs vested and immediate distribution amounts
     * @param amountToBeVested Amount of tokens sent to vesting contract
     * @param amountOnClaim Amount of tokens distributed immediately
     * @param investor Address of the claiming investor
     */
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor);

    /**
     * @notice Emitted when tokens are supplied for distribution by the Project
     * @dev Logs token supply and associated fees
     * @param amount Amount of tokens supplied
     * @param legionFee Fee amount collected by Legion
     * @param referrerFee Fee amount collected by the referrer
     */
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);

    /// @notice Struct for initializing the Token Distributor
    struct TokenDistributorInitializationParams {
        /// @notice The total amount of tokens to be distributed
        /// @dev Total tokens available for distribution
        uint256 totalAmountToDistribute;
        /// @notice Legion's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage applied to sold tokens
        uint256 legionFeeOnTokensSoldBps;
        /// @notice Referrer's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage for referrer on sold tokens
        uint256 referrerFeeOnTokensSoldBps;
        /// @notice Address of the referrer fee receiver
        /// @dev Destination for referrer fees
        address referrerFeeReceiver;
        /// @notice Address of the token being sold to investors
        /// @dev Ask token address
        address askToken;
        /// @notice Address of Legion's Address Registry contract
        /// @dev Registry address
        address addressRegistry;
        /// @notice Admin address of the project raising capital
        /// @dev Project admin address
        address projectAdmin;
    }

    /// @notice Struct for storing the configuration of the Token Distributor
    struct TokenDistributorConfig {
        /// @notice The total amount of tokens to be distributed
        /// @dev Total tokens available for distribution
        uint256 totalAmountToDistribute;
        /// @notice The total amount of tokens already claimed
        /// @dev Total tokens already distributed
        uint256 totalAmountClaimed;
        /// @notice Legion's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage applied to sold tokens
        uint256 legionFeeOnTokensSoldBps;
        /// @notice Referrer's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage for referrer on sold tokens
        uint256 referrerFeeOnTokensSoldBps;
        /// @notice Address of the token being sold to investors
        /// @dev Ask token address
        address askToken;
        /// @notice Admin address of the project raising capital
        /// @dev Project admin address
        address projectAdmin;
        /// @notice Address of the Legion Bouncer contract
        /// @dev Access control address
        address legionBouncer;
        /// @notice Address of Legion's Fee Receiver contract
        /// @dev Destination for Legion fees
        address legionFeeReceiver;
        /// @notice Address of the referrer fee receiver
        /// @dev Destination for referrer fees
        address referrerFeeReceiver;
        /// @notice Signer address of Legion
        /// @dev Address for signature verification
        address legionSigner;
        /// @notice Address of Legion's Address Registry contract
        /// @dev Registry address
        address addressRegistry;
        /// @notice Indicates if tokens have been supplied by the project
        /// @dev Supply status
        bool tokensSupplied;
    }

    struct InvestorPosition {
        /// @notice Flag indicating if investor has settled tokens
        /// @dev Settlement status
        bool hasSettled;
        /// @notice Address of the investor's vesting contract
        /// @dev Vesting contract address
        address vestingAddress;
    }

    /**
     * @notice Initializes the token distributor with parameters
     * @dev Must be implemented to set up distributor configuration; callable only once
     * @param tokenDistributorInitParams Calldata struct with initialization parameters
     */
    function initialize(TokenDistributorInitializationParams calldata tokenDistributorInitParams) external;

    /**
     * @notice Supplies tokens for distribution post-TGE
     * @dev Must be restricted to Project; handles token and fee transfers
     * @param amount Amount of tokens to supply
     * @param legionFee Fee amount for Legion
     * @param referrerFee Fee amount for referrer
     */
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;

    /**
     * @notice Performs an emergency withdrawal of tokens
     * @dev Must be restricted to Legion; used for safety measures
     * @param receiver Address to receive tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /**
     * @notice Allows investors to claim their token allocation
     * @dev Handles vesting and immediate distribution; requires signatures
     * @param claimAmount Maximum capital allowed per SAFT
     * @param investorVestingConfig Vesting configuration for the investor
     * @param claimSignature Signature verifying investment eligibility
     * @param vestingSignature Signature verifying vesting terms
     */
    function claimTokenAllocation(
        uint256 claimAmount,
        ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes memory claimSignature,
        bytes memory vestingSignature
    )
        external;

    /**
     * @notice Releases vested tokens to the investor
     * @dev Must interact with vesting contract to release tokens
     */
    function releaseVestedTokens() external;

    /**
     * @notice Syncs Legion addresses from the address registry
     * @dev Must update configuration with latest addresses
     */
    function syncLegionAddresses() external;

    /**
     * @notice Pauses the distribution
     * @dev Must halt distributor operations
     */
    function pauseDistribution() external;

    /**
     * @notice Unpauses the distribution
     * @dev Must resume distributor operations
     */
    function unpauseDistribution() external;

    /**
     * @notice Retrieves the current distributor configuration
     * @dev Must return the TokenDistributorConfig struct
     * @return TokenDistributorConfig memory Struct containing distributor configuration
     */
    function distributorConfiguration() external view returns (TokenDistributorConfig memory);

    /**
     * @notice Retrieves an investor's position details
     * @dev Must return the InvestorPosition struct for the specified address
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);

    /**
     * @notice Retrieves an investor's vesting status
     * @dev Must return vesting details if applicable
     * @param investor Address of the investor
     * @return ILegionVestingManager.LegionInvestorVestingStatus memory Struct containing vesting status
     */
    function investorVestingStatus(address investor)
        external
        view
        returns (ILegionVestingManager.LegionInvestorVestingStatus memory);
}
