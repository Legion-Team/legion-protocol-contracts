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
 * @title ILegionERC20TokenFactory
 * @author Legion
 * @notice Interface for the LegionERC20TokenFactory contract.
 */
interface ILegionERC20TokenFactory {
    /// @notice Emitted when a new ERC20 token is created
    /// @param tokenInstance Address of the newly created ERC20 token
    /// @param name Name of the ERC20 token
    /// @param symbol Symbol of the ERC20 token
    /// @param initialSupply Initial supply of the ERC20 token
    /// @param maxSupply Maximum supply of the ERC20 token
    /// @param tokenDecimals Decimals of the ERC20 token
    /// @param newOwner Address of the new owner of the ERC20 token
    event NewERC20TokenCreated(
        address tokenInstance,
        string name,
        string symbol,
        uint256 initialSupply,
        uint256 maxSupply,
        uint8 tokenDecimals,
        address newOwner
    );

    /// @notice Creates a new ERC20 token
    /// @param name Name of the ERC20 token
    /// @param symbol Symbol of the ERC20 token
    /// @param initialSupply Initial supply of the ERC20 token
    /// @param maxSupply Maximum supply of the ERC20 token
    /// @param tokenDecimals Decimals of the ERC20 token
    /// @param newOwner Address of the new owner of the ERC20 token
    function createERC20Token(
        string calldata name,
        string calldata symbol,
        uint256 initialSupply,
        uint256 maxSupply,
        uint8 tokenDecimals,
        address newOwner
    )
        external
        returns (address tokenInstance);
}
