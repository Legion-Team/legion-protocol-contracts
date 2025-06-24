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
 * @title ILegionPositionManager
 * @author Legion
 * @notice Interface for managing investor positions during sales in the Legion Protocol
 */
interface ILegionPositionManager {
    /// @notice Struct to hold the configuration parameters for the Legion Position Manager
    struct LegionPositionManagerConfig {
        /// @notice The name of the sale
        /// @dev This is the name of the sale for which positions are being managed
        string name;
        /// @notice The symbol of the sale
        /// @dev This is the symbol associated with the sale for which positions are being managed
        string symbol;
        /// @notice The base URI for the positions
        /// @dev This is the base URI used to construct the metadata URI for each position
        string baseURI;
        /// @notice The id of the last position created
        /// @dev This is used to track the last position ID created in the system
        uint256 lastPositionId;
    }

    /**
     * @notice Transfers an investor position from one address to another
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     */
    function transferInvestorPosition(address from, address to, uint256 positionId) external;

    /**
     * @notice Transfers an investor position with authorization
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     * @param signature The signature authorizing the transfer
     */
    function transferInvestorPositionWithAuthorization(
        address from,
        address to,
        uint256 positionId,
        bytes calldata signature
    )
        external;
}
