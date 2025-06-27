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

import { LibClone } from "@solady/src/utils/LibClone.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionCapitalRaise } from "../interfaces/raise/ILegionCapitalRaise.sol";
import { ILegionCapitalRaiseFactory } from "../interfaces/factories/ILegionCapitalRaiseFactory.sol";

import { LegionCapitalRaise } from "../raise/LegionCapitalRaise.sol";

/**
 * @title Legion Capital Raise Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion capital raise contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each capital raise campaign.
 */
contract LegionCapitalRaiseFactory is ILegionCapitalRaiseFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionCapitalRaise implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_capitalRaiseTemplate = address(new LegionCapitalRaise());

    /// @notice Constructor for the LegionCapitalRaiseFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionCapitalRaiseFactory
    function createCapitalRaise(LegionCapitalRaise.CapitalRaiseInitializationParams calldata capitalRaiseInitParams)
        external
        onlyOwner
        returns (address payable capitalRaiseInstance)
    {
        // Deploy a LegionCapitalRaise instance
        capitalRaiseInstance = payable(i_capitalRaiseTemplate.clone());

        // Emit NewCapitalRaiseCreated
        emit NewCapitalRaiseCreated(capitalRaiseInstance, capitalRaiseInitParams);

        // Initialize the LegionCapitalRaise with the provided configuration
        LegionCapitalRaise(capitalRaiseInstance).initialize(capitalRaiseInitParams);
    }
}
