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

import { ECIES, Point } from "../../lib/ECIES.sol";
import { ILegionAbstractSale } from "./ILegionAbstractSale.sol";

/**
 * @title ILegionSealedBidAuctionSale
 * @author Legion
 * @notice Interface for managing sealed bid auctions of ERC20 tokens post-TGE in the Legion Protocol
 * @dev Extends ILegionAbstractSale with sealed bid auction-specific functionality and encryption features
 */
interface ILegionSealedBidAuctionSale is ILegionAbstractSale {
    /// @notice Struct defining initialization parameters for the sealed bid auction sale
    struct SealedBidAuctionSaleInitializationParams {
        /// @notice Public key used to encrypt sealed bids
        /// @dev ECIES-compliant public key for bid encryption
        Point publicKey;
    }

    /// @notice Struct containing the runtime configuration of the sealed bid auction sale
    struct SealedBidAuctionSaleConfiguration {
        /// @notice Public key used to encrypt sealed bids
        /// @dev Set at initialization for bid encryption
        Point publicKey;
        /// @notice Private key used to decrypt sealed bids
        /// @dev Set when sale results are published; initially zero
        uint256 privateKey;
        /// @notice Flag indicating if sale cancellation is locked
        /// @dev Prevents cancellation during result publication
        bool cancelLocked;
    }

    /// @notice Struct representing an encrypted bid's components
    struct EncryptedBid {
        /// @notice Encrypted bid amount of tokens from the investor
        /// @dev Encrypted using the auction's public key
        uint256 encryptedAmountOut;
        /// @notice Public key used to encrypt the bid
        /// @dev Matches the auction's configured public key
        Point publicKey;
    }

    /**
     * @notice Emitted when capital is successfully invested in the sealed bid auction
     * @dev Logs investment details including encrypted bid data
     * @param amount Amount of capital invested (in bid tokens)
     * @param encryptedAmountOut Encrypted bid amount of tokens from the investor
     * @param salt Unique salt used in encryption (typically investor address)
     * @param investor Address of the investor
     * @param positionId Unique identifier for the investment position
     */
    event CapitalInvested(
        uint256 amount, uint256 encryptedAmountOut, uint256 salt, address investor, uint256 positionId
    );

    /**
     * @notice Emitted when the process of publishing sale results is initialized
     * @dev Indicates cancellation lock has been set
     */
    event PublishSaleResultsInitialized();

    /**
     * @notice Emitted when sale results are published by the Legion admin
     * @dev Logs final auction outcomes and decryption key
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     * @param tokensAllocated Total tokens allocated from the sale
     * @param capitalRaised Total capital raised from the auction
     * @param sealedBidPrivateKey Private key used to decrypt sealed bids
     */
    event SaleResultsPublished(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint256 capitalRaised,
        uint256 sealedBidPrivateKey
    );

    /**
     * @notice Initializes the sealed bid auction sale with parameters
     * @dev Must set up both common sale and auction-specific configurations
     * @param saleInitParams Calldata struct with Legion sale initialization parameters
     * @param sealedBidAuctionSaleInitParams Calldata struct with auction-specific parameters
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams
    )
        external;

    /**
     * @notice Allows investment into the sealed bid auction
     * @dev Must verify eligibility, handle encrypted bid, and transfer capital
     * @param amount Amount of capital (in bid tokens) to invest
     * @param sealedBid Encoded sealed bid data (encrypted amount out, salt, public key)
     * @param signature Legion signature for investor verification
     */
    function invest(uint256 amount, bytes calldata sealedBid, bytes memory signature) external;

    /**
     * @notice Initializes the publishing of sale results by locking cancellation
     * @dev Must prevent sale cancellation during result preparation
     */
    function initializePublishSaleResults() external;

    /**
     * @notice Publishes auction results after conclusion
     * @dev Must be restricted to Legion admin; sets final data and decryption key
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     * @param tokensAllocated Total tokens allocated for distribution
     * @param capitalRaised Total capital raised from the auction
     * @param sealedBidPrivateKey Private key to decrypt sealed bids
     */
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint256 capitalRaised,
        uint256 sealedBidPrivateKey
    )
        external;

    /**
     * @notice Decrypts a sealed bid using the published private key
     * @dev Must require a published private key; returns decrypted bid amount
     * @param encryptedAmountOut Encrypted bid amount from the investor
     * @param salt Salt used in the encryption process
     * @return uint256 Decrypted amount of tokens bid for
     */
    function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) external view returns (uint256);

    /**
     * @notice Retrieves the current sealed bid auction sale configuration
     * @dev Must return the SealedBidAuctionSaleConfiguration struct
     * @return SealedBidAuctionSaleConfiguration memory Struct containing auction configuration
     */
    function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory);
}
