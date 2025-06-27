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

import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";

/**
 * @title Legion Address Registry
 * @author Legion
 * @notice Maintains a registry of all addresses used in the Legion Protocol.
 * @dev Provides a centralized mapping of unique identifiers to addresses for the Legion ecosystem.
 */
contract LegionAddressRegistry is ILegionAddressRegistry, Ownable {
    /// @dev Mapping of unique identifiers to their corresponding Legion addresses.
    mapping(bytes32 => address) private s_legionAddresses;

    /// @dev @notice Constructor for the LegionAddressRegistry contract.
    /// @dev @dev Initializes ownership during contract deployment.
    /// @dev @param newOwner The address to be set as the initial owner of the registry.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionAddressRegistry
    function setLegionAddress(bytes32 id, address updatedAddress) external onlyOwner {
        // Cache the previous address before update
        address previousAddress = s_legionAddresses[id];

        // Update the address in the state
        s_legionAddresses[id] = updatedAddress;

        // Emit event for address update
        emit LegionAddressSet(id, previousAddress, updatedAddress);
    }

    /// @inheritdoc ILegionAddressRegistry
    function getLegionAddress(bytes32 id) external view returns (address) {
        return s_legionAddresses[id];
    }
}
