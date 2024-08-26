// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * ██      ███████  ██████  ██  ██████  ███    ██
 * ██      ██      ██       ██ ██    ██ ████   ██
 * ██      █████   ██   ███ ██ ██    ██ ██ ██  ██
 * ██      ██      ██    ██ ██ ██    ██ ██  ██ ██
 * ███████ ███████  ██████  ██  ██████  ██   ████
 *
 * If you find a bug, please contact security(at)legion.cc
 * We will pay a fair bounty for any issue that puts user's funds at risk.
 *
 */
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ILegionAccessControl} from "./interfaces/ILegionAccessControl.sol";

/**
 * @title Legion Access Control.
 * @author Legion.
 * @notice A contract used to keep access control for the Legion Protocol.
 */
contract LegionAccessControl is ILegionAccessControl, AccessControl {
    using Address for address;

    /// @dev Constant representing the broadcaster role.
    bytes32 public constant BROADCASTER_ROLE = keccak256("BROADCASTER_ROLE");

    /**
     * @dev Constructor to initialize the LegionAccessControl.
     *
     * @param defaultAdmin The default admin role for the `LegionAccessControl` contract.
     * @param defaultBroadcaster The default broadcaster role for the `LegionAccessControl` contract.
     */
    constructor(address defaultAdmin, address defaultBroadcaster) {
        /// Grant the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);

        /// Grant the default broadcaster role
        _grantRole(BROADCASTER_ROLE, defaultBroadcaster);
    }

    /**
     * @notice See {ILegionAccessControl-functionCall}.
     */
    function functionCall(address target, bytes memory data) external onlyRole(BROADCASTER_ROLE) {
        target.functionCall(data);
    }
}
