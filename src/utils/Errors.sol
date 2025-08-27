// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

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

/**
 * @title Legion Errors Library
 * @author Legion
 * @notice Defines custom errors shared across the Legion Protocol.
 * @dev Provides reusable error types for consistent exception handling throughout the protocol contracts.
 */
library Errors {
    /// @notice Thrown when an investor attempts to claim excess capital that was already claimed.
    /// @param investor The address of the investor attempting to claim excess.
    error LegionSale__AlreadyClaimedExcess(address investor);

    /// @notice Thrown when an investor attempts to settle tokens that are already settled.
    /// @param investor The address of the investor attempting to settle.
    error LegionSale__AlreadySettled(address investor);

    /// @notice Thrown when sale cancellation is locked.
    /// @dev Indicates cancellation is prevented, typically during result publication.
    error LegionSale__CancelLocked();

    /// @notice Thrown when sale cancellation is not locked but should be.
    /// @dev Indicates cancellation lock is required but not set.
    error LegionSale__CancelNotLocked();

    /// @notice Thrown when capital has already been withdrawn by the project.
    error LegionSale__CapitalAlreadyWithdrawn();

    /// @notice Thrown when no capital has been raised.
    /// @dev Indicates no capital is available for withdrawal.
    error LegionSale__CapitalNotRaised();

    /// @notice Thrown when capital raised data has already been published.
    error LegionSale__CapitalRaisedAlreadyPublished();

    /// @notice Thrown when capital raised data has not been published.
    /// @dev Indicates an action requires published capital data.
    error LegionSale__CapitalRaisedNotPublished();

    /// @notice Thrown when an investor is not eligible to withdraw excess invested capital.
    /// @param investor The address of the investor attempting to withdraw.
    /// @param amount The amount of excess capital the investor is trying to withdraw.
    error LegionSale__CannotWithdrawExcessInvestedCapital(address investor, uint256 amount);

    /// @notice Thrown when an invalid private key is provided for bid decryption.
    /// @dev Indicates the private key does not correspond to the public key.
    error LegionSale__InvalidBidPrivateKey();

    /// @notice Thrown when an invalid public key is used for bid encryption.
    /// @dev Indicates the public key is not valid or does not match the auction key.
    error LegionSale__InvalidBidPublicKey();

    /// @notice Thrown when an invalid fee amount is provided.
    /// @param amount The fee amount provided.
    /// @param expectedAmount The expected fee amount.
    error LegionSale__InvalidFeeAmount(uint256 amount, uint256 expectedAmount);

    /// @notice Thrown when an invalid investment amount is provided.
    /// @param amount The amount being invested.
    error LegionSale__InvalidInvestAmount(uint256 amount);

    /// @notice Thrown when an invalid time period configuration is provided.
    /// @dev Indicates periods (e.g., sale, refund) are outside allowed ranges.
    error LegionSale__InvalidPeriodConfig();

    /// @notice Thrown when invested capital does not match the SAFT amount.
    /// @param investor The address of the investor with the mismatch.
    error LegionSale__InvalidPositionAmount(address investor);

    /// @notice Thrown when an invalid salt is used for bid encryption.
    /// @dev Indicates the salt does not match the expected value (e.g., investor address).
    error LegionSale__InvalidSalt();

    /// @notice Thrown when an invalid signature is provided for investment.
    /// @param signature The signature provided by the investor.
    error LegionSale__InvalidSignature(bytes signature);

    /// @notice Thrown when an invalid amount of tokens is supplied by the project.
    /// @param amount The amount of tokens supplied.
    /// @param expectedAmount The expected token amount to be supplied.
    error LegionSale__InvalidTokenAmountSupplied(uint256 amount, uint256 expectedAmount);

    /// @notice Thrown when an invalid withdrawal amount is requested.
    /// @param amount The amount of tokens requested for withdrawal.
    error LegionSale__InvalidWithdrawAmount(uint256 amount);

    /// @notice Thrown when an invalid Merkle proof is provided for referrer fee claims.
    error LegionSale__InvalidMerkleProof();

    /// @notice Thrown when an investor who has already claimed excess capital attempts another action.
    /// @param investor The address of the investor who claimed excess.
    error LegionSale__InvestorHasClaimedExcess(address investor);

    /// @notice Thrown when an investor who has already refunded attempts another action.
    /// @param investor The address of the refunded investor.
    error LegionSale__InvestorHasRefunded(address investor);

    /// @notice Thrown when attempting to transfer a position that has been refunded or settled.
    /// @param positionId The ID of the position that cannot be transferred.
    error LegionSale__UnableToTransferInvestorPosition(uint256 positionId);

    /// @notice Thrown when attempting to merge an investor position that has been refunded or settled.
    /// @param positionId The ID of the position that cannot be merged.
    error LegionSale__UnableToMergeInvestorPosition(uint256 positionId);

    /// @notice Thrown when a function is not called by the Legion address.
    error LegionSale__NotCalledByLegion();

    /// @notice Thrown when a function is not called by Legion or project admin.
    error LegionSale__NotCalledByLegionOrProject();

    /// @notice Thrown when a function is not called by the project admin.
    error LegionSale__NotCalledByProject();

    /// @notice Thrown when a function is not called by the vesting controller.
    error LegionSale__NotCalledByVestingController();

    /// @notice Thrown when an investor is not in the token claim whitelist.
    /// @param investor The address of the non-whitelisted investor.
    error LegionSale__NotInClaimWhitelist(address investor);

    /// @notice Thrown when attempting to access a non-existent investor position.
    error LegionSale__InvestorPositionDoesNotExist();

    /// @notice Thrown when investment is attempted during the prefund allocation period.
    /// @param timestamp The current timestamp when the investment is attempted.
    error LegionSale__PrefundAllocationPeriodNotEnded(uint256 timestamp);

    /// @notice Thrown when the private key has already been published.
    error LegionSale__PrivateKeyAlreadyPublished();

    /// @notice Thrown when attempting decryption before the private key is published.
    error LegionSale__PrivateKeyNotPublished();

    /// @notice Thrown when an action is attempted before the refund period ends.
    /// @param currentTimestamp The current timestamp when the action is attempted.
    /// @param refundEndTimestamp The timestamp when the refund period ends.
    error LegionSale__RefundPeriodIsNotOver(uint256 currentTimestamp, uint256 refundEndTimestamp);

    /// @notice Thrown when a refund is attempted after the refund period ends.
    /// @param currentTimestamp The current timestamp when the action is attempted.
    /// @param refundEndTimestamp The timestamp when the refund period ends.
    error LegionSale__RefundPeriodIsOver(uint256 currentTimestamp, uint256 refundEndTimestamp);

    /// @notice Thrown when an action is attempted after the sale has ended.
    /// @param timestamp The current timestamp when the action is attempted.
    error LegionSale__SaleHasEnded(uint256 timestamp);

    /// @notice Thrown when an action requires the sale to be completed first.
    /// @param timestamp The current timestamp when the action is attempted.
    error LegionSale__SaleHasNotEnded(uint256 timestamp);

    /// @notice Thrown when an action is attempted on a canceled sale.
    error LegionSale__SaleIsCanceled();

    /// @notice Thrown when an action requires the sale to be canceled first.
    error LegionSale__SaleIsNotCanceled();

    /// @notice Thrown when attempting to republish sale results.
    error LegionSale__SaleResultsAlreadyPublished();

    /// @notice Thrown when an action requires published sale results.
    error LegionSale__SaleResultsNotPublished();

    /// @notice Thrown when a signature is reused.
    /// @param signature The signature that was previously used.
    error LegionSale__SignatureAlreadyUsed(bytes signature);

    /// @notice Thrown when attempting to reallocate tokens.
    error LegionSale__TokensAlreadyAllocated();

    /// @notice Thrown when attempting to resupply tokens.
    error LegionSale__TokensAlreadySupplied();

    /// @notice Thrown when an action requires token allocation first.
    error LegionSale__TokensNotAllocated();

    /// @notice Thrown when an action requires supplied tokens first.
    error LegionSale__TokensNotSupplied();

    /// @notice Thrown when a zero address is provided as a parameter.
    error LegionSale__ZeroAddressProvided();

    /// @notice Thrown when a zero value is provided as a parameter.
    error LegionSale__ZeroValueProvided();

    /// @notice Thrown when attempting to release tokens before the cliff period ends.
    /// @param currentTimestamp The current block timestamp when the attempt was made.
    error LegionVesting__CliffNotEnded(uint256 currentTimestamp);

    /// @notice Thrown when a token different from the expected ask token is released.
    error LegionVesting__OnlyAskTokenReleasable();

    /// @notice Thrown when the vesting configuration parameters are invalid.
    /// @param vestingType The type of vesting schedule (linear or epoch-based).
    /// @param vestingStartTimestamp The Unix timestamp when vesting starts.
    /// @param vestingDurationSeconds The duration of the vesting schedule in seconds.
    /// @param vestingCliffDurationSeconds The duration of the cliff period in seconds.
    /// @param epochDurationSeconds The duration of each epoch in seconds.
    /// @param numberOfEpochs The total number of epochs in the vesting schedule.
    /// @param tokenAllocationOnTGERate The token allocation released at TGE (18 decimal precision).
    error LegionVesting__InvalidVestingConfig(
        uint8 vestingType,
        uint256 vestingStartTimestamp,
        uint256 vestingDurationSeconds,
        uint256 vestingCliffDurationSeconds,
        uint256 epochDurationSeconds,
        uint256 numberOfEpochs,
        uint256 tokenAllocationOnTGERate
    );
}
