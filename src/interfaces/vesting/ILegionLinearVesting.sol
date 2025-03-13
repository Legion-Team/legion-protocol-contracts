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

/**
 * @title ILegionLinearVesting
 * @author Legion
 * @notice Interface for a linear vesting contract in the Legion Protocol
 * @dev Extends vesting functionality with a cliff period based on OpenZeppelin's VestingWalletUpgradeable
 */
interface ILegionLinearVesting {
    /**
     * @notice Returns the timestamp when vesting begins
     * @dev See {VestingWalletUpgradeable-start} for inherited behavior
     * @return uint256 Unix timestamp (seconds) of the vesting start
     */
    function start() external view returns (uint256);

    /**
     * @notice Returns the total duration of the vesting period
     * @dev See {VestingWalletUpgradeable-duration} for inherited behavior
     * @return uint256 Duration of vesting in seconds
     */
    function duration() external view returns (uint256);

    /**
     * @notice Returns the timestamp when vesting ends
     * @dev See {VestingWalletUpgradeable-end} for inherited behavior
     * @return uint256 Unix timestamp (seconds) of the vesting end
     */
    function end() external view returns (uint256);

    /**
     * @notice Returns the total amount of ETH released so far
     * @dev See {VestingWalletUpgradeable-released} for inherited behavior
     * @return uint256 Amount of ETH released
     */
    function released() external view returns (uint256);

    /**
     * @notice Returns the total amount of a specific token released so far
     * @dev See {VestingWalletUpgradeable-released} for inherited behavior
     * @param token Address of the token to query
     * @return uint256 Amount of the specified token released
     */
    function released(address token) external view returns (uint256);

    /**
     * @notice Returns the amount of ETH currently releasable
     * @dev See {VestingWalletUpgradeable-releasable} for inherited behavior
     * @return uint256 Amount of ETH that can be released now
     */
    function releasable() external view returns (uint256);

    /**
     * @notice Returns the amount of a specific token currently releasable
     * @dev See {VestingWalletUpgradeable-releasable} for inherited behavior
     * @param token Address of the token to query
     * @return uint256 Amount of the specified token that can be released now
     */
    function releasable(address token) external view returns (uint256);

    /**
     * @notice Releases vested ETH to the beneficiary
     * @dev See {VestingWalletUpgradeable-release} for inherited behavior; triggers transfer
     */
    function release() external;

    /**
     * @notice Releases vested tokens of a specific type to the beneficiary
     * @dev See {VestingWalletUpgradeable-release} for inherited behavior; triggers transfer
     * @param token Address of the token to release
     */
    function release(address token) external;

    /**
     * @notice Calculates the amount of ETH vested up to a given timestamp
     * @dev See {VestingWalletUpgradeable-vestedAmount} for inherited behavior
     * @param timestamp Unix timestamp (seconds) to calculate vesting up to the given time
     * @return uint256 Amount of ETH vested by the given timestamp
     */
    function vestedAmount(uint64 timestamp) external view returns (uint256);

    /**
     * @notice Calculates the amount of a specific token vested up to a given timestamp
     * @dev See {VestingWalletUpgradeable-vestedAmount} for inherited behavior
     * @param token Address of the token to query
     * @param timestamp Unix timestamp (seconds) to calculate vesting up to the given time
     * @return uint256 Amount of the specified token vested by the given timestamp
     */
    function vestedAmount(address token, uint64 timestamp) external view returns (uint256);

    /**
     * @notice Returns the timestamp when the cliff period ends
     * @dev Specific to this interface; indicates when tokens become releasable
     * @return uint256 Unix timestamp (seconds) of the cliff end
     */
    function cliffEndTimestamp() external view returns (uint256);
}
