# Errors
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/utils/Errors.sol)

**Author:**
Legion

Defines custom errors shared across the Legion Protocol.

*Provides reusable error types for consistent exception handling throughout the protocol contracts.*


## Errors
### LegionSale__AlreadyClaimedExcess
Thrown when an investor attempts to claim excess capital that was already claimed.


```solidity
error LegionSale__AlreadyClaimedExcess(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor attempting to claim excess.|

### LegionSale__AlreadySettled
Thrown when an investor attempts to settle tokens that are already settled.


```solidity
error LegionSale__AlreadySettled(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor attempting to settle.|

### LegionSale__CancelLocked
Thrown when sale cancellation is locked.

*Indicates cancellation is prevented, typically during result publication.*


```solidity
error LegionSale__CancelLocked();
```

### LegionSale__CancelNotLocked
Thrown when sale cancellation is not locked but should be.

*Indicates cancellation lock is required but not set.*


```solidity
error LegionSale__CancelNotLocked();
```

### LegionSale__CapitalAlreadyWithdrawn
Thrown when capital has already been withdrawn by the project.


```solidity
error LegionSale__CapitalAlreadyWithdrawn();
```

### LegionSale__CapitalNotRaised
Thrown when no capital has been raised.

*Indicates no capital is available for withdrawal.*


```solidity
error LegionSale__CapitalNotRaised();
```

### LegionSale__CapitalRaisedAlreadyPublished
Thrown when capital raised data has already been published.


```solidity
error LegionSale__CapitalRaisedAlreadyPublished();
```

### LegionSale__CapitalRaisedNotPublished
Thrown when capital raised data has not been published.

*Indicates an action requires published capital data.*


```solidity
error LegionSale__CapitalRaisedNotPublished();
```

### LegionSale__CannotWithdrawExcessInvestedCapital
Thrown when an investor is not eligible to withdraw excess invested capital.


```solidity
error LegionSale__CannotWithdrawExcessInvestedCapital(address investor, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor attempting to withdraw.|
|`amount`|`uint256`|The amount of excess capital the investor is trying to withdraw.|

### LegionSale__InvalidBidPrivateKey
Thrown when an invalid private key is provided for bid decryption.

*Indicates the private key does not correspond to the public key.*


```solidity
error LegionSale__InvalidBidPrivateKey();
```

### LegionSale__InvalidBidPublicKey
Thrown when an invalid public key is used for bid encryption.

*Indicates the public key is not valid or does not match the auction key.*


```solidity
error LegionSale__InvalidBidPublicKey();
```

### LegionSale__InvalidFeeAmount
Thrown when an invalid fee amount is provided.


```solidity
error LegionSale__InvalidFeeAmount(uint256 amount, uint256 expectedAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The fee amount provided.|
|`expectedAmount`|`uint256`|The expected fee amount.|

### LegionSale__InvalidInvestAmount
Thrown when an invalid investment amount is provided.


```solidity
error LegionSale__InvalidInvestAmount(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount being invested.|

### LegionSale__InvalidPeriodConfig
Thrown when an invalid time period configuration is provided.

*Indicates periods (e.g., sale, refund) are outside allowed ranges.*


```solidity
error LegionSale__InvalidPeriodConfig();
```

### LegionSale__InvalidPositionAmount
Thrown when invested capital does not match the SAFT amount.


```solidity
error LegionSale__InvalidPositionAmount(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor with the mismatch.|

### LegionSale__InvalidSalt
Thrown when an invalid salt is used for bid encryption.

*Indicates the salt does not match the expected value (e.g., investor address).*


```solidity
error LegionSale__InvalidSalt();
```

### LegionSale__InvalidSignature
Thrown when an invalid signature is provided for investment.


```solidity
error LegionSale__InvalidSignature(bytes signature);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signature`|`bytes`|The signature provided by the investor.|

### LegionSale__InvalidTokenAmountSupplied
Thrown when an invalid amount of tokens is supplied by the project.


```solidity
error LegionSale__InvalidTokenAmountSupplied(uint256 amount, uint256 expectedAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens supplied.|
|`expectedAmount`|`uint256`|The expected token amount to be supplied.|

### LegionSale__InvalidWithdrawAmount
Thrown when an invalid withdrawal amount is requested.


```solidity
error LegionSale__InvalidWithdrawAmount(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens requested for withdrawal.|

### LegionSale__InvalidMerkleProof
Thrown when an invalid Merkle proof is provided for referrer fee claims.


```solidity
error LegionSale__InvalidMerkleProof();
```

### LegionSale__InvestorHasClaimedExcess
Thrown when an investor who has already claimed excess capital attempts another action.


```solidity
error LegionSale__InvestorHasClaimedExcess(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor who claimed excess.|

### LegionSale__InvestorHasRefunded
Thrown when an investor who has already refunded attempts another action.


```solidity
error LegionSale__InvestorHasRefunded(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the refunded investor.|

### LegionSale__UnableToTransferInvestorPosition
Thrown when attempting to transfer a position that has been refunded or settled.


```solidity
error LegionSale__UnableToTransferInvestorPosition(uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`positionId`|`uint256`|The ID of the position that cannot be transferred.|

### LegionSale__UnableToMergeInvestorPosition
Thrown when attempting to merge an investor position that has been refunded or settled.


```solidity
error LegionSale__UnableToMergeInvestorPosition(uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`positionId`|`uint256`|The ID of the position that cannot be merged.|

### LegionSale__NotCalledByLegion
Thrown when a function is not called by the Legion address.


```solidity
error LegionSale__NotCalledByLegion();
```

### LegionSale__NotCalledByLegionOrProject
Thrown when a function is not called by Legion or project admin.


```solidity
error LegionSale__NotCalledByLegionOrProject();
```

### LegionSale__NotCalledByProject
Thrown when a function is not called by the project admin.


```solidity
error LegionSale__NotCalledByProject();
```

### LegionSale__NotCalledByVestingController
Thrown when a function is not called by the vesting controller.


```solidity
error LegionSale__NotCalledByVestingController();
```

### LegionSale__NotInClaimWhitelist
Thrown when an investor is not in the token claim whitelist.


```solidity
error LegionSale__NotInClaimWhitelist(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the non-whitelisted investor.|

### LegionSale__InvestorPositionDoesNotExist
Thrown when attempting to access a non-existent investor position.


```solidity
error LegionSale__InvestorPositionDoesNotExist();
```

### LegionSale__PrefundAllocationPeriodNotEnded
Thrown when investment is attempted during the prefund allocation period.


```solidity
error LegionSale__PrefundAllocationPeriodNotEnded(uint256 timestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|The current timestamp when the investment is attempted.|

### LegionSale__PrivateKeyAlreadyPublished
Thrown when the private key has already been published.


```solidity
error LegionSale__PrivateKeyAlreadyPublished();
```

### LegionSale__PrivateKeyNotPublished
Thrown when attempting decryption before the private key is published.


```solidity
error LegionSale__PrivateKeyNotPublished();
```

### LegionSale__RefundPeriodIsNotOver
Thrown when an action is attempted before the refund period ends.


```solidity
error LegionSale__RefundPeriodIsNotOver(uint256 currentTimestamp, uint256 refundEndTimestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentTimestamp`|`uint256`|The current timestamp when the action is attempted.|
|`refundEndTimestamp`|`uint256`|The timestamp when the refund period ends.|

### LegionSale__RefundPeriodIsOver
Thrown when a refund is attempted after the refund period ends.


```solidity
error LegionSale__RefundPeriodIsOver(uint256 currentTimestamp, uint256 refundEndTimestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentTimestamp`|`uint256`|The current timestamp when the action is attempted.|
|`refundEndTimestamp`|`uint256`|The timestamp when the refund period ends.|

### LegionSale__SaleHasEnded
Thrown when an action is attempted after the sale has ended.


```solidity
error LegionSale__SaleHasEnded(uint256 timestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|The current timestamp when the action is attempted.|

### LegionSale__SaleHasNotEnded
Thrown when an action requires the sale to be completed first.


```solidity
error LegionSale__SaleHasNotEnded(uint256 timestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|The current timestamp when the action is attempted.|

### LegionSale__SaleIsCanceled
Thrown when an action is attempted on a canceled sale.


```solidity
error LegionSale__SaleIsCanceled();
```

### LegionSale__SaleIsNotCanceled
Thrown when an action requires the sale to be canceled first.


```solidity
error LegionSale__SaleIsNotCanceled();
```

### LegionSale__SaleResultsAlreadyPublished
Thrown when attempting to republish sale results.


```solidity
error LegionSale__SaleResultsAlreadyPublished();
```

### LegionSale__SaleResultsNotPublished
Thrown when an action requires published sale results.


```solidity
error LegionSale__SaleResultsNotPublished();
```

### LegionSale__SignatureAlreadyUsed
Thrown when a signature is reused.


```solidity
error LegionSale__SignatureAlreadyUsed(bytes signature);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signature`|`bytes`|The signature that was previously used.|

### LegionSale__TokensAlreadyAllocated
Thrown when attempting to reallocate tokens.


```solidity
error LegionSale__TokensAlreadyAllocated();
```

### LegionSale__TokensAlreadySupplied
Thrown when attempting to resupply tokens.


```solidity
error LegionSale__TokensAlreadySupplied();
```

### LegionSale__TokensNotAllocated
Thrown when an action requires token allocation first.


```solidity
error LegionSale__TokensNotAllocated();
```

### LegionSale__TokensNotSupplied
Thrown when an action requires supplied tokens first.


```solidity
error LegionSale__TokensNotSupplied();
```

### LegionSale__ZeroAddressProvided
Thrown when a zero address is provided as a parameter.


```solidity
error LegionSale__ZeroAddressProvided();
```

### LegionSale__ZeroValueProvided
Thrown when a zero value is provided as a parameter.


```solidity
error LegionSale__ZeroValueProvided();
```

### LegionVesting__CliffNotEnded
Thrown when attempting to release tokens before the cliff period ends.


```solidity
error LegionVesting__CliffNotEnded(uint256 currentTimestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentTimestamp`|`uint256`|The current block timestamp when the attempt was made.|

### LegionVesting__OnlyAskTokenReleasable
Thrown when a token different from the expected ask token is released.


```solidity
error LegionVesting__OnlyAskTokenReleasable();
```

### LegionVesting__InvalidVestingConfig
Thrown when the vesting configuration parameters are invalid.


```solidity
error LegionVesting__InvalidVestingConfig(
    uint8 vestingType,
    uint256 vestingStartTimestamp,
    uint256 vestingDurationSeconds,
    uint256 vestingCliffDurationSeconds,
    uint256 epochDurationSeconds,
    uint256 numberOfEpochs,
    uint256 tokenAllocationOnTGERate
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vestingType`|`uint8`|The type of vesting schedule (linear or epoch-based).|
|`vestingStartTimestamp`|`uint256`|The Unix timestamp when vesting starts.|
|`vestingDurationSeconds`|`uint256`|The duration of the vesting schedule in seconds.|
|`vestingCliffDurationSeconds`|`uint256`|The duration of the cliff period in seconds.|
|`epochDurationSeconds`|`uint256`|The duration of each epoch in seconds.|
|`numberOfEpochs`|`uint256`|The total number of epochs in the vesting schedule.|
|`tokenAllocationOnTGERate`|`uint256`|The token allocation released at TGE (18 decimal precision).|

