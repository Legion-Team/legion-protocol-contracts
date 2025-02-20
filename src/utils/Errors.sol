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

/**
 * @title Legion Errors Library
 * @author Legion
 * @notice A library used for storing errors shared across the Legion protocol
 */
library Errors {
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
     * @notice Throws when the `askToken` is unavailable.
     */
    error AskTokenUnavailable();

    /**
     * @notice Throws when the ask tokens have not been supplied by the project.
     */
    error AskTokensNotSupplied();

    /**
     * @notice Throws when canceling is locked.
     */
    error CancelLocked();

    /**
     * @notice Throws when canceling is not locked.
     */
    error CancelNotLocked();

    /**
     * @notice Throws when an user tries to release tokens before the cliff period has ended.
     *
     * @param currentTimestamp The current block timestamp.
     */
    error CliffNotEnded(uint256 currentTimestamp);

    /**
     * @notice Throws when capital has already been withdrawn by the Project.
     */
    error CapitalAlreadyWithdrawn();

    /**
     * @notice Throws when the investor is not flagged to have excess capital returned.
     *
     * @param investor The address of the investor.
     */
    error CannotWithdrawExcessInvestedCapital(address investor);

    /**
     * @notice Throws when the claim amount is invalid.
     */
    error InvalidClaimAmount();

    /**
     * @notice Throws when an invalid amount of tokens has been supplied by the project.
     *
     * @param amount The amount of tokens supplied.
     */
    error InvalidTokenAmountSupplied(uint256 amount);

    /**
     * @notice Throws when the vesting configuration is invalid.
     */
    error InvalidVestingConfig();

    /**
     * @notice Throws when an invalid amount of tokens has been claimed.
     */
    error InvalidWithdrawAmount();

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
    error InvalidInvestAmount(uint256 amount);

    /**
     * @notice Throws when an invalid signature has been provided when pledging capital.
     *
     */
    error InvalidSignature();

    /**
     * @notice Throws when the invested capital amount is not equal to the SAFT amount.
     *
     * @param investor The address of the investor.
     */
    error InvalidPositionAmount(address investor);

    /**
     * @notice Throws when the investor has refunded.
     *
     * @param investor The address of the investor.
     */
    error InvestorHasRefunded(address investor);

    /**
     * @notice Throws when the salt used to encrypt the bid is invalid.
     */
    error InvalidSalt();

    /**
     * @notice Throws when an invalid bid public key is used to encrypt a bid.
     */
    error InvalidBidPublicKey();

    /**
     * @notice Throws when an invalid bid private key is provided to decrypt a bid.
     */
    error InvalidBidPrivateKey();

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
     * @notice Throws when no capital has been pledged by an investor.
     *
     * @param investor The address of the investor.
     */
    error NoCapitalInvested(address investor);

    /**
     * @notice Throws when not called by Legion.
     */
    error NotCalledByLegion();

    /**
     * @notice Throws when not called by the Project.
     */
    error NotCalledByProject();

    /**
     * @notice Throws when not called by Legion or the Project.
     */
    error NotCalledByLegionOrProject();

    /**
     * @notice Throws when capital is pledged during the pre-fund allocation period.
     */
    error PrefundAllocationPeriodNotEnded();

    /**
     * @notice Throws when the Project has withdrawn capital.
     */
    error ProjectHasWithdrawnCapital();

    /**
     * @notice Throws when the private key has already been published by Legion.
     */
    error PrivateKeyAlreadyPublished();

    /**
     * @notice Throws when the private key has not been published by Legion.
     */
    error PrivateKeyNotPublished();

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
     * @notice Throws when the signature has already been used.
     *
     * @param signature The signature that has been used.
     */
    error SignatureAlreadyUsed(bytes signature);

    /**
     * @notice Throws when the raised capital has not published.
     */
    error CapitalRaisedNotPublished();

    /**
     * @notice Throws when the sale results have been already published.
     */
    error SaleResultsAlreadyPublished();

    /**
     * @notice Throws when the raised capital have been already published.
     */
    error CapitalRaisedAlreadyPublished();

    /**
     * @notice Throws when the tokens have already been allocated.
     */
    error TokensAlreadyAllocated();

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
}
