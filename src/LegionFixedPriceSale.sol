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

import {ILegionFixedPriceSale} from "./interfaces/ILegionFixedPriceSale.sol";
import {ILegionLinearVesting} from "./interfaces/ILegionLinearVesting.sol";
import {ILegionVestingFactory} from "./interfaces/ILegionVestingFactory.sol";

/**
 * @title Legion Fixed Price Sale.
 * @author Legion.
 * @notice A contract used to execute fixed price sales of ERC20 tokens after TGE.
 */
contract LegionFixedPriceSale is LegionBaseSale, ILegionFixedPriceSale {
    using SafeERC20 for IERC20;

    /// @dev The prefund period duration in seconds.
    uint256 private prefundPeriodSeconds;

    /// @dev The prefund allocation period duration in seconds.
    uint256 private prefundAllocationPeriodSeconds;

    /// @dev The price of the token being sold denominated in the token used to raise capital.
    uint256 private tokenPrice;

    /// @dev The unix timestamp (seconds) of the block when the prefund starts.
    uint256 private prefundStartTime;

    /// @dev The unix timestamp (seconds) of the block when the prefund ends.
    uint256 private prefundEndTime;

    /**
     * @notice See {ILegionFixedPriceSale-initialize}.
     */
    function initialize(
        FixedPriceSalePeriodAndFeeConfig calldata fixedPriceSalePeriodAndFeeConfig,
        FixedPriceSaleAddressConfig calldata fixedPriceSaleAddressConfig
    ) external initializer {
        /// Initialize fixed price sale period and fee configuration
        prefundPeriodSeconds = fixedPriceSalePeriodAndFeeConfig.prefundPeriodSeconds;
        prefundAllocationPeriodSeconds = fixedPriceSalePeriodAndFeeConfig.prefundAllocationPeriodSeconds;
        salePeriodSeconds = fixedPriceSalePeriodAndFeeConfig.salePeriodSeconds;
        refundPeriodSeconds = fixedPriceSalePeriodAndFeeConfig.refundPeriodSeconds;
        lockupPeriodSeconds = fixedPriceSalePeriodAndFeeConfig.lockupPeriodSeconds;
        vestingDurationSeconds = fixedPriceSalePeriodAndFeeConfig.vestingDurationSeconds;
        vestingCliffDurationSeconds = fixedPriceSalePeriodAndFeeConfig.vestingCliffDurationSeconds;
        legionFeeOnCapitalRaisedBps = fixedPriceSalePeriodAndFeeConfig.legionFeeOnCapitalRaisedBps;
        legionFeeOnTokensSoldBps = fixedPriceSalePeriodAndFeeConfig.legionFeeOnTokensSoldBps;
        minimumPledgeAmount = fixedPriceSalePeriodAndFeeConfig.minimumPledgeAmount;
        tokenPrice = fixedPriceSalePeriodAndFeeConfig.tokenPrice;

        /// Initialize fixed price sale address configuration
        bidToken = fixedPriceSaleAddressConfig.bidToken;
        askToken = fixedPriceSaleAddressConfig.askToken;
        projectAdmin = fixedPriceSaleAddressConfig.projectAdmin;
        legionAdmin = fixedPriceSaleAddressConfig.legionAdmin;
        legionSigner = fixedPriceSaleAddressConfig.legionSigner;
        vestingFactory = fixedPriceSaleAddressConfig.vestingFactory;

        /// Calculate and set prefundStartTime, prefundEndTime, startTime, endTime and refundEndTime
        prefundStartTime = block.timestamp;
        prefundEndTime = prefundStartTime + fixedPriceSalePeriodAndFeeConfig.prefundPeriodSeconds;
        startTime = prefundEndTime + fixedPriceSalePeriodAndFeeConfig.prefundAllocationPeriodSeconds;
        endTime = startTime + fixedPriceSalePeriodAndFeeConfig.salePeriodSeconds;
        refundEndTime = endTime + fixedPriceSalePeriodAndFeeConfig.refundPeriodSeconds;

        /// Check if lockupPeriodSeconds is less than refundPeriodSeconds
        /// lockupEndTime should be at least refundEndTime
        if (
            fixedPriceSalePeriodAndFeeConfig.lockupPeriodSeconds <= fixedPriceSalePeriodAndFeeConfig.refundPeriodSeconds
        ) {
            /// If yes, set lockupEndTime to be refundEndTime
            lockupEndTime = refundEndTime;
        } else {
            /// If no, calculate the lockupEndTime
            lockupEndTime = endTime + fixedPriceSalePeriodAndFeeConfig.lockupPeriodSeconds;
        }

        // Set the vestingStartTime to begin when lockupEndTime is reached
        vestingStartTime = lockupEndTime;

        /// Verify if the sale configuration is valid
        _verifyValidConfig(fixedPriceSalePeriodAndFeeConfig, fixedPriceSaleAddressConfig);
    }

    /**
     * @notice See {ILegionFixedPriceSale-pledgeCapital}.
     */
    function pledgeCapital(uint256 amount, bytes memory signature) external {
        /// Verify that the investor is allowed to pledge capital
        _verifyLegionSignature(signature);

        /// Verify that pledge is not during the prefund allocation period
        _verifyNotPrefundAllocationPeriod();

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

        /// Flag if capital is pledged during the prefund period
        bool isPrefund = _isPrefund();

        /// Emit successfully CapitalPledged
        emit CapitalPledged(amount, msg.sender, isPrefund, block.timestamp);

        /// Transfer the pledged capital to the contract
        IERC20(bidToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice See {ILegionFixedPriceSale-publishSaleResults}.
     */
    function publishSaleResults(bytes32 merkleRoot, uint256 tokensAllocated) external onlyLegion {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        /// Set the merkle root for claiming tokens
        claimTokensMerkleRoot = merkleRoot;

        /// Set the total tokens to be allocated by the Project team
        totalTokensAllocated = tokensAllocated;

        /// Set the total capital raised to be withdrawn by the project
        totalCapitalRaised = (tokensAllocated * tokenPrice) / (10 ** (ERC20(bidToken).decimals()));

        /// Emit successfully SaleResultsPublished
        emit SaleResultsPublished(merkleRoot, tokensAllocated);
    }

    /**
     * @notice See {ILegionFixedPriceSale-salePeriodAndFeeConfiguration}.
     */
    function salePeriodAndFeeConfiguration()
        external
        view
        returns (FixedPriceSalePeriodAndFeeConfig memory salePeriodAndFeeConfig)
    {
        /// Get the fixed price sale period and fee config
        salePeriodAndFeeConfig = FixedPriceSalePeriodAndFeeConfig(
            prefundPeriodSeconds,
            prefundAllocationPeriodSeconds,
            salePeriodSeconds,
            refundPeriodSeconds,
            lockupPeriodSeconds,
            vestingDurationSeconds,
            vestingCliffDurationSeconds,
            legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps,
            tokenPrice,
            minimumPledgeAmount
        );
    }

    /**
     * @notice See {ILegionFixedPriceSale-saleAddressConfiguration}.
     */
    function saleAddressConfiguration() external view returns (FixedPriceSaleAddressConfig memory saleAddressConfig) {
        /// Get the fixed price sale address config
        saleAddressConfig =
            FixedPriceSaleAddressConfig(bidToken, askToken, projectAdmin, legionAdmin, legionSigner, vestingFactory);
    }

    /**
     * @notice See {ILegionFixedPriceSale-saleStatus}.
     */
    function saleStatus() external view returns (FixedPriceSaleStatus memory fixedPriceSaleStatus) {
        /// Get the fixed price sale status
        fixedPriceSaleStatus = FixedPriceSaleStatus(
            prefundStartTime,
            prefundEndTime,
            startTime,
            endTime,
            refundEndTime,
            lockupEndTime,
            vestingStartTime,
            totalCapitalPledged,
            totalTokensAllocated,
            totalCapitalRaised,
            claimTokensMerkleRoot,
            excessCapitalMerkleRoot,
            isCanceled,
            tokensSupplied
        );
    }

    /**
     * @notice Verify if prefund period is active (before sale startTime).
     */
    function _isPrefund() private view returns (bool) {
        return (block.timestamp < prefundEndTime);
    }

    /**
     * @notice Verify if prefund allocation period is active (after prefundEndTime and before sale startTime).
     */
    function _verifyNotPrefundAllocationPeriod() private view {
        if (block.timestamp >= prefundEndTime && block.timestamp < startTime) revert PrefundAllocationPeriodNotEnded();
    }

    /**
     * @notice Verify if the sale configuration is valid.
     *
     * @param _fixedPriceSalePeriodAndFeeConfig The period and fee configuration for the fixed price sale.
     * @param _fixedPriceSaleAddressConfig The address configuration for the fixed price sale.
     */
    function _verifyValidConfig(
        FixedPriceSalePeriodAndFeeConfig calldata _fixedPriceSalePeriodAndFeeConfig,
        FixedPriceSaleAddressConfig calldata _fixedPriceSaleAddressConfig
    ) private pure {
        /// Check for zero addresses provided
        if (
            _fixedPriceSaleAddressConfig.bidToken == address(0)
                || _fixedPriceSaleAddressConfig.projectAdmin == address(0)
                || _fixedPriceSaleAddressConfig.legionAdmin == address(0)
                || _fixedPriceSaleAddressConfig.legionSigner == address(0)
                || _fixedPriceSaleAddressConfig.vestingFactory == address(0)
        ) revert ZeroAddressProvided();

        /// Check for zero values provided
        if (
            _fixedPriceSalePeriodAndFeeConfig.prefundPeriodSeconds == 0
                || _fixedPriceSalePeriodAndFeeConfig.prefundAllocationPeriodSeconds == 0
                || _fixedPriceSalePeriodAndFeeConfig.salePeriodSeconds == 0
                || _fixedPriceSalePeriodAndFeeConfig.refundPeriodSeconds == 0
                || _fixedPriceSalePeriodAndFeeConfig.lockupPeriodSeconds == 0
                || _fixedPriceSalePeriodAndFeeConfig.tokenPrice == 0
        ) revert ZeroValueProvided();

        /// Check if prefund, allocation, sale, refund and lockup periods are longer than allowed
        if (
            _fixedPriceSalePeriodAndFeeConfig.prefundPeriodSeconds > THREE_MONTHS
                || _fixedPriceSalePeriodAndFeeConfig.prefundAllocationPeriodSeconds > TWO_WEEKS
                || _fixedPriceSalePeriodAndFeeConfig.salePeriodSeconds > THREE_MONTHS
                || _fixedPriceSalePeriodAndFeeConfig.refundPeriodSeconds > TWO_WEEKS
                || _fixedPriceSalePeriodAndFeeConfig.lockupPeriodSeconds > SIX_MONTHS
        ) revert InvalidPeriodConfig();

        /// Check if prefund, allocation, sale, refund and lockup periods are shorter than allowed
        if (
            _fixedPriceSalePeriodAndFeeConfig.prefundPeriodSeconds < ONE_HOUR
                || _fixedPriceSalePeriodAndFeeConfig.prefundAllocationPeriodSeconds < ONE_HOUR
                || _fixedPriceSalePeriodAndFeeConfig.salePeriodSeconds < ONE_HOUR
                || _fixedPriceSalePeriodAndFeeConfig.refundPeriodSeconds < ONE_HOUR
                || _fixedPriceSalePeriodAndFeeConfig.lockupPeriodSeconds < ONE_HOUR
        ) revert InvalidPeriodConfig();
    }
}
