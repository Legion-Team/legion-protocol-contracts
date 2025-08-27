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

import { MerkleProofLib } from "@solady/src/utils/MerkleProofLib.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionReferrerFeeDistributor } from "../interfaces/distribution/ILegionReferrerFeeDistributor.sol";

/**
 * @title Legion Referrer Fee Distributor
 * @author Legion
 * @notice Manages the distribution of referrer fees in the Legion Protocol.
 * @dev This contract is responsible for distributing fees to referrers based on their referrals.
 */
contract LegionReferrerFeeDistributor is ILegionReferrerFeeDistributor, Pausable {
    /// @dev Configuration for the Referrer Fee Distributor.
    ReferrerFeeDistributorConfig private s_feeDistributorConfig;

    /// @notice Mapping of referrer addresses to their respective claimed amounts.
    mapping(address s_referrer => uint256 s_claimedAmount) public s_claimedAmounts;

    /// @notice Restricts function access to the Legion bouncer only.
    /// @dev Reverts if the caller is not the configured Legion bouncer.
    modifier onlyLegion() {
        if (msg.sender != s_feeDistributorConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /// @notice Initializes the contract with initialization parameters.
    /// @param feeDistributorInitParams The initialization parameters for the fee distributor.
    constructor(ReferrerFeeDistributorInitializationParams memory feeDistributorInitParams) {
        _setFeeDistributorConfig(feeDistributorInitParams);
    }

    /// @inheritdoc ILegionReferrerFeeDistributor
    function setMerkleRoot(bytes32 merkleRoot) external onlyLegion {
        // Set the Merkle root for referrer fee distribution
        s_feeDistributorConfig.merkleRoot = merkleRoot;

        // Emit MerkleRootSet
        emit MerkleRootSet(merkleRoot);
    }

    /// @inheritdoc ILegionReferrerFeeDistributor
    function claim(uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused {
        // Generate the leaf node using the referrer address and the amount
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));

        // Verify the Merkle proof against the stored Merkle root
        if (!MerkleProofLib.verify(merkleProof, s_feeDistributorConfig.merkleRoot, leaf)) {
            revert Errors.LegionSale__InvalidMerkleProof();
        }

        // Get the already claimed amount for the referrer
        uint256 amountClaimed = s_claimedAmounts[msg.sender];

        // Get the amount remaining to be claimed
        uint256 amountToClaim = amount - amountClaimed;

        // If the amount to claim is zero, revert
        if (amountToClaim == 0) revert Errors.LegionSale__InvalidWithdrawAmount(amountToClaim);

        // Update the claimed amount
        s_claimedAmounts[msg.sender] += amountToClaim;

        // Update the total referrer fees distributed
        s_feeDistributorConfig.totalReferrerFeesDistributed += amountToClaim;

        // Emit ReferrerFeeClaimed
        emit ReferrerFeeClaimed(msg.sender, amountToClaim);

        // Transfer the tokens to the referrer
        SafeTransferLib.safeTransfer(s_feeDistributorConfig.token, msg.sender, amountToClaim);
    }

    /// @inheritdoc ILegionReferrerFeeDistributor
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        // Emit EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /// @inheritdoc ILegionReferrerFeeDistributor
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /// @inheritdoc ILegionReferrerFeeDistributor
    function pause() external onlyLegion {
        // Pause the distribution
        _pause();
    }

    /// @inheritdoc ILegionReferrerFeeDistributor
    function unpause() external onlyLegion {
        // Unpause the distribution
        _unpause();
    }

    /// @inheritdoc ILegionReferrerFeeDistributor
    function referrerFeeDistributorConfiguration() external view returns (ReferrerFeeDistributorConfig memory) {
        return s_feeDistributorConfig;
    }

    /// @dev Sets the distributor configuration during initialization
    /// @param _feeDistributorInitParams The initialization parameters to configure the distributor.
    function _setFeeDistributorConfig(ReferrerFeeDistributorInitializationParams memory _feeDistributorInitParams)
        private
    {
        // Verify if the distributor configuration is valid
        _verifyValidConfig(_feeDistributorInitParams);

        // Initialize fee distributor configuration
        s_feeDistributorConfig.token = _feeDistributorInitParams.token;
        s_feeDistributorConfig.addressRegistry = _feeDistributorInitParams.addressRegistry;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /// @dev Synchronizes Legion addresses from the address registry.
    function _syncLegionAddresses() private {
        // Cache Legion addresses from `LegionAddressRegistry`
        s_feeDistributorConfig.legionBouncer =
            ILegionAddressRegistry(s_feeDistributorConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);

        // Emit LegionAddressesSynced
        emit LegionAddressesSynced(s_feeDistributorConfig.legionBouncer);
    }

    /// @dev Validates the fee distributor configuration parameters during initialization.
    /// @param _feeDistributorInitParams The initialization parameters to validate.
    function _verifyValidConfig(ReferrerFeeDistributorInitializationParams memory _feeDistributorInitParams)
        private
        pure
    {
        // Check for zero addresses provided
        if (_feeDistributorInitParams.addressRegistry == address(0) || _feeDistributorInitParams.token == address(0)) {
            revert Errors.LegionSale__ZeroAddressProvided();
        }
    }
}
