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

import { ILegionTokenDistributorFactory } from "../interfaces/factories/ILegionTokenDistributorFactory.sol";
import { ILegionTokenDistributor } from "../interfaces/distribution/ILegionTokenDistributor.sol";

import { LegionTokenDistributor } from "../distribution/LegionTokenDistributor.sol";

/**
 * @title Legion Token Distributor Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion token distributor contracts
 * @dev Uses the clone pattern to create new instances of LegionTokenDistributor contracts
 */
contract LegionTokenDistributorFactory is ILegionTokenDistributorFactory, Ownable {
    using LibClone for address;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the LegionTokenDistributor implementation contract used as template
    /// @dev Immutable reference to the base implementation deployed during construction
    address public immutable i_tokenDistributorTemplate = address(new LegionTokenDistributor());

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the LegionTokenDistributorFactory with an owner
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
     * @notice Deploys a new LegionTokenDistributor contract instance
     * @dev Clones the template contract and initializes it with provided parameters; restricted to owner
     * @param distributorInitParams Struct containing Legion Token Distributor initialization parameters
     * @return distributorInstance Address of the newly deployed LegionTokenDistributor instance
     */
    function createTokenDistributor(
        ILegionTokenDistributor.TokenDistributorInitializationParams calldata distributorInitParams
    )
        external
        onlyOwner
        returns (address payable distributorInstance)
    {
        // Deploy a LegionTokenDistributor instance
        distributorInstance = payable(i_tokenDistributorTemplate.clone());

        // Emit NewTokenDistributorCreated
        emit NewTokenDistributorCreated(distributorInstance, distributorInitParams);

        // Initialize the LegionTokenDistributor with the provided configuration
        LegionTokenDistributor(distributorInstance).initialize(distributorInitParams);
    }
}
