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

/**
 * @title Legion Errors Library
 * @author Legion
 * @notice A library defining custom errors shared across the Legion Protocol
 * @dev Provides reusable error types for consistent exception handling in contracts
 */
library Errors {
    /**
     * @notice Thrown when an investor attempts to settle tokens already settled
     * @dev Indicates the investor has already claimed their token allocation
     * @param investor Address of the investor attempting to claim
     */
    error AlreadySettled(address investor);

    /**
     * @notice Thrown when an investor tries to claim excess capital already claimed
     * @dev Indicates the investor has already withdrawn excess capital
     * @param investor Address of the investor attempting to claim excess
     */
    error AlreadyClaimedExcess(address investor);

    /**
     * @notice Thrown when the ask token is not available
     * @dev Indicates the ask token address is not set or invalid
     */
    error AskTokenUnavailable();

    /**
     * @notice Thrown when ask tokens have not been supplied by the project
     * @dev Indicates the project has not provided tokens for distribution
     */
    error AskTokensNotSupplied();

    /**
     * @notice Thrown when cancellation is locked
     * @dev Indicates cancellation is prevented, typically during result publication
     */
    error CancelLocked();

    /**
     * @notice Thrown when cancellation is not locked
     * @dev Indicates cancellation lock is required but not set
     */
    error CancelNotLocked();

    /**
     * @notice Thrown when attempting to release tokens before the cliff period ends
     * @dev Indicates the vesting cliff has not yet been reached
     * @param currentTimestamp Current block timestamp when the attempt was made
     */
    error CliffNotEnded(uint256 currentTimestamp);

    /**
     * @notice Thrown when capital has already been withdrawn by the project
     * @dev Indicates the project has already taken the raised capital
     */
    error CapitalAlreadyWithdrawn();

    /**
     * @notice Thrown when no capital has been raised
     * @dev Indicates no capital is available for withdrawal
     */
    error CapitalNotRaised();

    /**
     * @notice Thrown when an investor is not eligible to withdraw excess capital
     * @dev Indicates the investor is not flagged for excess capital return
     * @param investor Address of the investor attempting to withdraw
     * @param amount The amount of excess capital the investor is trying to withdraw
     */
    error CannotWithdrawExcessInvestedCapital(address investor, uint256 amount);

    /**
     * @notice Thrown when an invalid amount of tokens is supplied by the project
     * @dev Indicates the supplied token amount does not match allocation
     * @param amount Amount of tokens supplied
     * @param expectedAmount Expected token amount to be supplied
     */
    error InvalidTokenAmountSupplied(uint256 amount, uint256 expectedAmount);

    /**
     * @notice Thrown when the vesting configuration is invalid
     * @dev Indicates vesting parameters (e.g., duration, rate) are incorrect
     * @param vestingType Type of vesting schedule (linear or epoch-based)
     * @param vestingStartTimestamp Unix timestamp when vesting starts
     * @param vestingDurationSeconds Duration of the vesting schedule in seconds
     * @param vestingCliffDurationSeconds Duration of the cliff period in seconds
     * @param epochDurationSeconds Duration of each epoch in seconds
     * @param numberOfEpochs Total number of epochs in the vesting schedule
     * @param tokenAllocationOnTGERate Token allocation released at TGE (18 decimals precision)
     */
    error InvalidVestingConfig(
        uint8 vestingType,
        uint256 vestingStartTimestamp,
        uint256 vestingDurationSeconds,
        uint256 vestingCliffDurationSeconds,
        uint256 epochDurationSeconds,
        uint256 numberOfEpochs,
        uint256 tokenAllocationOnTGERate
    );

    /**
     * @notice Thrown when an invalid amount of tokens is requested for withdrawal
     * @dev Indicates the withdrawal amount is zero or otherwise invalid
     */
    error InvalidWithdrawAmount();

    /**
     * @notice Thrown when an invalid amount is requested for refund
     * @dev Indicates the refund amount is zero or exceeds invested capital
     */
    error InvalidRefundAmount();

    /**
     * @notice Thrown when an invalid fee amount is provided
     * @dev Indicates the fee does not match calculated expectations
     */
    error InvalidFeeAmount();

    /**
     * @notice Thrown when an invalid time period configuration is provided
     * @dev Indicates periods (e.g., sale, refund) are outside allowed ranges
     */
    error InvalidPeriodConfig();

    /**
     * @notice Thrown when an invalid investment amount is pledged
     * @dev Indicates the amount is below minimum or otherwise incorrect
     * @param amount Amount being pledged
     */
    error InvalidInvestAmount(uint256 amount);

    /**
     * @notice Thrown when an invalid signature is provided for investment
     * @dev Indicates the signature does not match the Legion signer
     * @param signature Signature provided by the investor
     */
    error InvalidSignature(bytes signature);

    /**
     * @notice Thrown when invested capital does not match the SAFT amount
     * @dev Indicates a discrepancy between invested and agreed amounts
     * @param investor Address of the investor with the mismatch
     */
    error InvalidPositionAmount(address investor);

    /**
     * @notice Thrown when an investor who has refunded attempts an action
     * @dev Indicates the investor has already received a refund
     * @param investor Address of the refunded investor
     */
    error InvestorHasRefunded(address investor);

    /**
     * @notice Thrown when an investor who has claimed excess capital attempts an action
     * @dev Indicates the investor has already withdrawn excess
     * @param investor Address of the investor who claimed excess
     */
    error InvestorHasClaimedExcess(address investor);

    /**
     * @notice Thrown when an invalid salt is used to encrypt a bid
     * @dev Indicates the salt does not match the expected value (e.g., investor address)
     */
    error InvalidSalt();

    /**
     * @notice Thrown when an invalid public key is used to encrypt a bid
     * @dev Indicates the public key is not valid or does not match the auction key
     */
    error InvalidBidPublicKey();

    /**
     * @notice Thrown when an invalid private key is provided to decrypt a bid
     * @dev Indicates the private key does not correspond to the public key
     */
    error InvalidBidPrivateKey();

    /**
     * @notice Thrown when an investor is not in the token claim whitelist
     * @dev Indicates the investor is not eligible to claim tokens
     * @param investor Address of the non-whitelisted investor
     */
    error NotInClaimWhitelist(address investor);

    /**
     * @notice Thrown when an investor has not invested any capital
     * @dev Indicates no capital is available for refund or withdrawal
     * @param investor Address of the investor with no investment
     */
    error NoCapitalInvested(address investor);

    /**
     * @notice Thrown when a function is not called by the Legion address
     * @dev Indicates unauthorized access by a non-Legion caller
     */
    error NotCalledByLegion();

    /**
     * @notice Thrown when a function is not called by the Project address
     * @dev Indicates unauthorized access by a non-Project caller
     */
    error NotCalledByProject();

    /**
     * @notice Thrown when a function is not called by Legion or Project
     * @dev Indicates unauthorized access by a non-authorized caller
     */
    error NotCalledByLegionOrProject();

    /**
     * @notice Thrown when the token claim amount is invalid
     * @dev Indicates the requested claim amount does not match expected values
     */
    error NothingToClaim();

    /**
     * @notice Thrown when capital is pledged during the pre-fund allocation period
     * @dev Indicates investment is attempted before the allowed period
     * @param timestamp The current timestamp when the investment is attempted
     */
    error PrefundAllocationPeriodNotEnded(uint256 timestamp);

    /**
     * @notice Thrown when the private key has already been published
     * @dev Indicates an attempt to set an already published private key
     */
    error PrivateKeyAlreadyPublished();

    /**
     * @notice Thrown when the private key has not been published
     * @dev Indicates decryption is attempted before key publication
     */
    error PrivateKeyNotPublished();

    /**
     * @notice Thrown when the refund period is not over
     * @dev Indicates an action is attempted before refunds are complete
     */
    error RefundPeriodIsNotOver();

    /**
     * @notice Thrown when the refund period is over
     * @dev Indicates an action (e.g., refund) is attempted after the period ends
     */
    error RefundPeriodIsOver();

    /**
     * @notice Thrown when the sale has ended
     * @dev Indicates an action is attempted after the sale period
     * @param timestamp The current timestamp when the action is attempted
     */
    error SaleHasEnded(uint256 timestamp);

    /**
     * @notice Thrown when the sale has not ended
     * @dev Indicates an action requires the sale to be completed first
     */
    error SaleHasNotEnded();

    /**
     * @notice Thrown when the sale is canceled
     * @dev Indicates an action is attempted on a canceled sale
     */
    error SaleIsCanceled();

    /**
     * @notice Thrown when the sale is not canceled
     * @dev Indicates an action requires the sale to be canceled first
     */
    error SaleIsNotCanceled();

    /**
     * @notice Thrown when sale results are not published
     * @dev Indicates an action requires published sale results
     */
    error SaleResultsNotPublished();

    /**
     * @notice Thrown when a signature has already been used
     * @dev Indicates a signature is reused, violating uniqueness
     * @param signature The signature that was previously used
     */
    error SignatureAlreadyUsed(bytes signature);

    /**
     * @notice Thrown when raised capital has not been published
     * @dev Indicates an action requires published capital data
     */
    error CapitalRaisedNotPublished();

    /**
     * @notice Thrown when sale results have already been published
     * @dev Indicates an attempt to republish sale results
     */
    error SaleResultsAlreadyPublished();

    /**
     * @notice Thrown when raised capital has already been published
     * @dev Indicates an attempt to republish capital raised data
     */
    error CapitalRaisedAlreadyPublished();

    /**
     * @notice Thrown when tokens have already been allocated
     * @dev Indicates an attempt to reallocate tokens
     */
    error TokensAlreadyAllocated();

    /**
     * @notice Thrown when tokens have not been allocated
     * @dev Indicates an action requires token allocation first
     */
    error TokensNotAllocated();

    /**
     * @notice Thrown when tokens have already been supplied
     * @dev Indicates an attempt to resupply tokens
     */
    error TokensAlreadySupplied();

    /**
     * @notice Thrown when tokens have not been supplied
     * @dev Indicates an action requires supplied tokens first
     */
    error TokensNotSupplied();

    /**
     * @notice Thrown when a zero address is provided
     * @dev Indicates an invalid address parameter (e.g., 0x0)
     */
    error ZeroAddressProvided();

    /**
     * @notice Thrown when a zero value is provided
     * @dev Indicates an invalid numeric parameter (e.g., 0)
     */
    error ZeroValueProvided();
}
