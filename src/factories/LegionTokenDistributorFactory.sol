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
 * @notice Deploys proxy instances of Legion token distributor contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each token distributor.
 */
contract LegionTokenDistributorFactory is ILegionTokenDistributorFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionTokenDistributor implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_tokenDistributorTemplate = address(new LegionTokenDistributor());

    /// @notice Constructor for the LegionTokenDistributorFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionTokenDistributorFactory
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
