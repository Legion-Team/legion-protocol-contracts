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

import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { ECIES, Point } from "../lib/ECIES.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionSale } from "../interfaces/sales/ILegionSale.sol";
import { ILegionSealedBidAuctionSale } from "../interfaces/sales/ILegionSealedBidAuctionSale.sol";

import { LegionSale } from "./LegionSale.sol";

/**
 * @title Legion Sealed Bid Auction
 * @author Legion
 * @notice A contract used to execute sealed bid auctions of ERC20 tokens after TGE
 * @dev Inherits from LegionSale and implements ILegionSealedBidAuctionSale with encryption features
 */
contract LegionSealedBidAuctionSale is LegionSale, ILegionSealedBidAuctionSale {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the sealed bid auction sale configuration
    /// @dev Stores auction-specific parameters like encryption keys and cancel lock
    SealedBidAuctionSaleConfiguration private sealedBidAuctionSaleConfig;

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the sealed bid auction sale contract with parameters
     * @dev Sets up common and auction-specific configurations; callable only once
     * @param saleInitParams Calldata struct with Legion sale initialization parameters
     * @param sealedBidAuctionSaleInitParams Calldata struct with sealed bid auction-specific parameters
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams
    )
        external
        initializer
    {
        // Verify if the sale initialization parameters are valid.
        _verifyValidParams(sealedBidAuctionSaleInitParams);

        // Init and set the sale common params
        _setLegionSaleConfig(saleInitParams);

        // Set the sealed bid auction sale specific configuration
        (sealedBidAuctionSaleConfig.publicKey) = sealedBidAuctionSaleInitParams.publicKey;

        // Calculate and set startTime, endTime and refundEndTime
        saleConfig.startTime = block.timestamp;
        saleConfig.endTime = saleConfig.startTime + saleInitParams.salePeriodSeconds;
        saleConfig.refundEndTime = saleConfig.endTime + saleInitParams.refundPeriodSeconds;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows an investor to invest in the sealed bid auction
     * @dev Verifies conditions, handles encrypted bids, and transfers capital
     * @param amount Amount of capital (in bid tokens) to invest
     * @param sealedBid Encoded sealed bid data (encrypted amount out, salt, public key)
     * @param signature Legion signature for investor verification
     */
    function invest(uint256 amount, bytes calldata sealedBid, bytes memory signature) external whenNotPaused {
        // Verify that the investor is allowed to pledge capital
        _verifyLegionSignature(signature);

        // Decode the sealed bid data
        (uint256 encryptedAmountOut, uint256 salt, Point memory sealedBidPublicKey) =
            abi.decode(sealedBid, (uint256, uint256, Point));

        // Verify that the provided salt is valid
        _verifyValidSalt(salt);

        // Verify that the provided public key is valid
        _verifyValidPublicKey(sealedBidPublicKey);

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the amount pledged is more than the minimum required
        _verifyMinimumInvestAmount(amount);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        // Verify that the investor has not claimed excess capital
        _verifyHasNotClaimedExcess();

        // Increment total capital pledged from investors
        saleStatus.totalCapitalInvested += amount;

        // Increment total pledged capital for the investor
        investorPositions[msg.sender].investedCapital += amount;

        // Emit CapitalInvested
        emit CapitalInvested(amount, encryptedAmountOut, salt, msg.sender, block.timestamp);

        // Transfer the pledged capital to the contract
        SafeTransferLib.safeTransferFrom(addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Locks sale cancellation to initialize publishing of results
     * @dev Restricted to Legion; prevents cancellation during result publication
     */
    function initializePublishSaleResults() external onlyLegion {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that canceling is not locked
        _verifyCancelNotLocked();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        // Flag that the sale is locked from canceling
        sealedBidAuctionSaleConfig.cancelLocked = true;

        // Emit PublishSaleResultsInitialized
        emit PublishSaleResultsInitialized();
    }

    /**
     * @notice Publishes auction results including token allocation and capital raised
     * @dev Restricted to Legion; sets final sale data and decryption key
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     * @param tokensAllocated Total tokens allocated for investors
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
        external
        onlyLegion
    {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that canceling is locked
        _verifyCancelLocked();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify if the provided private key is valid
        _verifyValidPrivateKey(sealedBidPrivateKey);

        // Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        // Set the merkle root for claiming tokens
        saleStatus.claimTokensMerkleRoot = claimMerkleRoot;

        // Set the merkle root for accepted capital
        saleStatus.acceptedCapitalMerkleRoot = acceptedMerkleRoot;

        // Set the total tokens to be allocated by the Project team
        saleStatus.totalTokensAllocated = tokensAllocated;

        // Set the total capital raised to be withdrawn by the project
        saleStatus.totalCapitalRaised = capitalRaised;

        // Set the private key used to decrypt sealed bids
        sealedBidAuctionSaleConfig.privateKey = sealedBidPrivateKey;

        // Emit SaleResultsPublished
        emit SaleResultsPublished(
            claimMerkleRoot, acceptedMerkleRoot, tokensAllocated, capitalRaised, sealedBidPrivateKey
        );
    }

    /**
     * @notice Returns the current sealed bid auction sale configuration
     * @dev Provides read-only access to sealedBidAuctionSaleConfig
     * @return SealedBidAuctionSaleConfiguration memory Struct containing auction configuration
     */
    function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory) {
        return sealedBidAuctionSaleConfig;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Cancels the ongoing sealed bid auction sale
     * @dev Overrides LegionSale; restricted to Project admin with additional lock check
     */
    function cancelSale() public override(ILegionSale, LegionSale) onlyProject whenNotPaused {
        // Call parent method
        super.cancelSale();

        // Verify that canceling is not locked.
        _verifyCancelNotLocked();
    }

    /**
     * @notice Decrypts a sealed bid using the published private key
     * @dev View function requiring published private key; returns decrypted bid amount
     * @param encryptedAmountOut Encrypted bid amount from the investor
     * @param salt Salt used in the encryption process
     * @return uint256 Decrypted bid amount
     */
    function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) external view returns (uint256) {
        // Verify that the private key has been published by Legion
        _verifyPrivateKeyIsPublished();

        // Decrypt the sealed bid
        return ECIES.decrypt(
            encryptedAmountOut, sealedBidAuctionSaleConfig.publicKey, sealedBidAuctionSaleConfig.privateKey, salt
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies the validity of sealed bid auction initialization parameters
     * @dev Private pure function checking public key validity
     * @param sealedBidAuctionSaleInitParams Calldata struct with auction-specific parameters
     */
    function _verifyValidParams(SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams)
        private
        pure
    {
        // Check if the public key used for encryption is valid
        if (!ECIES.isValid(sealedBidAuctionSaleInitParams.publicKey)) {
            revert Errors.InvalidBidPublicKey();
        }
    }

    /**
     * @notice Verifies the validity of the public key used in a sealed bid
     * @dev Ensures the public key matches the auction's configured key
     * @param _publicKey Public key provided in the sealed bid
     */
    function _verifyValidPublicKey(Point memory _publicKey) private view {
        // Verify that the _publicKey is a valid point for the encryption library
        if (!ECIES.isValid(_publicKey)) revert Errors.InvalidBidPublicKey();

        // Verify that the _publicKey is the one used for the entire auction
        if (
            keccak256(abi.encodePacked(_publicKey.x, _publicKey.y))
                != keccak256(
                    abi.encodePacked(sealedBidAuctionSaleConfig.publicKey.x, sealedBidAuctionSaleConfig.publicKey.y)
                )
        ) revert Errors.InvalidBidPublicKey();
    }

    /**
     * @notice Verifies the validity of the private key for decrypting bids
     * @dev Ensures key is unpublished and matches the public key
     * @param _privateKey Private key provided for decryption
     */
    function _verifyValidPrivateKey(uint256 _privateKey) private view {
        // Verify that the private key has not already been published
        if (sealedBidAuctionSaleConfig.privateKey != 0) {
            revert Errors.PrivateKeyAlreadyPublished();
        }

        // Verify that the private key is valid for the public key
        Point memory calcPubKey = ECIES.calcPubKey(Point(1, 2), _privateKey);
        if (
            calcPubKey.x != sealedBidAuctionSaleConfig.publicKey.x
                || calcPubKey.y != sealedBidAuctionSaleConfig.publicKey.y
        ) revert Errors.InvalidBidPrivateKey();
    }

    /**
     * @notice Verifies that the private key has been published
     * @dev Reverts if private key is not set for decryption
     */
    function _verifyPrivateKeyIsPublished() private view {
        if (sealedBidAuctionSaleConfig.privateKey == 0) {
            revert Errors.PrivateKeyNotPublished();
        }
    }

    /**
     * @notice Verifies the validity of the salt used in bid encryption
     * @dev Ensures salt matches investor address for security
     * @param _salt Salt value provided in the sealed bid
     */
    function _verifyValidSalt(uint256 _salt) private view {
        if (uint256(uint160(msg.sender)) != _salt) revert Errors.InvalidSalt();
    }

    /**
     * @notice Verifies that cancellation is not locked
     * @dev Reverts if cancellation is locked during result publication
     */
    function _verifyCancelNotLocked() private view {
        if (sealedBidAuctionSaleConfig.cancelLocked) {
            revert Errors.CancelLocked();
        }
    }

    /**
     * @notice Verifies that cancellation is locked
     * @dev Reverts if cancellation is not locked during result publication
     */
    function _verifyCancelLocked() private view {
        if (!sealedBidAuctionSaleConfig.cancelLocked) {
            revert Errors.CancelNotLocked();
        }
    }
}
