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

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionTokenDistributor } from "../interfaces/distribution/ILegionTokenDistributor.sol";
import { ILegionVesting } from "../interfaces/vesting/ILegionVesting.sol";

import { LegionVestingManager } from "../vesting/LegionVestingManager.sol";

/**
 * @title Legion Token Distributor
 * @author Legion
 * @notice Contract for managing token distribution of ERC20 tokens sold through the Legion Protocol
 */
contract LegionTokenDistributor is ILegionTokenDistributor, LegionVestingManager, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Token distributor configuration
    /// @dev Struct containing distributor configuration
    TokenDistributorConfig private s_tokenDistributorConfig;

    /// @notice Mapping of investor addresses to their positions
    /// @dev Investor data
    mapping(address s_investorAddress => InvestorPosition s_investorPosition) private s_investorPositions;

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to the Legion address only
     * @dev Reverts if caller is not the configured Legion bouncer address
     */
    modifier onlyLegion() {
        if (msg.sender != s_tokenDistributorConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /**
     * @notice Restricts function access to the Project admin only
     * @dev Reverts if caller is not the configured project admin address
     */
    modifier onlyProject() {
        if (msg.sender != s_tokenDistributorConfig.projectAdmin) revert Errors.LegionSale__NotCalledByProject();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for LegionTokenDistributor
     * @dev Disables initializers to prevent uninitialized deployment
     */
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the token distributor contract with parameters
     * @dev Sets up distributor configuration
     * @param tokenDistributorInitParams Calldata struct with token distributor initialization parameters
     */
    function initialize(TokenDistributorInitializationParams calldata tokenDistributorInitParams)
        external
        initializer
    {
        _setTokenDistributorConfig(tokenDistributorInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Supplies tokens for distribution post-TGE
     * @dev Transfers tokens and fees; restricted to Project
     * @param amount Amount of tokens to supply
     * @param legionFee Fee amount for Legion
     * @param referrerFee Fee amount for referrer
     */
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external onlyProject whenNotPaused {
        // Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        // Calculate the expected Legion Fee amount
        uint256 expectedLegionFeeAmount =
            (s_tokenDistributorConfig.legionFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate the expected Referrer Fee amount
        uint256 expectedReferrerFeeAmount =
            (s_tokenDistributorConfig.referrerFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        // Verify Legion Fee amount
        if (legionFee != expectedLegionFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(legionFee, expectedLegionFeeAmount);
        }

        // Verify Referrer Fee amount
        if (referrerFee != expectedReferrerFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(referrerFee, expectedReferrerFeeAmount);
        }

        // Flag that ask tokens have been supplied
        s_tokenDistributorConfig.tokensSupplied = true;

        // Emit successfully TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        // Transfer the allocated amount of tokens for distribution to the contract
        SafeTransferLib.safeTransferFrom(s_tokenDistributorConfig.askToken, msg.sender, address(this), amount);

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(
                s_tokenDistributorConfig.askToken, msg.sender, s_tokenDistributorConfig.legionFeeReceiver, legionFee
            );
        }

        // Transfer the Referrer fee to the Referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                s_tokenDistributorConfig.askToken, msg.sender, s_tokenDistributorConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /**
     * @notice Withdraws tokens in emergency situations
     * @dev Restricted to Legion; used for safety measures
     * @param receiver Address to receive withdrawn tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        // Emit successfully EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /**
     * @notice Allows investors to claim their token allocation
     * @dev Handles vesting and immediate distribution; requires signatures
     * @param claimAmount The claim amount for the investor
     * @param investorVestingConfig Vesting configuration for the investor
     * @param claimSignature Signature verifying claim elegibility
     * @param vestingSignature Signature verifying vesting terms
     */
    function claimTokenAllocation(
        uint256 claimAmount,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes memory claimSignature,
        bytes memory vestingSignature
    )
        external
        whenNotPaused
    {
        // Verify that the vesting configuration is valid
        _verifyValidVestingConfig(investorVestingConfig);

        // Verify that the investor can claim the token allocation
        _verifyCanClaimTokenAllocation();

        // Verify that the investor position is valid
        _verifyValidPosition(claimAmount, claimSignature);

        // Verify that the investor vesting terms are valid
        _verifyValidVestingPosition(vestingSignature, investorVestingConfig);

        // Load the investor position
        InvestorPosition storage position = s_investorPositions[msg.sender];

        // Mark that the position has been settled
        position.hasSettled = true;

        // Update the total amount claimed
        s_tokenDistributorConfig.totalAmountClaimed += claimAmount;

        // Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim =
            claimAmount * investorVestingConfig.tokenAllocationOnTGERate / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        // Calculate the remaining amount to be vested
        uint256 amountToBeVested = claimAmount - amountToDistributeOnClaim;

        // Emit successfully TokenAllocationClaimed
        emit TokenAllocationClaimed(amountToBeVested, amountToDistributeOnClaim, msg.sender);

        // Deploy vesting and distribute tokens only if there is anything to distribute
        if (amountToBeVested != 0) {
            // Deploy a vesting contract for the investor
            address payable vestingAddress = _createVesting(investorVestingConfig);

            // Save the vesting contract address for the investor
            position.vestingAddress = vestingAddress;

            // Transfer the allocated amount of tokens for distribution to the vesting contract
            SafeTransferLib.safeTransfer(s_tokenDistributorConfig.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            // Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(s_tokenDistributorConfig.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /**
     * @notice Releases vested tokens to the investor
     * @dev Calls vesting contract to release tokens
     */
    function releaseVestedTokens() external whenNotPaused {
        // Get the investor position details
        InvestorPosition memory position = s_investorPositions[msg.sender];

        // Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert Errors.LegionSale__ZeroAddressProvided();

        // Release tokens to the investor account
        ILegionVesting(position.vestingAddress).release(s_tokenDistributorConfig.askToken);
    }

    /**
     * @notice Syncs Legion addresses from the address registry
     * @dev Updates configuration with latest addresses; restricted to Legion
     */
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /**
     * @notice Pauses the distribution
     * @dev Virtual function restricted to Legion; halts operations
     */
    function pauseDistribution() external onlyLegion {
        // Pause the distribution
        _pause();
    }

    /**
     * @notice Unpauses the distribution
     * @dev Virtual function restricted to Legion; resumes operations
     */
    function unpauseDistribution() external onlyLegion {
        // Unpause the distribution
        _unpause();
    }

    /**
     * @notice Returns the current distributor configuration
     * @dev Provides read-only access to s_tokenDistributorConfig
     * @return TokenDistributorConfig memory Struct containing distributor configuration
     */
    function distributorConfiguration() external view returns (TokenDistributorConfig memory) {
        return s_tokenDistributorConfig;
    }

    /**
     * @notice Returns an investor's position details
     * @dev Provides read-only access to investor position
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory) {
        return s_investorPositions[investorAddress];
    }

    /**
     * @notice Returns an investor's vesting status
     * @dev Queries vesting contract if applicable
     * @param investor Address of the investor
     * @return vestingStatus LegionInvestorVestingStatus memory Struct containing vesting status details
     */
    function investorVestingStatus(address investor)
        external
        view
        returns (LegionInvestorVestingStatus memory vestingStatus)
    {
        // Get the investor position details
        address investorVestingAddress = s_investorPositions[investor].vestingAddress;

        // Return the investor vesting status
        investorVestingAddress != address(0)
            ? vestingStatus = LegionInvestorVestingStatus(
                ILegionVesting(investorVestingAddress).start(),
                ILegionVesting(investorVestingAddress).end(),
                ILegionVesting(investorVestingAddress).cliffEndTimestamp(),
                ILegionVesting(investorVestingAddress).duration(),
                ILegionVesting(investorVestingAddress).released(s_tokenDistributorConfig.askToken),
                ILegionVesting(investorVestingAddress).releasable(s_tokenDistributorConfig.askToken),
                ILegionVesting(investorVestingAddress).vestedAmount(
                    s_tokenDistributorConfig.askToken, uint64(block.timestamp)
                )
            )
            : vestingStatus;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the distributor parameters during initialization
     * @dev Internal function to configure distributor;
     * @param tokenDistributorInitParams Calldata struct with initialization parameters
     */
    function _setTokenDistributorConfig(TokenDistributorInitializationParams calldata tokenDistributorInitParams)
        private
        onlyInitializing
    {
        // Verify if the distributor configuration is valid
        _verifyValidConfig(tokenDistributorInitParams);

        // Initialize distributor configuration
        s_tokenDistributorConfig.totalAmountToDistribute = tokenDistributorInitParams.totalAmountToDistribute;
        s_tokenDistributorConfig.legionFeeOnTokensSoldBps = tokenDistributorInitParams.legionFeeOnTokensSoldBps;
        s_tokenDistributorConfig.referrerFeeOnTokensSoldBps = tokenDistributorInitParams.referrerFeeOnTokensSoldBps;
        s_tokenDistributorConfig.referrerFeeReceiver = tokenDistributorInitParams.referrerFeeReceiver;
        s_tokenDistributorConfig.askToken = tokenDistributorInitParams.askToken;
        s_tokenDistributorConfig.addressRegistry = tokenDistributorInitParams.addressRegistry;
        s_tokenDistributorConfig.projectAdmin = tokenDistributorInitParams.projectAdmin;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /**
     * @notice Syncs Legion addresses from the registry
     * @dev Updates configuration with latest addresses; virtual for overrides
     */
    function _syncLegionAddresses() private {
        // Cache Legion addresses from `LegionAddressRegistry`
        s_tokenDistributorConfig.legionBouncer = ILegionAddressRegistry(s_tokenDistributorConfig.addressRegistry)
            .getLegionAddress(Constants.LEGION_BOUNCER_ID);
        s_tokenDistributorConfig.legionSigner = ILegionAddressRegistry(s_tokenDistributorConfig.addressRegistry)
            .getLegionAddress(Constants.LEGION_SIGNER_ID);
        s_tokenDistributorConfig.legionFeeReceiver = ILegionAddressRegistry(s_tokenDistributorConfig.addressRegistry)
            .getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);
        s_vestingConfig.vestingFactory = ILegionAddressRegistry(s_tokenDistributorConfig.addressRegistry)
            .getLegionAddress(Constants.LEGION_VESTING_FACTORY_ID);

        // Emit successfully LegionAddressesSynced
        emit LegionAddressesSynced(
            s_tokenDistributorConfig.legionBouncer,
            s_tokenDistributorConfig.legionSigner,
            s_tokenDistributorConfig.legionFeeReceiver,
            s_vestingConfig.vestingFactory
        );
    }

    /**
     * @notice Validates an investor's vesting position
     * @dev Verifies vesting signature and configuration
     * @param vestingSignature Signature proving vesting terms
     * @param investorVestingConfig Vesting configuration to verify
     */
    function _verifyValidVestingPosition(
        bytes memory vestingSignature,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig
    )
        private
        view
    {
        // Construct the signed data
        bytes32 _data = keccak256(abi.encode(msg.sender, address(this), block.chainid, investorVestingConfig))
            .toEthSignedMessageHash();

        // Verify the signature
        if (_data.recover(vestingSignature) != s_tokenDistributorConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(vestingSignature);
        }
    }

    /**
     * @notice Validates the distributor configuration parameters
     * @dev Checks for invalid values and addresses
     * @param _tokenDistributorInitParams Calldata struct with initialization parameters
     */
    function _verifyValidConfig(TokenDistributorInitializationParams calldata _tokenDistributorInitParams)
        private
        pure
    {
        // Check for zero addresses provided
        if (
            _tokenDistributorInitParams.projectAdmin == address(0)
                || _tokenDistributorInitParams.addressRegistry == address(0)
                || _tokenDistributorInitParams.askToken == address(0)
        ) revert Errors.LegionSale__ZeroAddressProvided();

        // Check for zero values provided
        if (_tokenDistributorInitParams.totalAmountToDistribute == 0) {
            revert Errors.LegionSale__ZeroValueProvided();
        }
    }

    /**
     * @notice Verifies conditions for supplying tokens
     * @dev Ensures allocation and supply state are valid
     * @param _amount Amount of tokens to supply
     */
    function _verifyCanSupplyTokens(uint256 _amount) private view {
        // Revert if tokens have already been supplied
        if (s_tokenDistributorConfig.tokensSupplied) revert Errors.LegionSale__TokensAlreadySupplied();

        // Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != s_tokenDistributorConfig.totalAmountToDistribute) {
            revert Errors.LegionSale__InvalidTokenAmountSupplied(
                _amount, s_tokenDistributorConfig.totalAmountToDistribute
            );
        }
    }

    /**
     * @notice Verifies conditions for claiming token allocation
     * @dev Checks supply and settlement status
     */
    function _verifyCanClaimTokenAllocation() internal view {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[msg.sender];

        // Check if the askToken has been supplied to the distributor
        if (!s_tokenDistributorConfig.tokensSupplied) revert Errors.LegionSale__TokensNotSupplied();

        // Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.LegionSale__AlreadySettled(msg.sender);
    }

    /**
     * @notice Validates an investor's position
     * @dev Verifies investment amount and signature
     * @param claimAmount Maximum capital allowed per SAFT
     * @param signature Signature to verify
     */
    function _verifyValidPosition(uint256 claimAmount, bytes memory signature) internal view {
        // Construct the signed data
        bytes32 _data = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid, uint256(claimAmount)))
            .toEthSignedMessageHash();

        // Verify the signature
        if (_data.recover(signature) != s_tokenDistributorConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(signature);
        }
    }
}
