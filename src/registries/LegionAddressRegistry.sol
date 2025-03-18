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
//
// If you find a bug, please contact security[at]legion.cc
// We will pay a fair bounty for any issue that puts users' funds at risk.

import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";

/**
 * @title Legion Address Registry
 * @author Legion
 * @notice A contract used to maintain the state of all addresses used in the Legion Protocol
 * @dev Manages a mapping of unique identifiers to addresses for the Legion ecosystem; restricted to owner
 */
contract LegionAddressRegistry is ILegionAddressRegistry, Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Mapping of unique identifiers to their corresponding Legion addresses
    /// @dev Stores the registry state as a private mapping
    mapping(bytes32 => address) private _legionAddresses;

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the LegionAddressRegistry with an owner
     * @dev Sets up ownership during contract deployment
     * @param newOwner Address to be set as the initial owner of the registry
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets a Legion address for a given identifier
     * @dev Updates the address mapping and emits an event; only callable by the owner
     * @param id Unique identifier (bytes32) for the address
     * @param updatedAddress New address to associate with the identifier
     */
    function setLegionAddress(bytes32 id, address updatedAddress) external onlyOwner {
        // Cache the previous address before update
        address previousAddress = _legionAddresses[id];

        // Update the address in the state
        _legionAddresses[id] = updatedAddress;

        // Emit event for address update
        emit LegionAddressSet(id, previousAddress, updatedAddress);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves the Legion address associated with a given identifier
     * @dev Returns the address stored in the mapping for the specified id
     * @param id Unique identifier (bytes32) for the address
     * @return Registered Legion address associated with the identifier
     */
    function getLegionAddress(bytes32 id) external view returns (address) {
        return _legionAddresses[id];
    }
}
