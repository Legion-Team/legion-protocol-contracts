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

/**
 * @title ILegionVesting
 * @author Legion
 * @notice Interface for a vesting contract in the Legion Protocol.
 */
interface ILegionVesting {
    /// @notice Returns the timestamp when vesting begins
    /// @return uint256 Unix timestamp (seconds) of the vesting start
    function start() external view returns (uint64);

    /// @notice Returns the total duration of the vesting period
    /// @return uint256 Duration of vesting in seconds
    function duration() external view returns (uint64);

    /// @notice Returns the timestamp when vesting ends
    /// @return uint256 Unix timestamp (seconds) of the vesting end
    function end() external view returns (uint64);

    /// @notice Returns the total amount of ETH released so far
    /// @return uint256 Amount of ETH released
    function released() external view returns (uint256);

    /// @notice Returns the total amount of a specific token released so far
    /// @param token Address of the token to query
    /// @return uint256 Amount of the specified token released
    function released(address token) external view returns (uint256);

    /// @notice Returns the amount of ETH currently releasable
    /// @return uint256 Amount of ETH that can be released now
    function releasable() external view returns (uint256);

    /// @notice Returns the amount of a specific token currently releasable
    /// @param token Address of the token to query
    /// @return uint256 Amount of the specified token that can be released now
    function releasable(address token) external view returns (uint256);

    /// @notice Releases vested ETH to the beneficiary
    function release() external;

    /// @notice Releases vested tokens of a specific type to the beneficiary
    /// @param token Address of the token to release
    function release(address token) external;

    /// @notice Calculates the amount of ETH vested up to a given timestamp
    /// @param timestamp Unix timestamp (seconds) to calculate vesting up to the given time
    /// @return uint256 Amount of ETH vested by the given timestamp
    function vestedAmount(uint64 timestamp) external view returns (uint256);

    /// @notice Calculates the amount of a specific token vested up to a given timestamp
    /// @param token Address of the token to query
    /// @param timestamp Unix timestamp (seconds) to calculate vesting up to the given time
    /// @return uint256 Amount of the specified token vested by the given timestamp
    function vestedAmount(address token, uint64 timestamp) external view returns (uint256);

    /// @notice Returns the timestamp when the cliff period ends
    /// @return uint256 Unix timestamp (seconds) of the cliff end
    function cliffEndTimestamp() external view returns (uint64);
}
