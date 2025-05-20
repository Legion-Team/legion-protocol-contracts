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

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ERC5192 } from "../lib/ERC5192.sol";
import { ILegionPositionManager } from "../interfaces/position/ILegionPositionManager.sol";

/**
 * @title Legion Position Manager
 * @author Legion
 * @notice A contract for managing investor positions during sales in the Legion Protocol
 * @dev Abstract contract implementing ILegionPositionManager; handles investor positions
 */
abstract contract LegionPositionManager is ILegionPositionManager, ERC5192 {
    using Strings for uint256;

    /**
     * @dev Configuration for the Legion Position Manager
     */
    LegionPositionManagerConfig public s_positionManagerconfig;

    /**
     * @notice Mapping of investor addresses to their position IDs
     * @dev Investor position IDs
     */
    mapping(address s_investorAddress => uint256 s_investorPositionId) internal s_investorPositionIds;

    /**
     * @inheritdoc ERC5192
     */
    function name() public view override returns (string memory) {
        return s_positionManagerconfig.name;
    }

    /**
     * @inheritdoc ERC5192
     */
    function symbol() public view override returns (string memory) {
        return s_positionManagerconfig.symbol;
    }

    /**
     * @inheritdoc ERC5192
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory baseURI = s_positionManagerconfig.baseURI;
        return bytes(baseURI).length > 0 ? string.concat(baseURI, id.toString()) : "";
    }

    /**
     * @notice Transfers an investor position from one address to another
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     * @dev This function needs to be implemented in the derived contract
     */
    function transferInvestorPosition(address from, address to, uint256 positionId) external virtual;

    /**
     * @inheritdoc ERC5192
     */
    function _afterTokenTransfer(address from, address to, uint256 id) internal override {
        // Check if this is not a new mint or burn
        if (from != address(0) && to != address(0)) {
            // Get the position ID of the sender
            uint256 positionId = s_investorPositionIds[from];

            // If the position ID is not assigned to the sender, revert
            if (positionId != id) {
                revert NotOwnerNorApproved();
            }

            // Delete the assigned position ID from the sender
            delete s_investorPositionIds[from];

            // Assign the position ID to the new owner
            s_investorPositionIds[to] = id;
        }

        super._afterTokenTransfer(from, to, id);
    }

    /**
     * @notice Internal function to transfer an investor position
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     */
    function _transferInvestorPosition(address from, address to, uint256 positionId) internal {
        // Unlock the position before transferring
        _updateLockedStatus(positionId, false);

        // Transfer the position token
        _transfer(from, to, positionId);
    }

    /**
     * @notice Internal function to create a new investor position
     * @param investor The address of the investor
     * @return postionId The ID of the newly created position
     */
    function _createInvestorPosition(address investor) internal returns (uint256 postionId) {
        // Increment the last position ID
        ++s_positionManagerconfig.lastPositionId;

        // Assign the new position ID to the investor
        postionId = s_positionManagerconfig.lastPositionId;

        // Map the investor address to the position ID
        s_investorPositionIds[investor] = postionId;

        // Mint the new position to the investor
        _mint(investor, postionId);
    }

    /**
     * @notice Internal function to burn an investor position
     * @param investor The address of the investor
     */
    function _burnInvestorPosition(address investor) internal {
        uint256 positionId = s_investorPositionIds[investor];

        // Burn the position token
        _burn(positionId);

        // Remove the mapping of the position ID to the investor address
        delete s_investorPositionIds[investor];
    }

    /**
     * @notice Internal function to get the position ID of an investor
     * @param investor The address of the investor
     * @return positionId The ID of the investor's position
     */
    function _getInvestorPositionId(address investor) internal view returns (uint256) {
        return s_investorPositionIds[investor];
    }
}
