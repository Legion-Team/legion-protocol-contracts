// SPDX-License-Identifier: MIT
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

interface ILegionLinearVesting {
    /**
     * @notice See {VestingWalletUpgradeable-start}.
     */
    function start() external view returns (uint256);

    /**
     * @notice See {VestingWalletUpgradeable-duration}.
     */
    function duration() external view returns (uint256);

    /**
     * @notice See {VestingWalletUpgradeable-end}.
     */
    function end() external view returns (uint256);

    /**
     * @notice See {VestingWalletUpgradeable-released}.
     */
    function released() external view returns (uint256);

    /**
     * @notice See {VestingWalletUpgradeable-released}.
     */
    function released(address token) external view returns (uint256);

    /**
     * @notice See {VestingWalletUpgradeable-releasable}.
     */
    function releasable() external view returns (uint256);

    /**
     * @notice See {VestingWalletUpgradeable-releasable}.
     */
    function releasable(address token) external view returns (uint256);

    /**
     * @notice See {VestingWalletUpgradeable-release}.
     */
    function release() external;

    /**
     * @notice See {VestingWalletUpgradeable-release}.
     */
    function release(address token) external;

    /**
     * @notice See {VestingWalletUpgradeable-vestedAmount}.
     */
    function vestedAmount(uint64 timestamp) external view returns (uint256);

    /**
     * @notice See {VestingWalletUpgradeable-vestedAmount}.
     */
    function vestedAmount(address token, uint64 timestamp) external view returns (uint256);
}
