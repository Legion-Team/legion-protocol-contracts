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

import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { ECIES, Point } from "./lib/ECIES.sol";
import { Errors } from "./utils/Errors.sol";
import { ILegionSale } from "./interfaces/ILegionSale.sol";
import { ILegionSealedBidAuctionSale } from "./interfaces/ILegionSealedBidAuctionSale.sol";
import { LegionSale } from "./LegionSale.sol";

/**
 * @title Legion Sealed Bid Auction.
 * @author Legion.
 * @notice A contract used to execute seale bid auctions of ERC20 tokens after TGE.
 */
contract LegionSealedBidAuctionSale is LegionSale, ILegionSealedBidAuctionSale {
    /// @dev A struct describing the sealed bid auction sale configuration.
    SealedBidAuctionSaleConfiguration private sealedBidAuctionSaleConfig;

    /**
     * @notice See {ILegionSealedBidAuctionSale-initialize}.
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams,
        LegionVestingInitializationParams calldata vestingInitParams
    )
        external
        initializer
    {
        // Verify if the sale initialization parameters are valid.
        _verifyValidParams(sealedBidAuctionSaleInitParams);

        // Init and set the sale common params
        _setLegionSaleConfig(saleInitParams, vestingInitParams);

        // Set the sealed bid auction sale specific configuration
        (sealedBidAuctionSaleConfig.publicKey) = sealedBidAuctionSaleInitParams.publicKey;

        // Calculate and set startTime, endTime and refundEndTime
        saleConfig.startTime = block.timestamp;
        saleConfig.endTime = saleConfig.startTime + saleInitParams.salePeriodSeconds;
        saleConfig.refundEndTime = saleConfig.endTime + saleInitParams.refundPeriodSeconds;

        // Check if lockupPeriodSeconds is less than refundPeriodSeconds
        // lockupEndTime should be at least refundEndTime
        if (saleInitParams.lockupPeriodSeconds <= saleInitParams.refundPeriodSeconds) {
            // If yes, set lockupEndTime to be refundEndTime
            saleConfig.lockupEndTime = saleConfig.refundEndTime;
        } else {
            // If no, calculate the lockupEndTime
            saleConfig.lockupEndTime = saleConfig.endTime + saleInitParams.lockupPeriodSeconds;
        }

        // Set the vestingStartTime to begin when lockupEndTime is reached
        vestingConfig.vestingStartTime = saleConfig.lockupEndTime;
    }

    /**
     * @notice See {ILegionSealedBidAuctionSale-invest}.
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
        _verifyMinimumPledgeAmount(amount);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        // Increment total capital pledged from investors
        saleStatus.totalCapitalInvested += amount;

        // Increment total pledged capital for the investor
        investorPositions[msg.sender].investedCapital += amount;

        // Emit successfully CapitalInvested
        emit CapitalInvested(amount, encryptedAmountOut, salt, msg.sender, block.timestamp);

        // Transfer the pledged capital to the contract
        SafeTransferLib.safeTransferFrom(addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice See {ILegionSealedBidAuctionSale-initializePublishSaleResults}.
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

        // Flag the the sale is locked from canceling
        sealedBidAuctionSaleConfig.cancelLocked = true;

        // Emit successfully PublishSaleResultsInitialized
        emit PublishSaleResultsInitialized();
    }

    /**
     * @notice See {ILegionSealedBidAuctionSale-publishSaleResults}.
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

        // Emit successfully SaleResultsPublished
        emit SaleResultsPublished(
            claimMerkleRoot, acceptedMerkleRoot, tokensAllocated, capitalRaised, sealedBidPrivateKey
        );
    }

    /**
     * @notice See {ILegionSale-cancelSale}.
     */
    function cancelSale() public override(ILegionSale, LegionSale) onlyProject whenNotPaused {
        // Call parent method
        super.cancelSale();

        // Verify that canceling the sale is not locked.
        _verifyCancelNotLocked();
    }

    /**
     * @notice See {ILegionSealedBidAuctionSale-decryptBid}.
     */
    function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) public view returns (uint256) {
        // Verify that the private key has been published by Legion
        _verifyPrivateKeyIsPublished();

        // Decrypt the sealed bid
        return ECIES.decrypt(
            encryptedAmountOut, sealedBidAuctionSaleConfig.publicKey, sealedBidAuctionSaleConfig.privateKey, salt
        );
    }

    /**
     * @notice See {ILegionSealedBidAuctionSale-sealedBidAuctionSaleConfiguration}.
     */
    function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory) {
        return sealedBidAuctionSaleConfig;
    }

    /**
     * @notice Verify if the sale initialization parameters are valid.
     */
    function _verifyValidParams(SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams)
        private
        pure
    {
        // Check if the public key used for encryption is valid
        if (!ECIES.isValid(sealedBidAuctionSaleInitParams.publicKey)) revert Errors.InvalidBidPublicKey();
    }

    /**
     * @notice Verify if the public key used to encrpyt the bid is valid.
     *
     * @param _publicKey The public key used to encrypt bids.
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
     * @notice Verify if the provided private key is valid.
     *
     * @param _privateKey The private key used to decrypt bids.
     */
    function _verifyValidPrivateKey(uint256 _privateKey) private view {
        // Verify that the private key has not already been published
        if (sealedBidAuctionSaleConfig.privateKey != 0) revert Errors.PrivateKeyAlreadyPublished();

        // Verify that the private key is valid for the public key
        Point memory calcPubKey = ECIES.calcPubKey(Point(1, 2), _privateKey);
        if (
            calcPubKey.x != sealedBidAuctionSaleConfig.publicKey.x
                || calcPubKey.y != sealedBidAuctionSaleConfig.publicKey.y
        ) revert Errors.InvalidBidPrivateKey();
    }

    /**
     * @notice Verify that the private key has been published by Legion.
     */
    function _verifyPrivateKeyIsPublished() private view {
        if (sealedBidAuctionSaleConfig.privateKey == 0) revert Errors.PrivateKeyNotPublished();
    }

    /**
     * @notice Verify that the salt used to encrypt the bid is valid.
     *
     * @param _salt The salt used for bid encryption
     */
    function _verifyValidSalt(uint256 _salt) private view {
        if (uint256(uint160(msg.sender)) != _salt) revert Errors.InvalidSalt();
    }

    /**
     * @notice Verify that canceling the is not locked.
     */
    function _verifyCancelNotLocked() private view {
        if (sealedBidAuctionSaleConfig.cancelLocked) revert Errors.CancelLocked();
    }

    /**
     * @notice Verify that canceling is locked.
     */
    function _verifyCancelLocked() private view {
        if (!sealedBidAuctionSaleConfig.cancelLocked) revert Errors.CancelNotLocked();
    }
}
