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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";

import { ILegionBouncer } from "../interfaces/access/ILegionBouncer.sol";

/**
 * @title Legion Bouncer
 * @author Legion
 * @notice Provides access control for the Legion Protocol through role-based permissions.
 * @dev Implements role-based access control using OwnableRoles to manage broadcaster permissions for executing calls on
 * target contracts.
 */
contract LegionBouncer is ILegionBouncer, OwnableRoles {
    using Address for address;

    /// @notice The role identifier for broadcaster permissions.
    /// @dev Used to check permissions for function calls, corresponds to _ROLE_0.
    uint256 public constant BROADCASTER_ROLE = _ROLE_0;

    /// @notice Constructor for the Legion Bouncer contract.
    /// @param defaultAdmin The address to receive the default admin role.
    /// @param defaultBroadcaster The address to receive the default broadcaster role.
    constructor(address defaultAdmin, address defaultBroadcaster) {
        // Grant the default admin role
        _initializeOwner(defaultAdmin);

        // Grant the default broadcaster role
        _grantRoles(defaultBroadcaster, BROADCASTER_ROLE);
    }

    /// @inheritdoc ILegionBouncer
    function functionCall(address target, bytes memory data) external onlyRoles(BROADCASTER_ROLE) {
        target.functionCall(data);
    }
}
