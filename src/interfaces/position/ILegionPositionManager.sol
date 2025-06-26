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
 * @title ILegionPositionManager
 * @author Legion
 * @notice Interface for the LegionPositionManager contract.
 */
interface ILegionPositionManager {
    /// @dev Struct to hold the configuration parameters for the Legion Position Manager.
    struct LegionPositionManagerConfig {
        // The name of the sale for which positions are being managed.
        string name;
        // The symbol associated with the sale for which positions are being managed.
        string symbol;
        // The base URI used to construct the metadata URI for each position.
        string baseURI;
        // The ID of the last position created, used to track position creation.
        uint256 lastPositionId;
    }

    /// @notice Transfers an investor position from one address to another.
    /// @param from The address of the current owner.
    /// @param to The address of the new owner.
    /// @param positionId The ID of the position to transfer.
    function transferInvestorPosition(address from, address to, uint256 positionId) external;

    /// @notice Transfers an investor position with cryptographic authorization.
    /// @param from The address of the current owner.
    /// @param to The address of the new owner.
    /// @param positionId The ID of the position to transfer.
    /// @param signature The cryptographic signature authorizing the transfer.
    function transferInvestorPositionWithAuthorization(
        address from,
        address to,
        uint256 positionId,
        bytes calldata signature
    )
        external;
}
