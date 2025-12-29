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
 * @title ILegionSealedBidSale
 * @author Legion
 * @notice Interface for the LegionSealedBidSale contract.
 */
interface ILegionSealedBidSale is ILegionAbstractSale {
    /// @dev Struct defining initialization parameters for the sealed bid sale
    struct SealedBidSaleInitializationParams {
        // Public key used to encrypt sealed bids
        Point publicKey;
    }

    /// @dev Struct containing the runtime configuration of the sealed bid sale
    struct SealedBidSaleConfiguration {
        // Duration of the refund period in seconds
        uint64 refundPeriodSeconds;
        // Flag indicating if sale cancellation is locked
        bool cancelLocked;
        // Public key used to encrypt sealed bids
        Point publicKey;
        // Private key used to decrypt sealed bids
        uint256 privateKey;
        // Fixed salt value for bid encryption
        uint256 fixedSalt;
    }

    /// @dev Struct representing an encrypted bid's components
    struct EncryptedBid {
        // Encrypted bid amount of tokens from the investor
        uint256 encryptedAmountOut;
        // Public key used to encrypt the bid
        Point publicKey;
    }

    /// @notice Emitted when capital is successfully invested in the sealed bid sale.
    /// @param amount The amount of capital invested (in bid tokens).
    /// @param encryptedAmountOut The encrypted bid amount of tokens from the investor.
    /// @param investor The address of the investor.
    /// @param positionId The unique identifier for the investment position.
    event CapitalInvested(uint256 amount, uint256 encryptedAmountOut, address investor, uint256 positionId);

    /// @notice Emitted when the total capital raised is published by the Legion admin.
    /// @param capitalRaised The total capital raised by the project.
    event CapitalRaisedPublished(uint256 capitalRaised);

    /// @notice Emitted when the sealed bid reveal process is initialized.
    event RevealInitialized();

    /// @notice Emitted when sealed bids are revealed by the Legion admin.
    /// @param sealedBidPrivateKey The private key used to decrypt sealed bids.
    /// @param fixedSalt The fixed salt used for sealing bids.
    event Revealed(uint256 sealedBidPrivateKey, uint256 fixedSalt);

    /// @notice Emitted when the sale is ended by Legion or project.
    event SaleEnded();

    /// @notice Initializes the sealed bid sale contract with parameters.
    /// @param saleInitParams The Legion sale initialization parameters.
    /// @param sealedBidSaleInitParams The sealed bid sale-specific parameters.
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        SealedBidSaleInitializationParams calldata sealedBidSaleInitParams
    )
        external;

    /// @notice Allows an investor to invest in the sealed bid sale.
    /// @param amount The amount of capital to invest.
    /// @param deadline The deadline for the investment.
    /// @param sealedBid The encoded sealed bid data (encrypted amount out, salt, public key).
    /// @param signature The Legion signature for investor verification.
    function invest(
        uint256 amount,
        uint256 deadline,
        bytes calldata sealedBid,
        bytes calldata signature
    )
        external
        payable;

    /// @notice Locks sale cancellation to initialize publishing of results.
    function initializeReveal() external;

    /// @notice Publishes sale results including token allocation and capital raised.
    /// @param sealedBidPrivateKey The private key to decrypt sealed bids.
    /// @param fixedSalt The fixed salt used for sealing bids.
    function reveal(uint256 sealedBidPrivateKey, uint256 fixedSalt) external;

    /// @notice Ends the sale and sets the refund period.
    function end() external;

    /// @notice Publishes the total capital raised.
    /// @param capitalRaised The total capital raised by the project.
    function publishRaisedCapital(uint256 capitalRaised) external;

    /// @notice Returns the current sealed bid sale configuration.
    /// @dev Provides read-only access to the sale configuration.
    /// @return The complete sealed bid sale configuration struct.
    function sealedBidSaleConfiguration() external view returns (SealedBidSaleConfiguration memory);

    /// @notice Decrypts a sealed bid using the published private key.
    /// @param encryptedAmountOut The encrypted bid amount from the investor.
    /// @param investor The address of the investor who made the bid.
    /// @return The decrypted bid amount.
    function decryptSealedBid(uint256 encryptedAmountOut, address investor) external view returns (uint256);
}
