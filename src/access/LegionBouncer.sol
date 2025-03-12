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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";

import { ILegionBouncer } from "../interfaces/access/ILegionBouncer.sol";

/**
 * @title Legion Bouncer
 * @author Legion
 * @notice A contract used to maintain access control for the Legion Protocol
 * @dev Implements role-based access control using OwnableRoles for managing broadcaster permissions
 */
contract LegionBouncer is ILegionBouncer, OwnableRoles {
    using Address for address;

    /// @notice Constant representing the broadcaster role identifier
    /// @dev Used to check permissions for function calls, corresponds to _ROLE_0
    uint256 public constant BROADCASTER_ROLE = _ROLE_0;

    /**
     * @notice Initializes the Legion Bouncer contract with default roles
     * @dev Sets up initial admin and broadcaster roles during deployment
     * @param defaultAdmin Address to receive the default admin role
     * @param defaultBroadcaster Address to receive the default broadcaster role
     */
    constructor(address defaultAdmin, address defaultBroadcaster) {
        // Grant the default admin role
        _initializeOwner(defaultAdmin);

        // Grant the default broadcaster role
        _grantRoles(defaultBroadcaster, BROADCASTER_ROLE);
    }

    /**
     * @notice Executes a function call on a target contract
     * @dev Performs a low-level call to the target address with provided data
     *      Only callable by addresses with BROADCASTER_ROLE
     * @param target Address of the contract to call
     * @param data Encoded function data to execute on the target contract
     */
    function functionCall(address target, bytes memory data) external onlyRoles(BROADCASTER_ROLE) {
        target.functionCall(data);
    }
}
