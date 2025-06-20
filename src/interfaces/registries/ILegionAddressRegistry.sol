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

/**
 * @title ILegionAddressRegistry
 * @author Legion
 * @notice Interface for managing Legion Protocol addresses
 * @dev Defines events and functions for address registry operations
 */
interface ILegionAddressRegistry {
    /**
     * @notice Emitted when a Legion address is set or updated
     * @dev Provides details about address changes in the registry
     * @param id Unique identifier (bytes32) of the address
     * @param previousAddress Address previously associated with the identifier
     * @param updatedAddress New address associated with the identifier
     */
    event LegionAddressSet(bytes32 id, address previousAddress, address updatedAddress);

    /**
     * @notice Sets a Legion address for a given identifier
     * @dev Must be implemented to update the address registry
     * @param id Unique identifier (bytes32) of the address
     * @param updatedAddress New address to associate with the identifier
     */
    function setLegionAddress(bytes32 id, address updatedAddress) external;

    /**
     * @notice Retrieves the Legion address associated with a given identifier
     * @dev Must be implemented to return the registered address for the specified id
     * @param id Unique identifier (bytes32) of the address
     * @return Registered Legion address associated with the identifier
     */
    function getLegionAddress(bytes32 id) external view returns (address);
}
