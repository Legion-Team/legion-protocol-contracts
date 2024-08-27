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
interface ILegionBaseSale {
    /**
     * @notice This event is emitted when capital is successfully withdrawn by the project owner.
     *
     * @param amountToWithdraw The amount of capital withdrawn.
     * @param projectOwner The address of the project owner.
     */
    event CapitalWithdrawn(uint256 amountToWithdraw, address projectOwner);

    /**
     * @notice This event is emitted when capital is successfully refunded to the investor.
     *
     * @param amount The amount of capital refunded to the investor.
     * @param investor The address of the investor who requested the refund.
     */
    event CapitalRefunded(uint256 amount, address investor);

    /**
     * @notice This event is emitted when capital is successfully refunded to the investor after a sale has been canceled.
     *
     * @param amount The amount of capital refunded to the investor.
     * @param investor The address of the investor who requested the refund.
     */
    event CapitalRefundedAfterCancel(uint256 amount, address investor);

    /**
     * @notice This event is emitted when excess capital is successfully claimed by the investor after a sale has ended.
     *
     * @param amount The amount of capital refunded to the investor.
     * @param investor The address of the investor who requested the refund.
     */
    event ExcessCapitalClaimed(uint256 amount, address investor);

    /**
     * @notice This event is emitted when excess capital results are successfully published by the Legion admin.
     *
     * @param merkleRoot The claim merkle root published.
     */
    event ExcessCapitalResultsPublished(bytes32 merkleRoot);

    /**
     * @notice This event is emitted when excess capital results are successfully published by the Legion admin.
     *
     * @param receiver The address of the receiver.
     * @param token The address of the token to be withdrawn.
     * @param amount The amount to be withdrawn.
     */
    event EmergencyWithdraw(address receiver, address token, uint256 amount);

    /**
     * @notice This event is emitted when a sale is successfully canceled.
     */
    event SaleCanceled();

