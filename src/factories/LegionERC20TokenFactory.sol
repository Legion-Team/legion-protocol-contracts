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

import { ILegionERC20TokenFactory } from "../interfaces/factories/ILegionERC20TokenFactory.sol";

import { ERC20Token } from "../token/ERC20Token.sol";

/**
 * @title Legion ERC20 Token Factory
 * @author Legion
 * @notice Deploys instances of ERC20 tokens.
 */
contract LegionERC20TokenFactory is ILegionERC20TokenFactory {
    /// @inheritdoc ILegionERC20TokenFactory
    function createERC20Token(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply,
        uint256 maxSupply,
        uint8 tokenDecimals,
        address newOwner
    )
        external
        returns (address tokenInstance)
    {
        // Deploy a new ERC20 token instance
        tokenInstance = address(new ERC20Token(name, symbol, initialSupply, maxSupply, tokenDecimals, newOwner));

        // Emit NewERC20TokenCreated
        emit NewERC20TokenCreated(tokenInstance, name, symbol, initialSupply, maxSupply, tokenDecimals, newOwner);
    }
}
