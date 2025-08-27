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

/**
 * @title ILegionReferrerFeeDistributor
 * @author Legion
 * @notice Interface for the LegionReferrerFeeDistributor contract.
 */
interface ILegionReferrerFeeDistributor {
    /// @dev Struct for initializing the Referrer Fee Distributor.
    struct ReferrerFeeDistributorInitializationParams {
        // Address of the token used for referrer fee distribution.
        address token;
        // Address of Legion's Address Registry contract.
        address addressRegistry;
    }

    /// @dev Struct containing the configuration for the Referrer Fee Distributor.
    struct ReferrerFeeDistributorConfig {
        // Address of Legion's Address Registry contract.
        address addressRegistry;
        // The address of the Legion bouncer contract.
        address legionBouncer;
        // The address of the token used for referrer fee distribution.
        address token;
        // The total amount of referrer fees distributed.
        uint256 totalReferrerFeesDistributed;
        // The Merkle root for referrer fee distribution.
        bytes32 merkleRoot;
    }

    /// @notice Emitted during an emergency withdrawal by Legion.
    /// @param receiver The address receiving the withdrawn tokens.
    /// @param token The address of the token withdrawn.
    /// @param amount The amount of tokens withdrawn.
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /// @notice Emitted when Legion addresses are successfully synced.
    /// @param legionBouncer The updated Legion bouncer address.
    event LegionAddressesSynced(address legionBouncer);

    /// @notice Emitted when the Merkle root is set for referrer fee distribution.
    /// @param merkleRoot The Merkle root set for the referrer fee distribution.
    event MerkleRootSet(bytes32 merkleRoot);

    /// @notice Emitted when referrer fees are claimed.
    /// @param referrer The address of the referrer claiming the fees.
    /// @param amount The total amount of referrer fees claimed.
    event ReferrerFeeClaimed(address referrer, uint256 amount);

    /// @notice Sets the Merkle root for the referrer fee distribution.
    /// @dev Can only be called by the Legion bouncer.
    /// @param merkleRoot The new Merkle root to be set.
    function setMerkleRoot(bytes32 merkleRoot) external;

    /// @notice Claims referrer fees based on the provided Merkle proof.
    /// @param amount The total aggregated amount of referrer fees to claim.
    /// @param merkleProof The Merkle proof to verify the claim.
    function claim(uint256 amount, bytes32[] calldata merkleProof) external;

    /// @notice Performs an emergency withdrawal of tokens.
    /// @param receiver The address to receive tokens.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;

    /// @notice Synchronizes Legion addresses from the address registry.
    function syncLegionAddresses() external;

    /// @notice Pauses all fee distribution operations.
    function pause() external;

    /// @notice Unpauses all fee distribution operations.
    function unpause() external;

    /// @notice Returns the current configuration of the Referrer Fee Distributor.
    function referrerFeeDistributorConfiguration() external view returns (ReferrerFeeDistributorConfig memory);
}