    /**
     * @notice This event is emitted when tokens are successfully supplied for distribution by the project admin.
     *
     * @param amount The amount of tokens supplied for distribution.
     * @param legionFee The fee amount collected by Legion.
     */
    event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee);

    /**
     * @notice This event is emitted when tokens are successfully claimed by the investor.
     *
     * @param amount The amount of tokens distributed to the vesting contract.
     * @param investor The address of the investor owning the vesting contract.
     * @param vesting The address of the vesting instance deployed.
     */
    event TokenAllocationClaimed(uint256 amount, address investor, address vesting);

    /**
     * @notice Throws when tokens already settled by investor.
     *
     * @param investor The address of the investor trying to claim.
     */
    error AlreadySettled(address investor);

    /**
     * @notice Throws when excess capital has already been claimed by investor.
     *
     * @param investor The address of the investor trying to get excess capital back.
     */
    error AlreadyClaimedExcess(address investor);

    /**
     * @notice Throws when the excess capital results have already been published.
     *
     * @param merkleRoot The merkle root for distribution of excess capital.
     */
    error ExcessCapitalResultsAlreadyPublished(bytes32 merkleRoot);

    /**
     * @notice Throws when an invalid amount of tokens has been supplied by the project.
     *
     * @param amount The amount of tokens supplied.
     */
    error InvalidTokenAmountSupplied(uint256 amount);

    /**
     * @notice Throws when an invalid amount of tokens has been claimed.
     */
    error InvalidClaimAmount();

    /**
     * @notice Throws when an invalid amount has been requested for refund.
     */
    error InvalidRefundAmount();

    /**
     * @notice Throws when an invalid amount has been requested for fee.
     */
    error InvalidFeeAmount();

    /**
     * @notice Throws when an invalid time config has been provided.
     */
    error InvalidPeriodConfig();

    /**
     * @notice Throws when an invalid pledge amount has been sent.
     *
     * @param amount The amount being pledged.
     */
    error InvalidPledgeAmount(uint256 amount);

    /**
     * @notice Throws when an invalid signature has been provided when pledging capital.
     *
     */
    error InvalidSignature();

    /**
     * @notice Throws when the lockup period is not over.
     */
    error LockupPeriodIsNotOver();

    /**
     * @notice Throws when the investor is not in the claim whitelist for tokens.
     *
     * @param investor The address of the investor.
     */
    error NotInClaimWhitelist(address investor);

    /**
     * @notice Throws when the investor is not flagged to have excess capital returned.
     *
     * @param investor The address of the investor.
     */
    error CannotClaimExcessCapital(address investor);

    /**
     * @notice Throws when no capital has been pledged by an investor.
     *
     * @param investor The address of the investor.
     */
    error NoCapitalPledged(address investor);

    /**
     * @notice Throws when not called by Legion.
     */
    error NotCalledByLegion();

    /**
     * @notice Throws when not called by the Project.
     */
    error NotCalledByProject();

    /**
     * @notice Throws when the `askToken` is unavailable.
     */
    error AskTokenUnavailable();

    /**
     * @notice Throws when the refund period is not over.
     */
    error RefundPeriodIsNotOver();

    /**
     * @notice Throws when the refund period is over.
     */
    error RefundPeriodIsOver();

    /**
     * @notice Throws when the sale has ended.
     */
    error SaleHasEnded();

    /**
     * @notice Throws when the sale has not ended.
     */
    error SaleHasNotEnded();

    /**
     * @notice Throws when the sale is canceled.
     */
    error SaleIsCanceled();

    /**
     * @notice Throws when the sale is not canceled.
     */
    error SaleIsNotCanceled();

    /**
     * @notice Throws when the sale results are not published.
     */
    error SaleResultsNotPublished();

    /**
     * @notice Throws when the sale results have been already published.
     */
    error SaleResultsAlreadyPublished();

    /**
     * @notice Throws when the tokens have already been allocated.
     * @param totalTokensAllocated The total amount of tokens allocated.
     */
    error TokensAlreadyAllocated(uint256 totalTokensAllocated);

    /**
     * @notice Throws when tokens have not been allocated.
     */
    error TokensNotAllocated();

    /**
     * @notice Throws when tokens have already been supplied.
     */
    error TokensAlreadySupplied();

    /**
     * @notice Throws when tokens have not been supplied.
     */
    error TokensNotSupplied();

    /**
     * @notice Throws when zero address has been provided.
     */
    error ZeroAddressProvided();

    /**
     * @notice Throws when zero value has been provided.
     */
    error ZeroValueProvided();

    /// @notice A struct describing the investor position during the sale.
    struct InvestorPosition {
        /// @dev The total amount of capital pledged by the investor.
        uint256 pledgedCapital;
        /// @dev Flag if the investor has claimed the tokens allocated to them.
        bool hasSettled;
        /// @dev Flag if the investor has claimed the excess capital pledged.
        bool hasClaimedExcess;
        /// @dev The address of the investor's vesting contract.
        address vestingAddress;
    }

    /**
     * @notice Request a refund from the sale during the applicable time window.
     */
    function requestRefund() external;

    /**
     * @notice Withdraw capital from the sale contract.
     *
     * @dev Can be called only by the Project admin address.
     */
    function withdrawCapital() external;

    /**
     * @notice Claims the investor token allocation.
     *
     * @param amount The amount to be distributed.
     * @param proof The merkle proof verification for claiming.
     */
    function claimTokenAllocation(uint256 amount, bytes32[] calldata proof) external;

    /**
     * @notice Claim excess capital back to the investor.
     *
     * @param amount The amount to be returned.
     * @param proof The merkle proof verification for the return.
     */
    function claimExcessCapital(uint256 amount, bytes32[] calldata proof) external;

    /**
     * @notice Releases tokens to the investor address.
     */
    function releaseTokens() external;

    /**
     * @notice Supply tokens once the sale results have been published.
     *
     * @dev Can be called only by the Project admin address.
     *
     * @param amount The token amount supplied by the project.
     * @param legionFee The token amount supplied by the project.
     */
    function supplyTokens(uint256 amount, uint256 legionFee) external;

    /**
     * @notice Publish merkle root for distribution of excess capital, once the sale has concluded.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param merkleRoot The merkle root to verify against.
     */
    function publishExcessCapitalResults(bytes32 merkleRoot) external;

    /**
     * @notice Cancels an ongoing sale.
     *
     * @dev Can be called only by the Project admin address.
     */
    function cancelSale() external;

    /**
     * @notice Cancels a sale in case the project has not supplied tokens after the lockup period is over.
     */
    function cancelExpiredSale() external;

    /**
     * @notice Claims back capital in case the sale has been canceled.
     */
    function claimBackCapitalIfCanceled() external;

    /**
     * @notice Withdraw tokens from the contract in case of emergency.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param receiver The address of the receiver.
     * @param token The address of the token to be withdrawn.
     * @param amount The amount to be withdrawn.
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external;
}
