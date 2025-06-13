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

/**
 * @title ILegionPositionManager
 * @author Legion
 * @notice Interface for managing investor positions during sales in the Legion Protocol
 * @dev Defines position types and structs for position configuration and status tracking
 */
interface ILegionPositionManager {
    struct LegionPositionManagerConfig {
        string name;
        string symbol;
        string baseURI;
        uint256 lastPositionId;
    }

    /**
     * @notice Transfers an investor position from one address to another
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     * @dev This function needs to be implemented in the derived contract
     */
    function transferInvestorPosition(address from, address to, uint256 positionId) external;
}
