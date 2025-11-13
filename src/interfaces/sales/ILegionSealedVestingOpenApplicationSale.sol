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

import { ECIES, Point } from "../../lib/ECIES.sol";
import { ILegionAbstractSale } from "./ILegionAbstractSale.sol";

/**
 * @title ILegionSealedVestingOpenApplicationSale
 * @author Legion
 * @notice Interface for the LegionSealedVestingOpenApplicationSale contract.
 */
interface ILegionSealedVestingOpenApplicationSale is ILegionAbstractSale {
    /// @dev Struct defining initialization parameters for the pre-liquid sealed vesting sale
    struct PreLiquidSaleInitializationParams {
        // Public key used to encrypt sealed vesting options
        Point publicKey;
    }

    /// @dev Struct defining the configuration for the pre-liquid sealed vesting sale
    struct PreLiquidSaleConfiguration {
        // Duration of the refund period in seconds
        uint64 refundPeriodSeconds;
        // Flag indicating whether the sale has ended
        bool hasEnded;
        // Flag indicating if sale cancellation is locked
        bool cancelLocked;
        // Public key used to encrypt sealed vesting options
        Point publicKey;
        // Private key used to decrypt sealed vesting options
        uint256 privateKey;
        // Fixed salt value for vesting option encryption
        uint256 fixedSalt;
    }

    /// @dev Struct representing an encrypted vesting option's components
    struct EncryptedVestingOption {
        // Encrypted vesting duration in seconds from the investor
        uint256 encryptedVestingDurationSeconds;
        // Public key used to encrypt the vesting option
        Point publicKey;
    }

    /// @notice Emitted when capital is successfully invested in the pre-liquid sale.
    /// @param amount The amount of capital invested (in bid tokens).
    /// @param encryptedVestingOption The encrypted vesting option from the investor.
    /// @param investor The address of the investor.
    /// @param positionId The unique identifier for the investment position.
    event CapitalInvested(uint256 amount, uint256 encryptedVestingOption, address investor, uint256 positionId);

    /// @notice Emitted when the total capital raised is published by the Legion admin.
    /// @param capitalRaised The total capital raised by the project.
    event CapitalRaisedPublished(uint256 capitalRaised);

    /// @notice Emitted when the sealed bid reveal process is initialized.
    event RevealInitialized();

    /// @notice Emitted when sealed bids are revealed by the Legion admin.
    event Revealed(uint256 sealedVestingOptionPrivateKey, uint256 fixedSalt);

    /// @notice Emitted when the sale is ended by Legion or project.
    event SaleEnded();

    /// @notice Initializes the pre-liquid sale contract with parameters.
    /// @param saleInitParams The Legion sale initialization parameters.
    /// @param preLiquidSaleInitParams The pre-liquid sale initialization parameters.
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external;

    /// @notice Allows an investor to invest capital in the pre-liquid sale.
    /// @param amount The amount of capital to invest.
    /// @param deadline The deadline for the investment.
    /// @param sealedVestingOption The encrypted vesting option from the investor.
    /// @param signature The Legion signature for investor verification.
    function invest(
        uint256 amount,
        uint256 deadline,
        bytes calldata sealedVestingOption,
        bytes calldata signature
    )
        external;

    /// @notice Ends the sale and sets the refund period.
    function end() external;

    /// @notice Publishes the total capital raised.
    /// @param capitalRaised The total capital raised by the project.
    function publishRaisedCapital(uint256 capitalRaised) external;

    /// @notice Locks sale cancellation to initialize publishing of results.
    function initializeReveal() external;

    /// @notice Publishes sale results including token allocation details.
    /// @param sealedVestingOptionPrivateKey The private key to decrypt sealed vesting options.
    /// @param fixedSalt The fixed salt used for sealing vesting options.
    function reveal(uint256 sealedVestingOptionPrivateKey, uint256 fixedSalt) external;

    /// @notice Returns the current pre-liquid sale configuration.
    /// @return The complete pre-liquid sale configuration struct.
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);

    /// @notice Decrypts a sealed vesting option using the published private key.
    /// @param encryptedVestingOption The encrypted vesting option from the investor.
    /// @param investor The address of the investor who made the investment.
    /// @return The decrypted vesting option.
    function decryptSealedVestingOption(
        uint256 encryptedVestingOption,
        address investor
    )
        external
        view
        returns (uint256);
}
