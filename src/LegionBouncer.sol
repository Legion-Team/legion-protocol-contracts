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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";

import { ILegionBouncer } from "./interfaces/ILegionBouncer.sol";

/**
 * @title Legion Bouncer
 * @author Legion
 * @notice A contract used to maintain access control for the Legion Protocol
 */
contract LegionBouncer is ILegionBouncer, OwnableRoles {
    using Address for address;

    /// @dev Constant representing the broadcaster role
    uint256 public constant BROADCASTER_ROLE = _ROLE_0;

    /**
     * @dev Constructor to initialize the Legion Bouncer contract
     *
     * @param defaultAdmin The address that will have the default admin role
     * @param defaultBroadcaster The address that will have the default broadcaster role
     */
    constructor(address defaultAdmin, address defaultBroadcaster) {
        // Grant the default admin role
        _initializeOwner(defaultAdmin);

        // Grant the default broadcaster role
        _grantRoles(defaultBroadcaster, BROADCASTER_ROLE);
    }

    /**
     * @notice Executes a function call on a target contract
     * @dev Only callable by addresses with the BROADCASTER_ROLE
     *
     * @param target The address of the contract to call
     * @param data The encoded function data to execute
     */
    function functionCall(address target, bytes memory data) external onlyRoles(BROADCASTER_ROLE) {
        target.functionCall(data);
    }
}
