// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionAddressRegistry } from "./interfaces/ILegionAddressRegistry.sol";

/**
 * @title Legion Address Registry
 * @author Legion
 * @notice A contract used to maintain the state of all addresses used in the Legion Protocol
 */
contract LegionAddressRegistry is ILegionAddressRegistry, Ownable {
    /// @dev Mapping of unique identifiers to Legion addresses
    mapping(bytes32 => address) private _legionAddresses;

    /**
     * @dev Constructor to initialize the LegionAddressRegistry
     *
     * @param newOwner The owner of the registry contract
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /**
     * @notice Sets a Legion address for the given identifier
     *
     * @param id The unique identifier for the address
     * @param updatedAddress The new address to set
     */
    function setLegionAddress(bytes32 id, address updatedAddress) external onlyOwner {
        // Cache the previous address before update
        address previousAddress = _legionAddresses[id];

        // Update the address in the state
        _legionAddresses[id] = updatedAddress;

        // Emit event for address update
        emit LegionAddressSet(id, previousAddress, updatedAddress);
    }

    /**
     * @notice Returns the Legion address for the given identifier
     *
     * @param id The unique identifier for the address
     * @return The registered Legion address
     */
    function getLegionAddress(bytes32 id) public view returns (address) {
        return _legionAddresses[id];
    }
}
