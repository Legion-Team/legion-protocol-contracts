# Errors
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/utils/Errors.sol)

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

### LegionSale__InvalidOpsFee
Thrown when an invalid operations fee amount is provided.


```solidity
error LegionSale__InvalidOpsFee(uint256 amount, uint256 expectedAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The operations fee amount provided.|
|`expectedAmount`|`uint256`|The expected operations fee amount.|

### LegionSale__InvalidPeriodConfig
Thrown when an invalid time period configuration is provided.

*Indicates periods (e.g., sale, refund) are outside allowed ranges.*


```solidity
error LegionSale__InvalidPeriodConfig();
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

### LegionSale__InvalidAmount
Thrown when an invalid withdrawal amount is requested.


```solidity
error LegionSale__InvalidAmount(uint256 amount);
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

### LegionSale__InvestorHasNotClaimedExcess
Thrown when an investor who has not claimed excess capital attempts an action requiring it.


```solidity
error LegionSale__InvestorHasNotClaimedExcess(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor who has not claimed excess.|

### LegionSale__InvestorHasRefunded
Thrown when an investor who has already refunded attempts another action.


```solidity
error LegionSale__InvestorHasRefunded(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the refunded investor.|

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

### LegionSale__SignatureExpired
Thrown when a signature has expired.


```solidity
error LegionSale__SignatureExpired(uint256 currentTimestamp, uint256 deadline);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentTimestamp`|`uint256`|The current block timestamp when the signature is used.|
|`deadline`|`uint256`|The deadline timestamp after which the signature is invalid.|

### LegionSale__TokensAlreadySupplied
Thrown when attempting to resupply tokens.


```solidity
error LegionSale__TokensAlreadySupplied();
```

### LegionSale__TokensNotSupplied
Thrown when an action requires supplied tokens first.


```solidity
error LegionSale__TokensNotSupplied();
```

### LegionSale__TransferReceiptTokensPaused
Thrown when transfer of receipt tokens is paused.


```solidity
error LegionSale__TransferReceiptTokensPaused();
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

