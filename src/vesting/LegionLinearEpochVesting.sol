// SPDX-License-Identifier: Apache-2.0
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

import { VestingWalletUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";

import { Errors } from "../utils/Errors.sol";

/**
 * @title Legion Linear Epoch Vesting
 * @author Legion
 * @notice Releases vested tokens to users on an epoch-based schedule with cliff protection.
 * @dev Extends OpenZeppelin's VestingWalletUpgradeable with linear epoch vesting functionality.
 */
contract LegionLinearEpochVesting is VestingWalletUpgradeable {
    /// @dev Unix timestamp (seconds) when the cliff period ends.
    uint64 private s_cliffEndTimestamp;

    /// @dev Duration of each epoch in seconds.
    uint64 private s_epochDurationSeconds;

    /// @dev Total number of epochs in the vesting schedule.
    uint64 private s_numberOfEpochs;

    /// @dev The last epoch for which tokens were claimed.
    uint64 private s_lastClaimedEpoch;

    /// @dev Address of the vesting controller.
    address private s_vestingController;

    /// @dev The address of the token to be vested.
    address private s_askToken;

    /// @notice Restricts token release until the cliff period has ended.
    /// @dev Reverts with LegionVesting__CliffNotEnded if block.timestamp is before cliffEndTimestamp.
    modifier onlyCliffEnded() {
        if (block.timestamp < s_cliffEndTimestamp) revert Errors.LegionVesting__CliffNotEnded(block.timestamp);
        _;
    }

    /// @notice Restricts function access to the vesting controller only.
    /// @dev Reverts if the caller is not the configured vesting controller address.
    modifier onlyVestingController() {
        if (msg.sender != s_vestingController) revert Errors.LegionSale__NotCalledByVestingController();
        _;
    }

    /// @notice Restricts function access to release the ask token only.
    /// @dev Reverts if the token being released is not the configured ask token.
    /// @param token The address of the token to release.
    modifier onlyAskToken(address token) {
        if (token != s_askToken) revert Errors.LegionVesting__OnlyAskTokenReleasable();
        _;
    }

    /// @notice Constructor for the LegionLinearEpochVesting contract.
    /// @dev Prevents the implementation contract from being initialized directly.
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /// @notice Initializes the vesting contract with specified parameters.
    /// @dev Sets up the vesting schedule, cliff, and epoch details; callable only once.
    /// @param _beneficiary The address to receive the vested tokens.
    /// @param _vestingController The address of the vesting controller contract for access control.
    /// @param _askToken The address of the token to be vested.
    /// @param _startTimestamp The Unix timestamp (seconds) when vesting starts.
    /// @param _durationSeconds The total duration of the vesting period in seconds.
    /// @param _cliffDurationSeconds The duration of the cliff period in seconds.
    /// @param _epochDurationSeconds The duration of each epoch in seconds.
    /// @param _numberOfEpochs The number of epochs in the vesting schedule.
    function initialize(
        address _beneficiary,
        address _vestingController,
        address _askToken,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        uint64 _cliffDurationSeconds,
        uint64 _epochDurationSeconds,
        uint64 _numberOfEpochs
    )
        external
        initializer
    {
        // Initialize the LegionLinearEpochVesting clone
        __VestingWallet_init(_beneficiary, _startTimestamp, _durationSeconds);

        // Set the cliff end timestamp based on the cliff duration
        s_cliffEndTimestamp = _startTimestamp + _cliffDurationSeconds;

        // Set the epoch duration
        s_epochDurationSeconds = _epochDurationSeconds;

        // Set the number of epochs
        s_numberOfEpochs = _numberOfEpochs;

        // Set the vesting controller address for access control
        s_vestingController = _vestingController;

        // Set the ask token address
        s_askToken = _askToken;
    }

    /// @notice Returns the timestamp when the cliff period ends
    /// @dev Indicates when the vesting cliff ends and tokens can be released.
    /// @return The Unix timestamp (seconds) of the cliff end.
    function cliffEndTimestamp() external view returns (uint64) {
        return s_cliffEndTimestamp;
    }

    /// @notice Returns the duration of each epoch in seconds.
    /// @dev Defines the vesting interval for epoch-based releases.
    /// @return The duration of each epoch in seconds.
    function epochDurationSeconds() external view returns (uint64) {
        return s_epochDurationSeconds;
    }

    /// @notice Returns the total number of epochs in the vesting schedule.
    /// @dev Determines the granularity of token releases.
    /// @return The total number of epochs in the vesting schedule.
    function numberOfEpochs() external view returns (uint64) {
        return s_numberOfEpochs;
    }

    /// @notice Returns the last epoch for which tokens were claimed.
    /// @dev Tracks the progress of vesting claims.
    /// @return The last epoch number for which tokens were claimed.
    function lastClaimedEpoch() external view returns (uint64) {
        return s_lastClaimedEpoch;
    }

    /// @notice Releases vested tokens of a specific type to the beneficiary.
    /// @dev Overrides VestingWalletUpgradeable; requires cliff to have ended.
    /// @param token The address of the token to release.
    function release(address token) public override onlyAskToken(token) onlyCliffEnded {
        super.release(token);

        // Update the last claimed epoch
        _updateLastClaimedEpoch();
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @dev Can only be called by the vesting controller.
    /// @param newOwner The address to transfer ownership to.
    function emergencyTransferOwnership(address newOwner) external onlyVestingController {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /// @notice Returns the current epoch based on the current block timestamp.
    /// @dev Calculates the epoch number starting from 0 before vesting begins.
    /// @return The current epoch number (0 if before start, 1+ otherwise).
    function getCurrentEpoch() public view returns (uint64) {
        if (block.timestamp < start()) return 0;
        else return (uint64(block.timestamp - start())) / s_epochDurationSeconds + 1;
    }

    /// @notice Returns the epoch at a specific timestamp.
    /// @dev Calculates the epoch number for a given timestamp.
    /// @param timestamp The Unix timestamp (seconds) to evaluate.
    /// @return The epoch number at the given timestamp (0 if before start).
    function getCurrentEpochAtTimestamp(uint256 timestamp) public view returns (uint64) {
        if (timestamp < start()) return 0;
        else return (uint64(timestamp - start())) / s_epochDurationSeconds + 1;
    }

    /// @dev Updates the last claimed epoch after a release.
    function _updateLastClaimedEpoch() internal {
        // Get the current epoch
        uint64 currentEpoch = getCurrentEpoch();

        // If all epochs have elapsed, set the last claimed epoch to the total number of epochs
        if (currentEpoch >= s_numberOfEpochs + 1) {
            s_lastClaimedEpoch = s_numberOfEpochs;
            return;
        }

        // If current epoch is greater than the last claimed epoch, set the last claimed epoch to the current epoch - 1
        s_lastClaimedEpoch = currentEpoch - 1;
    }

    /// @dev Calculates the vested amount based on an epoch-based schedule.
    /// @param _totalAllocation The total amount of tokens allocated for vesting.
    /// @param _timestamp The Unix timestamp (seconds) to calculate vesting up to.
    /// @return amountVested The amount of tokens vested by the given timestamp.
    function _vestingSchedule(
        uint256 _totalAllocation,
        uint64 _timestamp
    )
        internal
        view
        override
        returns (uint256 amountVested)
    {
        // Get the current epoch
        uint256 currentEpoch = getCurrentEpochAtTimestamp(_timestamp);

        // If all epochs have elapsed, return the total allocation
        if (currentEpoch >= s_numberOfEpochs + 1) {
            amountVested = _totalAllocation;
            return amountVested;
        }

        // Otherwise, calculate the amount vested based on the current epoch
        if (currentEpoch > s_lastClaimedEpoch) {
            amountVested = ((currentEpoch - 1) * _totalAllocation) / s_numberOfEpochs;
        }
    }
}
