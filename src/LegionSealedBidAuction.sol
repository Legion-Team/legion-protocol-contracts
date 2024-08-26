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
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {LegionBaseSale} from "./LegionBaseSale.sol";
import {ECIES, Point} from "./lib/ECIES.sol";
import {ILegionBaseSale} from "./interfaces/ILegionBaseSale.sol";
import {ILegionSealedBidAuction} from "./interfaces/ILegionSealedBidAuction.sol";
import {ILegionLinearVesting} from "./interfaces/ILegionLinearVesting.sol";
import {ILegionVestingFactory} from "./interfaces/ILegionVestingFactory.sol";

/**
 * @title Legion Sealed Bid Auction.
 * @author Legion.
 * @notice A contract used to execute seale bid auctions of ERC20 tokens after TGE.
 */
contract LegionSealedBidAuction is LegionBaseSale, ILegionSealedBidAuction {
    using SafeERC20 for IERC20;

    /// @dev The public key used to encrypt the sealed bids.
    Point private publicKey;

    /// @dev The private key used to decrypt the bids. Not set until results are published.
    uint256 private privateKey;

    /// @dev Boolean representing if canceling of the sale is locked
    bool private cancelLocked;

    /**
     * @notice See {ILegionSealedBidAuction-initialize}.
     */
    function initialize(
        SealedBidAuctionPeriodAndFeeConfig calldata sealedBidAuctionPeriodAndFeeConfig,
        SealedBidAuctionAddressConfig calldata sealedBidAuctionAddressConfig
    ) external initializer {
        /// Initialize sealed bid auction period and fee configuration
        salePeriodSeconds = sealedBidAuctionPeriodAndFeeConfig.salePeriodSeconds;
        refundPeriodSeconds = sealedBidAuctionPeriodAndFeeConfig.refundPeriodSeconds;
        lockupPeriodSeconds = sealedBidAuctionPeriodAndFeeConfig.lockupPeriodSeconds;
        vestingDurationSeconds = sealedBidAuctionPeriodAndFeeConfig.vestingDurationSeconds;
        vestingCliffDurationSeconds = sealedBidAuctionPeriodAndFeeConfig.vestingCliffDurationSeconds;
        legionFeeOnCapitalRaisedBps = sealedBidAuctionPeriodAndFeeConfig.legionFeeOnCapitalRaisedBps;
        legionFeeOnTokensSoldBps = sealedBidAuctionPeriodAndFeeConfig.legionFeeOnTokensSoldBps;
        minimumPledgeAmount = sealedBidAuctionPeriodAndFeeConfig.minimumPledgeAmount;
        publicKey = sealedBidAuctionPeriodAndFeeConfig.publicKey;

        /// Initialize sealed bid auction address configuration
        bidToken = sealedBidAuctionAddressConfig.bidToken;
        askToken = sealedBidAuctionAddressConfig.askToken;
        projectAdmin = sealedBidAuctionAddressConfig.projectAdmin;
        legionAdmin = sealedBidAuctionAddressConfig.legionAdmin;
        legionSigner = sealedBidAuctionAddressConfig.legionSigner;
        vestingFactory = sealedBidAuctionAddressConfig.vestingFactory;

        /// Calculate and set startTime, endTime and refundEndTime
        startTime = block.timestamp;
        endTime = startTime + sealedBidAuctionPeriodAndFeeConfig.salePeriodSeconds;
        refundEndTime = endTime + sealedBidAuctionPeriodAndFeeConfig.refundPeriodSeconds;

        /// Check if lockupPeriodSeconds is less than refundPeriodSeconds
        /// lockupEndTime should be at least refundEndTime
        if (
            sealedBidAuctionPeriodAndFeeConfig.lockupPeriodSeconds
                <= sealedBidAuctionPeriodAndFeeConfig.refundPeriodSeconds
        ) {
            /// If yes, set lockupEndTime to be refundEndTime
            lockupEndTime = refundEndTime;
        } else {
            /// If no, calculate the lockupEndTime
            lockupEndTime = endTime + sealedBidAuctionPeriodAndFeeConfig.lockupPeriodSeconds;
        }

        // Set the vestingStartTime to begin when lockupEndTime is reached
        vestingStartTime = lockupEndTime;

        /// Verify if the sale configuration is valid
        _verifyValidConfig(sealedBidAuctionPeriodAndFeeConfig, sealedBidAuctionAddressConfig);
    }

    /**
     * @notice See {ILegionSealedBidAuction-pledgeCapital}.
     */
    function pledgeCapital(uint256 amount, bytes calldata sealedBid, bytes memory signature) external {
        /// Verify that the investor is allowed to pledge capital
        _verifyLegionSignature(signature);

        /// Decode the sealed bid data
        (uint256 encryptedAmountOut, uint256 salt, Point memory sealedBidPublicKey) =
            abi.decode(sealedBid, (uint256, uint256, Point));

        /// Verify that the provided salt is valid
        _verifyValidSalt(salt);

        /// Verify that the provided public key is valid
        _verifyValidPublicKey(sealedBidPublicKey);

        /// Verify that the sale has not ended
        _verifySaleHasNotEnded();

        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the amount pledged is more than the minimum required
        _verifyMinimumPledgeAmount(amount);

        /// Increment total capital pledged from investors
        totalCapitalPledged += amount;

        /// Increment total pledged capital for the investor
        investorPositions[msg.sender].pledgedCapital += amount;

        /// Emit successfully CapitalPledged
        emit CapitalPledged(amount, encryptedAmountOut, salt, msg.sender, block.timestamp);

        /// Transfer the pledged capital to the contract
        IERC20(bidToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice See {ILegionSealedBidAuction-initializePublishSaleResults}.
     */
    function initializePublishSaleResults() external onlyLegion {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that canceling is not locked
        _verifyCancelNotLocked();

        /// Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        /// Flag the the sale is locked from canceling
        cancelLocked = true;

        /// Emit successfully PublishSaleResultsInitialized
        emit PublishSaleResultsInitialized();
    }

    /**
     * @notice See {ILegionSealedBidAuction-publishSaleResults}.
     */
    function publishSaleResults(
        bytes32 merkleRoot,
        uint256 tokensAllocated,
        uint256 capitalRaised,
        uint256 sealedBidPrivateKey
    ) external onlyLegion {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that canceling is locked
        _verifyCancelLocked();

        /// Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Verify if the provided private key is valid
        _verifyValidPrivateKey(sealedBidPrivateKey);

        /// Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        /// Set the merkle root for claiming tokens
        claimTokensMerkleRoot = merkleRoot;

        /// Set the total tokens to be allocated by the Project team
        totalTokensAllocated = tokensAllocated;

        /// Set the total capital raised to be withdrawn by the project
        totalCapitalRaised = capitalRaised;

        /// Set the private key used to decrypt sealed bids
        privateKey = sealedBidPrivateKey;

        /// Emit successfully SaleResultsPublished
        emit SaleResultsPublished(merkleRoot, tokensAllocated, capitalRaised, sealedBidPrivateKey);
    }

    /**
     * @notice See {ILegionBaseSale-cancelSale}.
     */
    function cancelSale() public virtual override(ILegionBaseSale, LegionBaseSale) onlyProject {
        /// Call parent method
        super.cancelSale();

        /// Verify that canceling the sale is not locked.
        _verifyCancelNotLocked();
    }

    /**
     * @notice See {ILegionSealedBidAuction-salePeriodAndFeeConfiguration}.
     */
    function salePeriodAndFeeConfiguration()
        external
        view
        returns (SealedBidAuctionPeriodAndFeeConfig memory salePeriodAndFeeConfig)
    {
        /// Get the sealed bid auction period and fee config
        salePeriodAndFeeConfig = SealedBidAuctionPeriodAndFeeConfig(
            salePeriodSeconds,
            refundPeriodSeconds,
            lockupPeriodSeconds,
            vestingDurationSeconds,
            vestingCliffDurationSeconds,
            legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps,
            minimumPledgeAmount,
            publicKey
        );
    }

    /**
     * @notice See {ILegionSealedBidAuction-saleAddressConfiguration}.
     */
    function saleAddressConfiguration()
        external
        view
        returns (SealedBidAuctionAddressConfig memory saleAddressConfig)
    {
        /// Get the sealed bid auction address config
        saleAddressConfig =
            SealedBidAuctionAddressConfig(bidToken, askToken, projectAdmin, legionAdmin, legionSigner, vestingFactory);
    }

    /**
     * @notice See {ILegionSealedBidAuction-saleStatus}.
     */
    function saleStatus() external view returns (SealedBidAuctionStatus memory sealedBidAuctionStatus) {
        /// Get the sealed bid auction status
        sealedBidAuctionStatus = SealedBidAuctionStatus(
            startTime,
            endTime,
            refundEndTime,
            lockupEndTime,
            vestingStartTime,
            totalCapitalPledged,
            totalTokensAllocated,
            totalCapitalRaised,
            privateKey,
            claimTokensMerkleRoot,
            excessCapitalMerkleRoot,
            isCanceled,
            tokensSupplied
        );
    }

    /**
     * @notice See {ILegionSealedBidAuction-decryptBid}.
     */
    function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) public view returns (uint256) {
        /// Verify that the private key has been published by Legion
        _verifyPrivateKeyIsPublished();

        /// Decrypt the sealed bid
        return ECIES.decrypt(encryptedAmountOut, publicKey, privateKey, salt);
    }

    /**
     * @notice Verify if the sale configuration is valid.
     *
     * @param _sealedBidAuctionPeriodAndFeeConfig The period and fee configuration for the sealed bid auction.
     * @param _sealedBidAuctionAddressConfig The address configuration for the sealed bid auction.
     */
    function _verifyValidConfig(
        SealedBidAuctionPeriodAndFeeConfig calldata _sealedBidAuctionPeriodAndFeeConfig,
        SealedBidAuctionAddressConfig calldata _sealedBidAuctionAddressConfig
    ) private pure {
        /// Check for zero addresses provided
        if (
            _sealedBidAuctionAddressConfig.bidToken == address(0)
                || _sealedBidAuctionAddressConfig.projectAdmin == address(0)
                || _sealedBidAuctionAddressConfig.legionAdmin == address(0)
                || _sealedBidAuctionAddressConfig.legionSigner == address(0)
                || _sealedBidAuctionAddressConfig.vestingFactory == address(0)
        ) revert ZeroAddressProvided();

        /// Check for zero values provided
        if (
            _sealedBidAuctionPeriodAndFeeConfig.salePeriodSeconds == 0
                || _sealedBidAuctionPeriodAndFeeConfig.refundPeriodSeconds == 0
                || _sealedBidAuctionPeriodAndFeeConfig.lockupPeriodSeconds == 0
        ) revert ZeroValueProvided();

        /// Check if the public key used for encryption is valid
        if (!ECIES.isValid(_sealedBidAuctionPeriodAndFeeConfig.publicKey)) revert InvalidBidPublicKey();

        /// Check if sale, refund and lockup periods are longer than allowed
        if (
            _sealedBidAuctionPeriodAndFeeConfig.salePeriodSeconds > THREE_MONTHS
                || _sealedBidAuctionPeriodAndFeeConfig.refundPeriodSeconds > TWO_WEEKS
                || _sealedBidAuctionPeriodAndFeeConfig.lockupPeriodSeconds > SIX_MONTHS
        ) revert InvalidPeriodConfig();

        /// Check if sale, refund and lockup periods are shorter than allowed
        if (
            _sealedBidAuctionPeriodAndFeeConfig.salePeriodSeconds < ONE_HOUR
                || _sealedBidAuctionPeriodAndFeeConfig.refundPeriodSeconds < ONE_HOUR
                || _sealedBidAuctionPeriodAndFeeConfig.lockupPeriodSeconds < ONE_HOUR
        ) revert InvalidPeriodConfig();
    }

    /**
     * @notice Verify if the public key used to encrpyt the bid is valid.
     *
     * @param _publicKey The public key used to encrypt bids.
     */
    function _verifyValidPublicKey(Point memory _publicKey) private view {
        /// Verify that the _publicKey is a valid point for the encryption library
        if (!ECIES.isValid(_publicKey)) revert InvalidBidPublicKey();

        /// Verify that the _publicKey is the one used for the entire auction
        if (
            keccak256(abi.encodePacked(_publicKey.x, _publicKey.y))
                != keccak256(abi.encodePacked(publicKey.x, publicKey.y))
        ) revert InvalidBidPublicKey();
    }

    /**
     * @notice Verify if the provided private key is valid.
     *
     * @param _privateKey The private key used to decrypt bids.
     */
    function _verifyValidPrivateKey(uint256 _privateKey) private view {
        /// Verify that the private key has not already been published
        if (privateKey != 0) revert PrivateKeyAlreadyPublished();

        /// Verify that the private key is valid for the public key
        Point memory calcPubKey = ECIES.calcPubKey(Point(1, 2), _privateKey);
        if (calcPubKey.x != publicKey.x || calcPubKey.y != publicKey.y) revert InvalidBidPrivateKey();
    }

    /**
     * @notice Verify that the private key has been published by Legion.
     */
    function _verifyPrivateKeyIsPublished() private view {
        if (privateKey == 0) revert PrivateKeyNotPublished();
    }

    /**
     * @notice Verify that the salt used to encrypt the bid is valid.
     *
     * @param _salt The salt used for bid encryption
     */
    function _verifyValidSalt(uint256 _salt) private view {
        if (uint256(uint160(msg.sender)) != _salt) revert InvalidSalt();
    }

    /**
     * @notice Verify that canceling the is not locked.
     */
    function _verifyCancelNotLocked() private view {
        if (cancelLocked) revert CancelLocked();
    }

    /**
     * @notice Verify that canceling is locked.
     */
    function _verifyCancelLocked() private view {
        if (!cancelLocked) revert CancelNotLocked();
    }
}
