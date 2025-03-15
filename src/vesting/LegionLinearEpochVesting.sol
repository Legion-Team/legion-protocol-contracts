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

import { Errors } from "../utils/Errors.sol";

/**
 * @title Legion Linear Epoch Vesting
 * @author Legion
 * @notice A contract for releasing vested tokens to users on an epoch-based schedule
 * @dev Extends OpenZeppelin's VestingWalletUpgradeable with linear epoch vesting and cliff
 */
contract LegionLinearEpochVesting is VestingWalletUpgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Unix timestamp (seconds) when the cliff period ends
    /// @dev Prevents token release until this timestamp is reached
    uint256 public cliffEndTimestamp;

    /// @notice Duration of each epoch in seconds
    /// @dev Publicly accessible; defines the vesting interval
    uint256 public epochDurationSeconds;

    /// @notice Total number of epochs in the vesting schedule
    /// @dev Publicly accessible; determines the vesting granularity
    uint256 public numberOfEpochs;

    /// @notice The last epoch for which tokens were claimed
    /// @dev Publicly accessible; tracks vesting progress
    uint256 public lastClaimedEpoch;

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts token release until the cliff period has ended
     * @dev Reverts with CliffNotEnded if block.timestamp is before cliffEndTimestamp
     */
    modifier onlyCliffEnded() {
        if (block.timestamp < cliffEndTimestamp) revert Errors.CliffNotEnded(block.timestamp);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for LegionLinearEpochVesting
     * @dev Disables initializers to prevent uninitialized deployment
     */
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the vesting contract with specified parameters
     * @dev Sets up the vesting schedule, cliff, and epoch details; callable only once
     * @param _beneficiary Address to receive the vested tokens
     * @param _startTimestamp Unix timestamp (seconds) when vesting starts
     * @param _durationSeconds Total duration of the vesting period in seconds
     * @param _cliffDurationSeconds Duration of the cliff period in seconds
     * @param _epochDurationSeconds Duration of each epoch in seconds
     * @param _numberOfEpochs Number of epochs in the vesting schedule
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

    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Releases vested tokens of a specific type to the beneficiary
     * @dev Overrides VestingWalletUpgradeable; requires cliff to have ended
     * @param token Address of the token to release
     */
    function release(address token) public override onlyCliffEnded {
        super.release(token);

        // Update the last claimed epoch
        _updateLastClaimedEpoch();
    }

    /**
     * @notice Returns the current epoch based on the current block timestamp
     * @dev Calculates the epoch number starting from 0 before vesting begins
     * @return uint256 Current epoch number (0 if before start, 1+ otherwise)
     */
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < start()) return 0;
        else return (block.timestamp - start()) / epochDurationSeconds + 1;
    }

    /**
     * @notice Returns the epoch at a specific timestamp
     * @dev Calculates the epoch number for a given timestamp
     * @param timestamp Unix timestamp (seconds) to evaluate
     * @return uint256 Epoch number at the given timestamp (0 if before start)
     */
    function getCurrentEpochAtTimestamp(uint256 timestamp) public view returns (uint256) {
        if (timestamp < start()) return 0;
        else return (timestamp - start()) / epochDurationSeconds + 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the last claimed epoch after a release
     * @dev Internal function to track vesting progress; adjusts lastClaimedEpoch
     */
    function _updateLastClaimedEpoch() internal {
        // Get the current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // If all the epochs have elapsed, set the last claimed epoch to the total number of epochs
        if (currentEpoch >= numberOfEpochs + 1) {
            lastClaimedEpoch = numberOfEpochs;
            return;
        }

        // If current epoch is greater than the last claimed epoch, set the last claimed epoch to the current epoch - 1
        lastClaimedEpoch = currentEpoch - 1;
    }

    /**
     * @notice Calculates the vested amount based on an epoch-based schedule
     * @dev Overrides VestingWalletUpgradeable to implement linear epoch vesting
     * @param totalAllocation Total amount of tokens allocated for vesting
     * @param timestamp Unix timestamp (seconds) to calculate vesting up to the given time
     * @return amountVested Amount of tokens vested by the given timestamp
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

        // If all the epochs have elapsed, return the total allocation
        if (currentEpoch >= numberOfEpochs + 1) {
            amountVested = totalAllocation;
        }

        // Else, calculate the amount vested based on the current epoch
        if (currentEpoch > lastClaimedEpoch) {
            amountVested = ((currentEpoch - 1 - lastClaimedEpoch) * totalAllocation) / numberOfEpochs;
        }
    }
}
