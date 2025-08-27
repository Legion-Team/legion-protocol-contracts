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

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Errors } from "../utils/Errors.sol";

import { ERC5192 } from "../lib/ERC5192.sol";
import { ILegionPositionManager } from "../interfaces/position/ILegionPositionManager.sol";

/**
 * @title Legion Position Manager
 * @author Legion
 * @notice Manages investor positions during sales in the Legion Protocol using soulbound NFTs.
 * @dev Abstract contract that extends ERC5192 to create non-transferable position tokens representing investor
 * participation in sales.
 */
abstract contract LegionPositionManager is ILegionPositionManager, ERC5192 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using Strings for uint256;

    /// @notice Legion Position Manager configuration.
    /// @dev Struct containing the position manager configuration.
    LegionPositionManagerConfig public s_positionManagerConfig;

    /// @notice Mapping of investor addresses to their position IDs.
    /// @dev Maps each investor to their unique position identifier.
    mapping(address s_investorAddress => uint256 s_investorPositionId) internal s_investorPositionIds;

    /// @inheritdoc ILegionPositionManager
    function transferInvestorPosition(address from, address to, uint256 positionId) external virtual;

    /// @inheritdoc ILegionPositionManager
    function transferInvestorPositionWithAuthorization(
        address from,
        address to,
        uint256 positionId,
        bytes calldata signature
    )
        external
        virtual;

    /// @inheritdoc ERC5192
    function name() public view override returns (string memory) {
        return s_positionManagerConfig.name;
    }

    /// @inheritdoc ERC5192
    function symbol() public view override returns (string memory) {
        return s_positionManagerConfig.symbol;
    }

    /// @inheritdoc ERC5192
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) {
            revert("ERC721: URI query for nonexistent token");
        }
        string memory baseURI = s_positionManagerConfig.baseURI;
        return bytes(baseURI).length > 0 ? string.concat(baseURI, id.toString()) : "";
    }

    /// @inheritdoc ERC5192
    function _afterTokenTransfer(address _from, address _to, uint256 _id) internal override {
        // Check if this is not a new mint or burn
        if (_from != address(0) && _to != address(0)) {
            // Delete the assigned position ID from the sender
            delete s_investorPositionIds[_from];

            // Assign the position ID to the new owner
            s_investorPositionIds[_to] = _id;
        }

        super._afterTokenTransfer(_from, _to, _id);
    }

    /// @dev Internal function to transfer an investor position between addresses.
    /// @param _from The address of the current owner.
    /// @param _to The address of the new owner.
    /// @param _positionId The ID of the position to transfer.
    function _transferInvestorPosition(address _from, address _to, uint256 _positionId) internal virtual {
        // Unlock the position before transferring
        _updateLockedStatus(_positionId, false);

        // Transfer the position token
        _transfer(_from, _to, _positionId);
    }

    /// @dev Internal function to create a new investor position.
    /// @param _investor The address of the investor.
    /// @return positionId The ID of the newly created position.
    function _createInvestorPosition(address _investor) internal virtual returns (uint256 positionId) {
        // Increment the last position ID
        ++s_positionManagerConfig.lastPositionId;

        // Assign the new position ID
        positionId = s_positionManagerConfig.lastPositionId;

        // Map the investor address to the new position ID
        s_investorPositionIds[_investor] = positionId;

        // Mint the position token to the investor
        _mint(_investor, positionId);
    }

    /// @dev Internal function to burn an investor position.
    /// @param _investor The address of the investor whose position will be burned.
    function _burnInvestorPosition(address _investor) internal virtual {
        uint256 positionId = s_investorPositionIds[_investor];

        // Burn the position token
        _burn(positionId);

        // Remove the mapping of the position ID to the investor address
        delete s_investorPositionIds[_investor];
    }

    /// @dev Internal function to get the position ID of an investor.
    /// @param _investor The address of the investor.
    /// @return The ID of the investor's position.
    function _getInvestorPositionId(address _investor) internal view virtual returns (uint256) {
        return s_investorPositionIds[_investor];
    }

    /// @dev Verifies that an investor's position exists.
    /// @param _positionId The ID of the investor's position.
    function _verifyPositionExists(uint256 _positionId) internal pure virtual {
        if (_positionId == 0) revert Errors.LegionSale__InvestorPositionDoesNotExist();
    }

    /// @dev Verifies that a transfer signature is valid and authorized.
    /// @param _from The address of the current owner.
    /// @param _to The address of the new owner.
    /// @param _positionId The ID of the position being transferred.
    /// @param _signer The expected signer of the authorization.
    /// @param _signature The signature authorizing the transfer.
    function _verifyTransferSignature(
        address _from,
        address _to,
        uint256 _positionId,
        address _signer,
        bytes calldata _signature
    )
        internal
        view
        virtual
    {
        bytes32 _data = keccak256(abi.encodePacked(_from, _to, _positionId, msg.sender, address(this), block.chainid))
            .toEthSignedMessageHash();
        if (_data.recover(_signature) != _signer) {
            revert Errors.LegionSale__InvalidSignature(_signature);
        }
    }
}
