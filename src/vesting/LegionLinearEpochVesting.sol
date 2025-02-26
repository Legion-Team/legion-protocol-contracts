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

import { Errors } from "../utils/Errors.sol";

/**
 * @title Legion Linear Epoch Vesting
 * @author Legion
 * @notice A contract used to release vested tokens to users
 * @dev The contract fully utilizes OpenZeppelin's VestingWallet.sol implementation
 */
contract LegionLinearEpochVesting is VestingWalletUpgradeable {
    /// @dev The Unix timestamp (seconds) of the block when the cliff ends
    uint256 private cliffEndTimestamp;

    /// @dev The duration of each epoch in seconds
    uint256 public epochDurationSeconds;

    /// @dev The number of epochs
    uint256 public numberOfEpochs;

    /// @dev The last claimed epoch
    uint256 public lastClaimedEpoch;

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
     * @param _beneficiary The beneficiary to receive tokens
     * @param _startTimestamp The Unix timestamp when the vesting schedule starts
     * @param _durationSeconds The duration of the vesting period in seconds
     * @param _cliffDurationSeconds The duration of the cliff period in seconds
     * @param _epochDurationSeconds The duration of each epoch in seconds
     * @param _numberOfEpochs The number of epochs
     */
    function initialize(
        address _beneficiary,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        uint64 _cliffDurationSeconds,
        uint256 _epochDurationSeconds,
        uint256 _numberOfEpochs
    )
        public
        initializer
    {
        // Initialize the LegionLinearVesting clone
        __VestingWallet_init(_beneficiary, _startTimestamp, _durationSeconds);

        // Set the cliff end timestamp, based on the cliff duration
        cliffEndTimestamp = _startTimestamp + _cliffDurationSeconds;

        // Set the epoch duration
        epochDurationSeconds = _epochDurationSeconds;

        // Set the number of epochs
        numberOfEpochs = _numberOfEpochs;
    }

    /**
     * @dev Overriden implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    )
        internal
        view
        override
        returns (uint256 amountVested)
    {
        // Get the current epoch
        uint256 currentEpoch = getCurrentEpochAtTimestamp(timestamp);

        // If all the epochs have elpased, return the total allocation
        if (currentEpoch >= numberOfEpochs + 1) {
            amountVested = totalAllocation;
        }

        // Else, calculate the amount vested based on the current epoch
        if (currentEpoch > lastClaimedEpoch) {
            amountVested = ((currentEpoch - 1 - lastClaimedEpoch) * totalAllocation) / numberOfEpochs;
        }
    }

    /**
     * @dev Updates the last claimed epoch
     */
    function _updateLastClaimedEpoch() internal {
        // Get the current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // If all the epochs have elpased, set the last claimed epoch to the total number of epochs
        if (currentEpoch >= numberOfEpochs + 1) {
            lastClaimedEpoch = numberOfEpochs;
            return;
        }

        // If current epoch is greater than the last claimed epoch, set the last claimed epoch to the current epoch - 1
        lastClaimedEpoch = currentEpoch - 1;
    }

    /**
     * @notice Release the native token (ether) that have already vested.
     *
     * Emits a {EtherReleased} event.
     */
    function release() public override onlyCliffEnded {
        super.release();

        // Update the last claimed epoch
        _updateLastClaimedEpoch();
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

        // Update the last claimed epoch
        _updateLastClaimedEpoch();
    }

    /**
     * @notice Returns the current epoch.
     */
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < start()) return 0;
        else return (block.timestamp - start()) / epochDurationSeconds + 1;
    }

    /**
     * @notice Returns the current epoch for a specific timestamp.
     */
    function getCurrentEpochAtTimestamp(uint256 timestamp) public view returns (uint256) {
        if (timestamp < start()) return 0;
        else return (timestamp - start()) / epochDurationSeconds + 1;
    }

    /**
     * @notice Returns the cliff end timestamp.
     */
    function cliffEnd() public view returns (uint256) {
        return cliffEndTimestamp;
    }
}
