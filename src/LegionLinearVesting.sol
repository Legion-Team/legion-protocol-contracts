// SPDX-License-Identifier: Apache-2.0
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

import { VestingWalletUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";

import { Errors } from "./utils/Errors.sol";

/**
 * @title Legion Linear Vesting.
 * @author Legion.
 * @notice A contract used to release vested tokens to users.
 * @dev The contract fully utilizes OpenZeppelin's VestingWallet.sol implementation.
 */
contract LegionLinearVesting is VestingWalletUpgradeable {
    /// @dev The unix timestamp (seconds) of the block when the cliff ends.
    uint256 private cliffEndTimestamp;

    /**
     * @notice Throws if an user tries to release tokens before the cliff period has ended
     */
    modifier onlyCliffEnded() {
        if (block.timestamp < cliffEndTimestamp) revert Errors.CliffNotEnded(block.timestamp);
        _;
    }

    /**
     * @dev LegionLinearVesting constructor.
     */
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with correct parameters.
     *
     * @param beneficiary The beneficiary to receive tokens.
     * @param startTimestamp The start timestamp of the vesting schedule.
     * @param durationSeconds The vesting duration in seconds.
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
     * @notice See {VestingWalletUpgradeable-release}.
     */
    function release() public override onlyCliffEnded {
        super.release();
    }

    /**
     * @notice See {VestingWalletUpgradeable-release}.
     */
    function release(address token) public override onlyCliffEnded {
        super.release(token);
    }

    /**
     * @notice Returns the cliff end timestamp.
     */
    function cliffEnd() public view returns (uint256) {
        return cliffEndTimestamp;
    }
}
