// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * ██      ███████  ██████  ██  ██████  ███    ██
 * ██      ██      ██       ██ ██    ██ ████   ██
 * ██      █████   ██   ███ ██ ██    ██ ██ ██  ██
 * ██      ██      ██    ██ ██ ██    ██ ██  ██ ██
 * ███████ ███████  ██████  ██  ██████  ██   ████
 *
 * If you find a bug, please contact security(at)legion.cc
 * We will pay a fair bounty for any issue that puts user's funds at risk.
 *
 */
import {ECIES, Point} from "../lib/ECIES.sol";
import {ILegionBaseSale} from "./ILegionBaseSale.sol";

interface ILegionSealedBidAuction is ILegionBaseSale {
    /**
     * @notice This event is emitted when capital is successfully pledged.
     *
     * @param amount The amount of capital pledged.
     * @param encryptedAmountOut The encrpyped amount out.
     * @param salt The unique salt used in the encryption process.
     * @param investor The address of the investor.
     * @param pledgeTimestamp The unix timestamp (seconds) of the block when capital has been pledged.
     */
    event CapitalPledged(
        uint256 amount, uint256 encryptedAmountOut, uint256 salt, address investor, uint256 pledgeTimestamp
    );

    /**
     * @notice This event is emitted when publishing the sale results has been initialized.
     */
    event PublishSaleResultsInitialized();

    /**
     * @notice This event is emitted when sale results are successfully published by the Legion admin.
     *
     * @param merkleRoot The claim merkle root published.
     * @param tokensAllocated The amount of tokens allocated from the sale.
     * @param capitalRaised The capital raised from the sale.
     * @param sealedBidPrivateKey The private key used to decrypt sealed bids.
     */
    event SaleResultsPublished(
        bytes32 merkleRoot, uint256 tokensAllocated, uint256 capitalRaised, uint256 sealedBidPrivateKey
    );

    /**
     * @notice Throws when canceling is locked.
     */
    error CancelLocked();

    /**
     * @notice Throws when canceling is not locked.
     */
    error CancelNotLocked();

    /**
     * @notice Throws when an invalid bid public key is used to encrypt a bid.
     */
    error InvalidBidPublicKey();

    /**
     * @notice Throws when an invalid bid private key is provided to decrypt a bid.
     */
    error InvalidBidPrivateKey();

    /**
     * @notice Throws when the private key has already been published by Legion.
     */
    error PrivateKeyAlreadyPublished();

    /**
     * @notice Throws when the private key has not been published by Legion.
     */
    error PrivateKeyNotPublished();

    /**
     * @notice Throws when the salt used to encrypt the bid is invalid.
     */
    error InvalidSalt();

    /// @notice A struct describing the sealed bid auction configuration.
    struct SealedBidAuctionConfig {
        /// @dev The sale period duration in seconds.
        uint256 salePeriodSeconds;
        /// @dev The refund period duration in seconds.
        uint256 refundPeriodSeconds;
        /// @dev The lockup period duration in seconds.
        uint256 lockupPeriodSeconds;
        /// @dev The vesting schedule duration for the token sold in seconds.
        uint256 vestingDurationSeconds;
        /// @dev The vesting cliff duration for the token sold in seconds.
        uint256 vestingCliffDurationSeconds;
        /// @dev Legion's fee on capital raised in BPS (Basis Points).
        uint256 legionFeeOnCapitalRaisedBps;
        /// @dev Legion's fee on tokens sold in BPS (Basis Points).
        uint256 legionFeeOnTokensSoldBps;
        /// @dev The minimum pledge amount denominated in the `bidToken`
        uint256 minimumPledgeAmount;
        /// @dev The public key used to encrypt the sealed bids.
        Point publicKey;
        /// @dev The address of the token used for raising capital.
        address bidToken;
        /// @dev The address of the token being sold to investors.
        address askToken;
        /// @dev The admin address of the project raising capital.
        address projectAdmin;
        /// @dev The address of Legion's Address Registry contract.
        address addressRegistry;
    }

    /// @notice A struct describing the sealed bid auction status.
    struct SealedBidAuctionStatus {
        /// @dev The unix timestamp (seconds) of the block when the sale starts.
        uint256 startTime;
        /// @dev The unix timestamp (seconds) of the block when the sale ends.
        uint256 endTime;
        /// @dev The unix timestamp (seconds) of the block when the refund period ends.
        uint256 refundEndTime;
        /// @dev The unix timestamp (seconds) of the block when the lockup period ends.
        uint256 lockupEndTime;
        /// @dev The unix timestamp (seconds) of the block when the vesting period starts.
        uint256 vestingStartTime;
        /// @dev The total capital pledged by investors.
        uint256 totalCapitalPledged;
        /// @dev The total amount of tokens allocated to investors.
        uint256 totalTokensAllocated;
        /// @dev The total capital raised from the sale.
        uint256 totalCapitalRaised;
        /// @dev The private key used to decrypt the bids. Not set until results are published.
        uint256 privateKey;
        /// @dev The merkle root for verification of token distribution amounts.
        bytes32 claimTokensMerkleRoot;
        /// @dev The merkle root for verification of excess capital distribution amounts.
        bytes32 excessCapitalMerkleRoot;
        /// @dev Whether the sale has been canceled or not.
        bool isCanceled;
        /// @dev Whether tokens have been supplied by the project or not.
        bool tokensSupplied;
        /// @dev Whether raised capital has been withdrawn from the sale by the project or not.
        bool capitalWithdrawn;
    }

    /// @notice A struct describing the encrypted bid
    struct EncryptedBid {
        /// @dev The encrypted amount out.
        uint256 encryptedAmountOut;
        /// @dev The public key used to encrypt the bid
        Point publicKey;
    }

    /**
     * @notice Initialized the contract with correct parameters.
     *
     * @param sealedBidAuctionConfig The configuration for the sealed bid auction.
     */
    function initialize(SealedBidAuctionConfig calldata sealedBidAuctionConfig) external;

    /**
     * @notice Pledge capital to the sealed bid auction.
     *
     * @param amount The amount of capital pledged.
     * @param sealedBid The encoded sealed bid data.
     * @param signature The Legion signature for verification.
     */
    function pledgeCapital(uint256 amount, bytes calldata sealedBid, bytes memory signature) external;

    /**
     * @notice Initializes the process of publishing of sale results, by locking sale cancelation.
     */
    function initializePublishSaleResults() external;

    /**
     * @notice Publish merkle root for distribution of tokens, once the sale has concluded.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param merkleRoot The merkle root to verify against.
     * @param tokensAllocated The total amount of tokens allocated for distribution among investors.
     * @param capitalRaised The total capital raised from the auction
     * @param sealedBidPrivateKey the private key used to decrypt sealed bids
     */
    function publishSaleResults(
        bytes32 merkleRoot,
        uint256 tokensAllocated,
        uint256 capitalRaised,
        uint256 sealedBidPrivateKey
    ) external;

    /**
     * @notice Returns the configuration for the sealed bid auction.
     */
    function saleConfiguration() external view returns (SealedBidAuctionConfig memory saleConfig);

    /**
     * @notice Returns the status for the sealed bid auction.
     */
    function saleStatus() external view returns (SealedBidAuctionStatus memory sealedBidAuctionStatus);

    /**
     * @notice Decrypts the sealed bid, once the private key has been published by Legion.
     *
     * @dev Can be called only of the private key has been published.
     *
     * @param encryptedAmountOut The encrypted bid amount
     * @param salt The salt used in the encryption process
     */
    function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) external view returns (uint256);
}
