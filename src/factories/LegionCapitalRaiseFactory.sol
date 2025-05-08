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

import { LibClone } from "@solady/src/utils/LibClone.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionCapitalRaise } from "../interfaces/raise/ILegionCapitalRaise.sol";
import { ILegionCapitalRaiseFactory } from "../interfaces/factories/ILegionCapitalRaiseFactory.sol";

import { LegionCapitalRaise } from "../raise/LegionCapitalRaise.sol";

/**
 * @title Legion Capital Raise Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion pre-liquid capital raise contracts
 * @dev Utilizes the clone pattern to create new instances of LegionCapitalRaise contracts
 */
contract LegionCapitalRaiseFactory is ILegionCapitalRaiseFactory, Ownable {
    using LibClone for address;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the LegionCapitalRaise implementation contract used as template
    /// @dev Immutable reference to the base implementation deployed during construction
    address public immutable i_capitalRaiseTemplate = address(new LegionCapitalRaise());

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the LegionCapitalRaiseFactory with an owner
     * @dev Sets up ownership during contract deployment
     * @param newOwner Address to be set as the initial owner of the factory
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploys a new LegionCapitalRaise contract instance
     * @dev Clones the template contract and initializes it with provided parameters; restricted to owner
     * @param capitalRaiseInitParams Calldata struct containing pre-liquid capital raise initialization parameters
     * @return capitalRaiseInstance Address of the newly deployed and initialized LegionCapitalRaise instance
     */
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
