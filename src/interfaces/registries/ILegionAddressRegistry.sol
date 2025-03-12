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

/**
 * @title Legion Address Registry Interface
 * @notice An interface for managing Legion Protocol addresses
 */
interface ILegionAddressRegistry {
    /**
     * @notice Emitted when a Legion address is set or updated
     *
     * @param id The unique identifier of the address
     * @param previousAddress The previous address before the update
     * @param updatedAddress The updated address
     */
    event LegionAddressSet(bytes32 id, address previousAddress, address updatedAddress);

    /**
     * @notice Sets a Legion address
     *
     * @param id The unique identifier of the address
     * @param updatedAddress The new address to set
     */
    function setLegionAddress(bytes32 id, address updatedAddress) external;

    /**
     * @notice Gets a Legion address
     *
     * @param id The unique identifier of the address
     * @return The registered Legion address
     */
    function getLegionAddress(bytes32 id) external view returns (address);
}
