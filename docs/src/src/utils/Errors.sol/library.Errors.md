# Errors
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/utils/Errors.sol)

**Author:**
Legion

A library used for storing errors shared across the Legion protocol


## Errors
### AlreadySettled
Throws when tokens already settled by investor.


```solidity
error AlreadySettled(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor trying to claim.|

### AlreadyClaimedExcess
Throws when excess capital has already been claimed by investor.


```solidity
error AlreadyClaimedExcess(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor trying to get excess capital back.|

### AskTokenUnavailable
Throws when the `askToken` is unavailable.


```solidity
error AskTokenUnavailable();
```

### AskTokensNotSupplied
Throws when the ask tokens have not been supplied by the project.


```solidity
error AskTokensNotSupplied();
```

### CancelLocked
Throws when canceling is locked.


```solidity
error CancelLocked();
```

### CancelNotLocked
Throws when canceling is not locked.


```solidity
error CancelNotLocked();
```

### CliffNotEnded
Throws when an user tries to release tokens before the cliff period has ended.


```solidity
error CliffNotEnded(uint256 currentTimestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentTimestamp`|`uint256`|The current block timestamp.|

### CapitalAlreadyWithdrawn
Throws when capital has already been withdrawn by the Project.


```solidity
error CapitalAlreadyWithdrawn();
```

### CapitalNotRaised
Throws when no capital has been raised.


```solidity
error CapitalNotRaised();
```

### CannotWithdrawExcessInvestedCapital
Throws when the investor is not flagged to have excess capital returned.


```solidity
error CannotWithdrawExcessInvestedCapital(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

### InvalidClaimAmount
Throws when the claim amount is invalid.


```solidity
error InvalidClaimAmount();
```

### InvalidTokenAmountSupplied
Throws when an invalid amount of tokens has been supplied by the project.


```solidity
error InvalidTokenAmountSupplied(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens supplied.|

### InvalidVestingConfig
Throws when the vesting configuration is invalid.


```solidity
error InvalidVestingConfig();
```

### InvalidWithdrawAmount
Throws when an invalid amount of tokens has been claimed.


```solidity
error InvalidWithdrawAmount();
```

### InvalidRefundAmount
Throws when an invalid amount has been requested for refund.


```solidity
error InvalidRefundAmount();
```

### InvalidFeeAmount
Throws when an invalid amount has been requested for fee.


```solidity
error InvalidFeeAmount();
```

### InvalidPeriodConfig
Throws when an invalid time config has been provided.


```solidity
error InvalidPeriodConfig();
```

### InvalidInvestAmount
Throws when an invalid pledge amount has been sent.


```solidity
error InvalidInvestAmount(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount being pledged.|

### InvalidSignature
Throws when an invalid signature has been provided when pledging capital.


```solidity
error InvalidSignature();
```

### InvalidPositionAmount
Throws when the invested capital amount is not equal to the SAFT amount.


```solidity
error InvalidPositionAmount(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

### InvestorHasRefunded
Throws when the investor has refunded.


```solidity
error InvestorHasRefunded(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

### InvestorHasClaimedExcess
Throws when the investor has claimed excess capital invested.


```solidity
error InvestorHasClaimedExcess(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

### InvalidSalt
Throws when the salt used to encrypt the bid is invalid.


```solidity
error InvalidSalt();
```

### InvalidBidPublicKey
Throws when an invalid bid public key is used to encrypt a bid.


```solidity
error InvalidBidPublicKey();
```

### InvalidBidPrivateKey
Throws when an invalid bid private key is provided to decrypt a bid.


```solidity
error InvalidBidPrivateKey();
```

### NotInClaimWhitelist
Throws when the investor is not in the claim whitelist for tokens.


```solidity
error NotInClaimWhitelist(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

### NoCapitalInvested
Throws when no capital has been pledged by an investor.


```solidity
error NoCapitalInvested(address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

### NotCalledByLegion
Throws when not called by Legion.


```solidity
error NotCalledByLegion();
```

### NotCalledByProject
Throws when not called by the Project.


```solidity
error NotCalledByProject();
```

### NotCalledByLegionOrProject
Throws when not called by Legion or the Project.


```solidity
error NotCalledByLegionOrProject();
```

### PrefundAllocationPeriodNotEnded
Throws when capital is pledged during the pre-fund allocation period.


```solidity
error PrefundAllocationPeriodNotEnded();
```

### PrivateKeyAlreadyPublished
Throws when the private key has already been published by Legion.


```solidity
error PrivateKeyAlreadyPublished();
```

### PrivateKeyNotPublished
Throws when the private key has not been published by Legion.


```solidity
error PrivateKeyNotPublished();
```

### RefundPeriodIsNotOver
Throws when the refund period is not over.


```solidity
error RefundPeriodIsNotOver();
```

### RefundPeriodIsOver
Throws when the refund period is over.


```solidity
error RefundPeriodIsOver();
```

### SaleHasEnded
Throws when the sale has ended.


```solidity
error SaleHasEnded();
```

### SaleHasNotEnded
Throws when the sale has not ended.


```solidity
error SaleHasNotEnded();
```

### SaleIsCanceled
Throws when the sale is canceled.


```solidity
error SaleIsCanceled();
```

### SaleIsNotCanceled
Throws when the sale is not canceled.


```solidity
error SaleIsNotCanceled();
```

### SaleResultsNotPublished
Throws when the sale results are not published.


```solidity
error SaleResultsNotPublished();
```

### SignatureAlreadyUsed
Throws when the signature has already been used.


```solidity
error SignatureAlreadyUsed(bytes signature);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signature`|`bytes`|The signature that has been used.|

### CapitalRaisedNotPublished
Throws when the raised capital has not published.


```solidity
error CapitalRaisedNotPublished();
```

### SaleResultsAlreadyPublished
Throws when the sale results have been already published.


```solidity
error SaleResultsAlreadyPublished();
```

### CapitalRaisedAlreadyPublished
Throws when the raised capital have been already published.


```solidity
error CapitalRaisedAlreadyPublished();
```

### TokensAlreadyAllocated
Throws when the tokens have already been allocated.


```solidity
error TokensAlreadyAllocated();
```

### TokensNotAllocated
Throws when tokens have not been allocated.


```solidity
error TokensNotAllocated();
```

### TokensAlreadySupplied
Throws when tokens have already been supplied.


```solidity
error TokensAlreadySupplied();
```

### TokensNotSupplied
Throws when tokens have not been supplied.


```solidity
error TokensNotSupplied();
```

### ZeroAddressProvided
Throws when zero address has been provided.


```solidity
error ZeroAddressProvided();
```

### ZeroValueProvided
Throws when zero value has been provided.


```solidity
error ZeroValueProvided();
```

