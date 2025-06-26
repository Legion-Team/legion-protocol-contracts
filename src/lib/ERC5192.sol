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

import { ERC721 } from "@solady/src/tokens/ERC721.sol";

import { IERC5192 } from "../interfaces/lib/IERC5192.sol";

/**
 * @title ERC-5192: Minimal Soulbound NFTs Implementation
 * @author Legion
 * @notice Implements Soulbound Tokens (SBTs) according to the ERC-5192 standard.
 * @dev Abstract contract that extends ERC721 with locking functionality to create non-transferable tokens.
 */
abstract contract ERC5192 is IERC5192, ERC721 {
    /// @dev Thrown when attempting to transfer a locked token.
    /// @param tokenId The identifier for the token that cannot be transferred.
    error ERC5192__LockedToken(uint256 tokenId);

    /// @dev Thrown when attempting to transfer a token to itself.
    /// @param tokenId The identifier for the token that cannot be transferred to itself.
    error ERC5192__TransferToSelf(uint256 tokenId);

    /// @dev Mapping from token ID to locked status.
    mapping(uint256 => bool) internal _locked;

    /// @notice Returns the locking status of a Soulbound Token.
    /// @dev SBTs assigned to the zero address are considered invalid, and queries about them will revert.
    /// @param tokenId The identifier for an SBT.
    /// @return True if the token is locked, false otherwise.
    function locked(uint256 tokenId) external view virtual override returns (bool) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        return _locked[tokenId];
    }

    /// @dev Updates the locked status of a token and emits the appropriate event.
    /// @param tokenId The identifier for a token.
    /// @param status The new locked status of the token.
    function _updateLockedStatus(uint256 tokenId, bool status) internal virtual {
        _locked[tokenId] = status;
        if (status) {
            emit Locked(tokenId);
        } else {
            emit Unlocked(tokenId);
        }
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC721: 0x80ac58cd, ERC721Metadata: 0x5b5e139f, EIP5192: 0xb45a3c0e.
            result := or(or(or(eq(s, 0x01ffc9a7), eq(s, 0x80ac58cd)), eq(s, 0x5b5e139f)), eq(s, 0xb45a3c0e))
        }
    }

    /// @inheritdoc ERC721
    function name() public view virtual override returns (string memory) { }

    /// @inheritdoc ERC721
    function symbol() public view virtual override returns (string memory) { }

    /// @inheritdoc ERC721
    function tokenURI(uint256 id) public view virtual override returns (string memory) { }

    /// @inheritdoc ERC721
    function _mint(address to, uint256 id) internal virtual override {
        super._mint(to, id);

        // Set the locked status to true
        _locked[id] = true;

        // Emit the Locked event
        emit Locked(id);
    }

    /// @inheritdoc ERC721
    function _mintAndSetExtraDataUnchecked(address to, uint256 id, uint96 value) internal virtual override {
        super._mintAndSetExtraDataUnchecked(to, id, value);

        // Set the locked status to true
        _locked[id] = true;

        // Emit the Locked event
        emit Locked(id);
    }

    /// @inheritdoc ERC721
    function _burn(uint256 id) internal virtual override {
        // Set the locked status to false
        _locked[id] = false;

        super._burn(id);

        // Emit the Unlocked event
        emit Unlocked(id);
    }

    /// @inheritdoc ERC721
    function _beforeTokenTransfer(address from, address to, uint256 id) internal virtual override {
        // If the token is locked, revert the transaction
        if (_locked[id]) {
            revert ERC5192__LockedToken(id);
        }

        // If the transfer is to self, revert the transaction
        if (from == to) {
            revert ERC5192__TransferToSelf(id);
        }

        super._beforeTokenTransfer(from, to, id);
    }

    /// @inheritdoc ERC721
    function _afterTokenTransfer(address from, address to, uint256 id) internal virtual override {
        // Update the locked status of the token to true
        _updateLockedStatus(id, true);

        super._afterTokenTransfer(from, to, id);
    }
}
