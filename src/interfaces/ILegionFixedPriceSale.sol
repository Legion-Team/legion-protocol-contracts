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
import {ILegionBaseSale} from "./ILegionBaseSale.sol";

interface ILegionFixedPriceSale is ILegionBaseSale {
    /**
     * @notice This event is emitted when capital is successfully pledged.
     *
     * @param amount The amount of capital pledged.
     * @param investor The address of the investor.
     * @param isPrefund Whether capital is pledged before sale start.
     * @param pledgeTimestamp The unix timestamp (seconds) of the block when capital has been pledged.
     */
    event CapitalPledged(uint256 amount, address investor, bool isPrefund, uint256 pledgeTimestamp);

    /**
     * @notice This event is emitted when sale results are successfully published by the Legion admin.
     *
     * @param merkleRoot The claim merkle root published.
     * @param tokensAllocated The amount of tokens allocated from the sale.
     */
    event SaleResultsPublished(bytes32 merkleRoot, uint256 tokensAllocated);

    /**
     * @notice Throws when capital is pledged during the prefund allocation period.
     */
    error PrefundAllocationPeriodNotEnded();

    /// @notice A struct describing the fixed price sale configuration.
    struct FixedPriceSaleConfig {
        /// @dev The prefund period duration in seconds.
        uint256 prefundPeriodSeconds;
        /// @dev The prefund allocation period duration in seconds.
        uint256 prefundAllocationPeriodSeconds;
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
        /// @dev The price of the token being sold denominated in the token used to raise capital.
        uint256 tokenPrice;
        /// @dev The address of the token used for raising capital.
        address bidToken;
        /// @dev The address of the token being sold to investors.
        address askToken;
        /// @dev The admin address of the project raising capital.
        address projectAdmin;
        /// @dev The address of Legion's Address Registry contract.
        address addressRegistry;
    }

    /// @notice A struct describing the fixed price sale status.
    struct FixedPriceSaleStatus {
        /// @dev The unix timestamp (seconds) of the block when the prefund starts.
        uint256 prefundStartTime;
        /// @dev The unix timestamp (seconds) of the block when the prefund ends.
        uint256 prefundEndTime;
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

    /**
     * @notice Initialized the contract with correct parameters.
     *
     * @param fixedPriceSaleConfig The configuration for the fixed price sale.
     */
    function initialize(FixedPriceSaleConfig calldata fixedPriceSaleConfig) external;

    /**
     * @notice Pledge capital to the fixed price sale.
     *
     * @param amount The amount of capital pledged.
     * @param signature The Legion signature for verification.
     */
    function pledgeCapital(uint256 amount, bytes memory signature) external;

    /**
     * @notice Publish merkle root for distribution of tokens, once the sale has concluded.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param merkleRoot The merkle root to verify against.
     * @param tokensAllocated The total amount of tokens allocated for distribution among investors.
     * @param askTokenDecimals The decimals number of the ask token.
     */
    function publishSaleResults(bytes32 merkleRoot, uint256 tokensAllocated, uint8 askTokenDecimals) external;

    /**
     * @notice Returns the configuration for the fixed price sale.
     */
    function saleConfiguration() external view returns (FixedPriceSaleConfig memory saleConfig);

    /**
     * @notice Returns the status for the fixed price sale.
     */
    function saleStatus() external view returns (FixedPriceSaleStatus memory fixedPriceSaleStatus);
}
