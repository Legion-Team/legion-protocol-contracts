// SPDX-License-Identifier: Apache-2.0
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

import { VestingWalletUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

/**
 * @title Legion Linear Vesting
 * @author Legion
 * @notice A contract for releasing vested tokens to users with a linear schedule
 * @dev Extends OpenZeppelin's VestingWalletUpgradeable with cliff functionality
 */
contract LegionLinearVesting is VestingWalletUpgradeable {
    /// @notice Unix timestamp (seconds) when the cliff period ends
    /// @dev Private variable preventing token release until this timestamp
    uint256 public cliffEndTimestamp;

    /**
     * @notice Restricts token release until the cliff period has ended
     * @dev Reverts with CliffNotEnded if block.timestamp is before cliffEndTimestamp
     */
    modifier onlyCliffEnded() {
        if (block.timestamp < cliffEndTimestamp) revert Errors.CliffNotEnded(block.timestamp);
        _;
    }

    /**
     * @notice Constructor for LegionLinearVesting
     * @dev Disables initializers to prevent uninitialized deployment
     */
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /**
     * @notice Initializes the vesting contract with specified parameters
     * @dev Sets up the linear vesting schedule and cliff; callable only once
     * @param beneficiary Address to receive the vested tokens
     * @param startTimestamp Unix timestamp (seconds) when vesting starts
     * @param durationSeconds Total duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     */
    function initialize(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    )
        public
        initializer
    {
        // Initialize the LegionLinearVesting clone
        __VestingWallet_init(beneficiary, startTimestamp, durationSeconds);

        // Set the cliff end timestamp, based on the cliff duration
        cliffEndTimestamp = startTimestamp + cliffDurationSeconds;
    }

    /**
     * @notice Releases vested tokens of a specific type to the beneficiary
     * @dev Overrides VestingWalletUpgradeable; requires cliff to have ended
     * @param token Address of the token to release
     */
    function release(address token) public override onlyCliffEnded {
        super.release(token);
    }
}
