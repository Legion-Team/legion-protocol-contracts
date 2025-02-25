// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

import { ECIES, Point } from "../lib/ECIES.sol";
import { ILegionSale } from "./ILegionSale.sol";

interface ILegionSealedBidAuctionSale is ILegionSale {
    /// @notice A struct describing the sealed bid auction sale initialization params
    struct SealedBidAuctionSaleInitializationParams {
        /// @dev The public key used to encrypt the sealed bids.
        Point publicKey;
    }

    /// @notice A struct describing the sealed bid auction sale configuration
    struct SealedBidAuctionSaleConfiguration {
        /// @dev The public key used to encrypt the sealed bids.
        Point publicKey;
        /// @dev The private key used to decrypt the bids. Not set until results are published.
        uint256 privateKey;
        /// @dev Boolean representing if canceling of the sale is locked
        bool cancelLocked;
    }

    /// @notice A struct describing the encrypted bid
    struct EncryptedBid {
        /// @dev The encrypted amount out.
        uint256 encryptedAmountOut;
        /// @dev The public key used to encrypt the bid
        Point publicKey;
    }

    /**
     * @notice This event is emitted when capital is successfully invested.
     *
     * @param amount The amount of capital invested.
     * @param encryptedAmountOut The encrypted amount out.
     * @param salt The unique salt used in the encryption process.
     * @param investor The address of the investor.
     * @param investTimestamp The Unix timestamp (seconds) of the block when capital has been invested.
     */
    event CapitalInvested(
        uint256 amount, uint256 encryptedAmountOut, uint256 salt, address investor, uint256 investTimestamp
    );

    /**
     * @notice This event is emitted when publishing the sale results has been initialized.
     */
    event PublishSaleResultsInitialized();

    /**
     * @notice This event is emitted when sale results are successfully published by the Legion admin.
     *
     * @param claimMerkleRoot The merkle root to verify token claims.
     * @param acceptedMerkleRoot The merkle root to verify accepted capital.
     * @param tokensAllocated The amount of tokens allocated from the sale.
     * @param capitalRaised The capital raised from the sale.
     * @param sealedBidPrivateKey The private key used to decrypt sealed bids.
     */
    event SaleResultsPublished(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint256 capitalRaised,
        uint256 sealedBidPrivateKey
    );

    /**
     * @notice Initializes the contract with correct parameters.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param sealedBidAuctionSaleInitParams The sealed bid auction sale specific initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams,
        LegionVestingInitializationParams calldata vestingInitParams
    )
        external;

    /**
     * @notice Invest capital to the sealed bid auction.
     *
     * @param amount The amount of capital invested.
     * @param sealedBid The encoded sealed bid data.
     * @param signature The Legion signature for verification.
     */
    function invest(uint256 amount, bytes calldata sealedBid, bytes memory signature) external;

    /**
     * @notice Initializes the process of publishing of sale results, by locking sale cancelation.
     */
    function initializePublishSaleResults() external;

    /**
     * @notice Publish sale results, once the sale has concluded.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param claimMerkleRoot The merkle root to verify token claims.
     * @param acceptedMerkleRoot The merkle root to verify accepted capital.
     * @param tokensAllocated The total amount of tokens allocated for distribution among investors.
     * @param capitalRaised The total capital raised from the auction.
     * @param sealedBidPrivateKey the private key used to decrypt sealed bids.
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
     * @notice Decrypts the sealed bid, once the private key has been published by Legion.
     *
     * @dev Can be called only if the private key has been published.
     *
     * @param encryptedAmountOut The encrypted bid amount
     * @param salt The salt used in the encryption process
     */
    function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) external view returns (uint256);

    /**
     * @notice Returns the sealed bid auction sale configuration.
     */
    function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory);
}
