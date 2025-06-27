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
 * @notice Manages the distribution of ERC20 tokens sold through the Legion Protocol.
 * @dev Handles token allocation claims, vesting deployment, and emergency operations with signature verification.
 */
contract LegionTokenDistributor is ILegionTokenDistributor, LegionVestingManager, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev Token distributor configuration
    TokenDistributorConfig private s_tokenDistributorConfig;

    /// @dev Mapping of investor addresses to their positions.
    mapping(address s_investorAddress => InvestorPosition s_investorPosition) private s_investorPositions;

    /// @notice Restricts function access to the Legion bouncer only.
    /// @dev Reverts if the caller is not the configured Legion bouncer.
    modifier onlyLegion() {
        if (msg.sender != s_tokenDistributorConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /// @notice Restricts function access to the project admin only.
    /// @dev Reverts if the caller is not the configured project admin.
    modifier onlyProject() {
        if (msg.sender != s_tokenDistributorConfig.projectAdmin) revert Errors.LegionSale__NotCalledByProject();
        _;
    }

    /// @notice Constructs the LegionTokenDistributor and disables initializers.
    /// @dev Prevents the implementation contract from being initialized directly.
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /// @inheritdoc ILegionTokenDistributor
    function initialize(TokenDistributorInitializationParams calldata tokenDistributorInitParams)
        external
        initializer
    {
        _setTokenDistributorConfig(tokenDistributorInitParams);
    }

    /// @inheritdoc ILegionTokenDistributor
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external onlyProject whenNotPaused {
        // Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        // Flag that ask tokens have been supplied
        s_tokenDistributorConfig.tokensSupplied = true;

        // Load the token distributor configuration
        TokenDistributorConfig memory tokenDistributorConfig = s_tokenDistributorConfig;

        // Calculate the expected Legion Fee amount
        uint256 expectedLegionFeeAmount =
            (tokenDistributorConfig.legionFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate the expected Referrer Fee amount
        uint256 expectedReferrerFeeAmount =
            (tokenDistributorConfig.referrerFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        // Verify Legion Fee amount
        if (legionFee != expectedLegionFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(legionFee, expectedLegionFeeAmount);
        }

        // Verify Referrer Fee amount
        if (referrerFee != expectedReferrerFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(referrerFee, expectedReferrerFeeAmount);
        }

        // Emit successfully TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        // Transfer the allocated amount of tokens for distribution to the contract
        SafeTransferLib.safeTransferFrom(tokenDistributorConfig.askToken, msg.sender, address(this), amount);

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(
                tokenDistributorConfig.askToken, msg.sender, tokenDistributorConfig.legionFeeReceiver, legionFee
            );
        }

        // Transfer the Referrer fee to the Referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                tokenDistributorConfig.askToken, msg.sender, tokenDistributorConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /// @inheritdoc ILegionTokenDistributor
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        // Emit successfully EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /// @inheritdoc ILegionTokenDistributor
    function claimTokenAllocation(
        uint256 claimAmount,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes calldata claimSignature,
        bytes calldata vestingSignature
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

        // Load the token distributor configuration
        TokenDistributorConfig memory tokenDistributorConfig = s_tokenDistributorConfig;

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
            SafeTransferLib.safeTransfer(tokenDistributorConfig.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            // Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(tokenDistributorConfig.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /// @inheritdoc ILegionTokenDistributor
    function releaseVestedTokens() external whenNotPaused {
        // Get the investor vesting address
        address investorVestingAddress = s_investorPositions[msg.sender].vestingAddress;

        // Revert in case there's no vesting for the investor
        if (investorVestingAddress == address(0)) revert Errors.LegionSale__ZeroAddressProvided();

        // Release tokens to the investor account
        ILegionVesting(investorVestingAddress).release(s_tokenDistributorConfig.askToken);
    }

    /// @inheritdoc ILegionTokenDistributor
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /// @inheritdoc ILegionTokenDistributor
    function pause() external onlyLegion {
        _pause();
    }

    /// @inheritdoc ILegionTokenDistributor
    function unpause() external onlyLegion {
        _unpause();
    }

    /// @inheritdoc ILegionTokenDistributor
    function distributorConfiguration() external view returns (TokenDistributorConfig memory) {
        return s_tokenDistributorConfig;
    }

    /// @inheritdoc ILegionTokenDistributor
    function investorPosition(address investor) external view returns (InvestorPosition memory) {
        return s_investorPositions[investor];
    }

    /// @inheritdoc ILegionTokenDistributor
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

    /// @dev Sets the distributor configuration during initialization
    /// @param _tokenDistributorInitParams The initialization parameters to configure the distributor.
    function _setTokenDistributorConfig(TokenDistributorInitializationParams calldata _tokenDistributorInitParams)
        private
        onlyInitializing
    {
        // Verify if the distributor configuration is valid
        _verifyValidConfig(_tokenDistributorInitParams);

        // Initialize distributor configuration
        s_tokenDistributorConfig.totalAmountToDistribute = _tokenDistributorInitParams.totalAmountToDistribute;
        s_tokenDistributorConfig.legionFeeOnTokensSoldBps = _tokenDistributorInitParams.legionFeeOnTokensSoldBps;
        s_tokenDistributorConfig.referrerFeeOnTokensSoldBps = _tokenDistributorInitParams.referrerFeeOnTokensSoldBps;
        s_tokenDistributorConfig.referrerFeeReceiver = _tokenDistributorInitParams.referrerFeeReceiver;
        s_tokenDistributorConfig.askToken = _tokenDistributorInitParams.askToken;
        s_tokenDistributorConfig.addressRegistry = _tokenDistributorInitParams.addressRegistry;
        s_tokenDistributorConfig.projectAdmin = _tokenDistributorInitParams.projectAdmin;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /// @dev Synchronizes Legion addresses from the address registry.
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

    /// @dev Validates an investor's vesting position using signature verification.
    /// @param _vestingSignature The signature proving the vesting terms are authorized.
    /// @param _investorVestingConfig The vesting configuration to verify.
    function _verifyValidVestingPosition(
        bytes calldata _vestingSignature,
        LegionVestingManager.LegionInvestorVestingConfig calldata _investorVestingConfig
    )
        private
        view
    {
        // Construct the signed data
        bytes32 _data = keccak256(abi.encode(msg.sender, address(this), block.chainid, _investorVestingConfig))
            .toEthSignedMessageHash();

        // Verify the signature
        if (_data.recover(_vestingSignature) != s_tokenDistributorConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_vestingSignature);
        }
    }

    /// @dev Validates the distributor configuration parameters during initialization.
    /// @param _tokenDistributorInitParams The initialization parameters to validate.
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

    /// @dev Verifies that tokens can be supplied for distribution.
    /// @param _amount The amount of tokens to be supplied.
    function _verifyCanSupplyTokens(uint256 _amount) private view {
        // Load the token distributor configuration
        TokenDistributorConfig memory tokenDistributorConfig = s_tokenDistributorConfig;

        // Revert if tokens have already been supplied
        if (tokenDistributorConfig.tokensSupplied) revert Errors.LegionSale__TokensAlreadySupplied();

        // Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != tokenDistributorConfig.totalAmountToDistribute) {
            revert Errors.LegionSale__InvalidTokenAmountSupplied(
                _amount, tokenDistributorConfig.totalAmountToDistribute
            );
        }
    }

    /// @dev Verifies that an investor can claim their token allocation.
    function _verifyCanClaimTokenAllocation() internal view {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[msg.sender];

        // Check if the askToken has been supplied to the distributor
        if (!s_tokenDistributorConfig.tokensSupplied) revert Errors.LegionSale__TokensNotSupplied();

        // Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.LegionSale__AlreadySettled(msg.sender);
    }

    /// @dev Validates an investor's position using signature verification.
    /// @param _claimAmount The amount of tokens the investor is claiming.
    /// @param _signature The signature to verify the claim authorization.
    function _verifyValidPosition(uint256 _claimAmount, bytes calldata _signature) internal view {
        // Construct the signed data
        bytes32 _data =
            keccak256(abi.encodePacked(msg.sender, address(this), block.chainid, _claimAmount)).toEthSignedMessageHash();

        // Verify the signature
        if (_data.recover(_signature) != s_tokenDistributorConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_signature);
        }
    }
}
