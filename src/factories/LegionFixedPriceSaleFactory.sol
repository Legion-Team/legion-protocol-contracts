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

import { ILegionFixedPriceSale } from "../interfaces/sales/ILegionFixedPriceSale.sol";
import { ILegionFixedPriceSaleFactory } from "../interfaces/factories/ILegionFixedPriceSaleFactory.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionFixedPriceSale } from "../sales/LegionFixedPriceSale.sol";

/**
 * @title Legion Fixed Price Sale Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion fixed price sales
 * @dev Uses the clone pattern to create new instances of LegionFixedPriceSale contracts
 */
contract LegionFixedPriceSaleFactory is ILegionFixedPriceSaleFactory, Ownable {
    using LibClone for address;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the LegionFixedPriceSale implementation contract used as template
    /// @dev Immutable reference to the base implementation deployed during construction
    address public immutable i_fixedPriceSaleTemplate = address(new LegionFixedPriceSale());

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the LegionFixedPriceSaleFactory with an owner
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
     * @notice Deploys a new LegionFixedPriceSale contract instance
     * @dev Clones the template contract and initializes it with provided parameters; restricted to owner
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @param fixedPriceSaleInitParams Struct containing fixed price sale specific initialization parameters
     * @return fixedPriceSaleInstance Address of the newly deployed and initialized LegionFixedPriceSale instance
     */
    function createFixedPriceSale(
        ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
    )
        external
        onlyOwner
        returns (address payable fixedPriceSaleInstance)
    {
        // Deploy a LegionFixedPriceSale instance
        fixedPriceSaleInstance = payable(i_fixedPriceSaleTemplate.clone());

        // Emit NewFixedPriceSaleCreated
        emit NewFixedPriceSaleCreated(fixedPriceSaleInstance, saleInitParams, fixedPriceSaleInitParams);

        // Initialize the LegionFixedPriceSale with the provided configuration
        LegionFixedPriceSale(fixedPriceSaleInstance).initialize(saleInitParams, fixedPriceSaleInitParams);
    }
}
