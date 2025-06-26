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
 * @title ILegionAddressRegistry
 * @author Legion
 * @notice Interface for the LegionAddressRegistry contract.
 */
interface ILegionAddressRegistry {
    /// @notice Emitted when a Legion address is set or updated.
    /// @param id The unique identifier (bytes32) of the address.
    /// @param previousAddress The address previously associated with the identifier.
    /// @param updatedAddress The new address associated with the identifier.
    event LegionAddressSet(bytes32 id, address previousAddress, address updatedAddress);

    /// @notice Sets a Legion address for a given identifier.
    /// @param id The unique identifier for the address.
    /// @param updatedAddress The new address to associate with the identifier.
    function setLegionAddress(bytes32 id, address updatedAddress) external;

    /// @notice Retrieves the Legion address associated with a given identifier.
    /// @param id The unique identifier for the address.
    /// @return The registered Legion address associated with the identifier.
    function getLegionAddress(bytes32 id) external view returns (address);
}
