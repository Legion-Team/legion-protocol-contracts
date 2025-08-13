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
 * @title ILegionSealedBidAuctionSale
 * @author Legion
 * @notice Interface for the LegionSealedBidAuctionSale contract.
 */
interface ILegionSealedBidAuctionSale is ILegionAbstractSale {
    /// @dev Struct defining initialization parameters for the sealed bid auction sale
    struct SealedBidAuctionSaleInitializationParams {
        // Public key used to encrypt sealed bids
        Point publicKey;
    }

    /// @dev Struct containing the runtime configuration of the sealed bid auction sale
    struct SealedBidAuctionSaleConfiguration {
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

    /// @notice Emitted when capital is successfully invested in the sealed bid auction.
    /// @param amount The amount of capital invested (in bid tokens).
    /// @param encryptedAmountOut The encrypted bid amount of tokens from the investor.
    /// @param investor The address of the investor.
    /// @param positionId The unique identifier for the investment position.
    event CapitalInvested(uint256 amount, uint256 encryptedAmountOut, address investor, uint256 positionId);

    /// @notice Emitted when the process of publishing sale results is initialized.
    event PublishSaleResultsInitialized();

    /// @notice Emitted when sale results are published by the Legion admin.
    /// @param claimMerkleRoot The Merkle root for verifying token claims.
    /// @param acceptedMerkleRoot The Merkle root for verifying accepted capital.
    /// @param tokensAllocated The total tokens allocated from the sale.
    /// @param capitalRaised The total capital raised from the auction.
    /// @param sealedBidPrivateKey The private key used to decrypt sealed bids.
    /// @param fixedSalt The fixed salt used for sealing bids.
    event SaleResultsPublished(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint256 capitalRaised,
        uint256 sealedBidPrivateKey,
        uint256 fixedSalt
    );

    /// @notice Initializes the sealed bid auction sale contract with parameters.
    /// @param saleInitParams The Legion sale initialization parameters.
    /// @param sealedBidAuctionSaleInitParams The sealed bid auction-specific parameters.
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams
    )
        external;

    /// @notice Allows an investor to invest in the sealed bid auction.
    /// @param amount The amount of capital to invest.
    /// @param sealedBid The encoded sealed bid data (encrypted amount out, salt, public key).
    /// @param signature The Legion signature for investor verification.
    function invest(uint256 amount, bytes calldata sealedBid, bytes calldata signature) external;

    /// @notice Locks sale cancellation to initialize publishing of results.
    function initializePublishSaleResults() external;

    /// @notice Publishes auction results including token allocation and capital raised.
    /// @param claimMerkleRoot The Merkle root for verifying token claims.
    /// @param acceptedMerkleRoot The Merkle root for verifying accepted capital.
    /// @param tokensAllocated The total tokens allocated for investors.
    /// @param capitalRaised The total capital raised from the auction.
    /// @param sealedBidPrivateKey The private key to decrypt sealed bids.
    /// @param fixedSalt The fixed salt used for sealing bids.
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint256 capitalRaised,
        uint256 sealedBidPrivateKey,
        uint256 fixedSalt
    )
        external;

    /// @notice Returns the current sealed bid auction sale configuration.
    /// @dev Provides read-only access to the auction configuration.
    /// @return The complete sealed bid auction sale configuration struct.
    function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory);

    /// @notice Decrypts a sealed bid using the published private key.
    /// @param encryptedAmountOut The encrypted bid amount from the investor.
    /// @param investor The address of the investor who made the bid.
    /// @return The decrypted bid amount.
    function decryptSealedBid(uint256 encryptedAmountOut, address investor) external view returns (uint256);
}
