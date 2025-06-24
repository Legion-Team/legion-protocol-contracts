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
 * @notice Interface for managing token distribution of ERC20 tokens sold through the Legion Protocol
 */
interface ILegionTokenDistributor {
    /// @notice Struct for initializing the Token Distributor
    struct TokenDistributorInitializationParams {
        /// @notice Legion's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage applied to sold tokens
        uint16 legionFeeOnTokensSoldBps;
        /// @notice Referrer's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage for referrer on sold tokens
        uint16 referrerFeeOnTokensSoldBps;
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
        /// @notice The total amount of tokens to be distributed
        /// @dev Total tokens available for distribution
        uint256 totalAmountToDistribute;
    }

    /// @notice Struct for storing the configuration of the Token Distributor
    struct TokenDistributorConfig {
        /// @notice Legion's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage applied to sold tokens
        uint16 legionFeeOnTokensSoldBps;
        /// @notice Referrer's fee on tokens sold in basis points (BPS)
        /// @dev Fee percentage for referrer on sold tokens
        uint16 referrerFeeOnTokensSoldBps;
        /// @notice Indicates if tokens have been supplied by the project
        /// @dev Supply status
        bool tokensSupplied;
        /// @notice The total amount of tokens to be distributed
        /// @dev Total tokens available for distribution
        uint256 totalAmountToDistribute;
        /// @notice The total amount of tokens already claimed
        /// @dev Total tokens already distributed
        uint256 totalAmountClaimed;
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
     * @notice Emitted when an investor successfully claims their token allocation
     * @param amountToBeVested Amount of tokens sent to vesting contract
     * @param amountOnClaim Amount of tokens distributed immediately
     * @param investor Address of the claiming investor
     */
    event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor);

    /**
     * @notice Emitted when tokens are supplied for distribution by the Project
     * @param amount Amount of tokens supplied
     * @param legionFee Fee amount collected by Legion
     * @param referrerFee Fee amount collected by the referrer
     */
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);

    /**
     * @notice Initializes the token distributor with parameters
     * @param tokenDistributorInitParams Calldata struct with initialization parameters
     */
    function initialize(TokenDistributorInitializationParams calldata tokenDistributorInitParams) external;

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
     * @notice Allows investors to claim their token allocation
     * @param claimAmount Maximum capital allowed per SAFT
     * @param investorVestingConfig Vesting configuration for the investor
     * @param claimSignature Signature verifying investment eligibility
     * @param vestingSignature Signature verifying vesting terms
     */
    function claimTokenAllocation(
        uint256 claimAmount,
        ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes calldata claimSignature,
        bytes calldata vestingSignature
    )
        external;

    /**
     * @notice Releases vested tokens to the investor
     */
    function releaseVestedTokens() external;

    /**
     * @notice Syncs Legion addresses from the address registry
     */
    function syncLegionAddresses() external;

    /**
     * @notice Pauses the distribution
     */
    function pauseDistribution() external;

    /**
     * @notice Unpauses the distribution
     */
    function unpauseDistribution() external;

    /**
     * @notice Retrieves the current distributor configuration
     * @return TokenDistributorConfig memory Struct containing distributor configuration
     */
    function distributorConfiguration() external view returns (TokenDistributorConfig memory);

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
