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
 * @title Legion Linear Vesting
 * @author Legion
 * @notice A contract used to release vested tokens to users
 * @dev The contract fully utilizes OpenZeppelin's VestingWallet.sol implementation
 */
contract LegionLinearVesting is VestingWalletUpgradeable {
    /// @dev The Unix timestamp (seconds) of the block when the cliff ends
    uint256 private cliffEndTimestamp;

    /**
     * @notice Throws if a user tries to release tokens before the cliff period has ended
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
     * @notice Initializes the contract with the correct parameters
     *
     * @param beneficiary The beneficiary to receive tokens
     * @param startTimestamp The Unix timestamp when the vesting schedule starts
     * @param durationSeconds The duration of the vesting period in seconds
     * @param cliffDurationSeconds The duration of the cliff period in seconds
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
     * @notice Release the native token (ether) that have already vested.
     *
     * Emits a {EtherReleased} event.
     */
    function release() public override onlyCliffEnded {
        super.release();
    }

    /**
     * @notice Release the tokens that have already vested.
     *
     * @param token The vested token to release
     *
     * Emits a {ERC20Released} event.
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
