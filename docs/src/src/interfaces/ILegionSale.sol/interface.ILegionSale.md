# ILegionSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/ac3edaa080a44c4acca1531370a76a05f05491f5/src/interfaces/ILegionSale.sol)


## Functions
### refund

Request a refund from the sale during the applicable time window.


```solidity
function refund() external;
```

### withdrawRaisedCapital

Withdraw raised capital from the sale contract.

*Can be called only by the Project admin address.*


```solidity
function withdrawRaisedCapital() external;
```

### claimTokenAllocation

Claims the investor token allocation.


```solidity
function claimTokenAllocation(uint256 amount, bytes32[] calldata proof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount to be distributed.|
|`proof`|`bytes32[]`|The merkle proof verification for claiming.|


### withdrawExcessInvestedCapital

Withdraw excess capital back to the investor.


```solidity
function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount to be returned.|
|`proof`|`bytes32[]`|The merkle proof verification for the return.|


### releaseVestedTokens

Releases tokens to the investor address.


```solidity
function releaseVestedTokens() external;
```

### supplyTokens

Supply tokens once the sale results have been published.

*Can be called only by the Project admin address.*


```solidity
function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The token amount supplied by the project.|
|`legionFee`|`uint256`|The legion fee token amount supplied by the project.|
|`referrerFee`|`uint256`|The referrer fee token amount supplied by the project.|


### setAcceptedCapital

Publish merkle root for accepted capital.

*Can be called only by the Legion admin address.*


```solidity
function setAcceptedCapital(bytes32 merkleRoot) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The merkle root to verify against.|


### cancelSale

Cancels an ongoing sale.

*Can be called only by the Project admin address.*


```solidity
function cancelSale() external;
```

### cancelExpiredSale

Cancels a sale in case the project has not supplied tokens after the lockup period is over.


```solidity
function cancelExpiredSale() external;
```

### withdrawInvestedCapitalIfCanceled

Claims back capital in case the sale has been canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external;
```

### emergencyWithdraw

Withdraw tokens from the contract in case of emergency.

*Can be called only by the Legion admin address.*


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address of the receiver.|
|`token`|`address`|The address of the token to be withdrawn.|
|`amount`|`uint256`|The amount to be withdrawn.|


### syncLegionAddresses

Syncs active Legion addresses from `LegionAddressRegistry.sol`.


```solidity
function syncLegionAddresses() external;
```

### pauseSale

Pauses the sale.


```solidity
function pauseSale() external;
```

### unpauseSale

Unpauses the sale.


```solidity
function unpauseSale() external;
```

### saleConfiguration

Returns the sale configuration.


```solidity
function saleConfiguration() external view returns (LegionSaleConfiguration memory);
```

### vestingConfiguration

Returns the vesting configuration.


```solidity
function vestingConfiguration() external view returns (LegionVestingConfiguration memory);
```

### saleStatusDetails

Returns the sale status details.


```solidity
function saleStatusDetails() external view returns (LegionSaleStatus memory);
```

### investorPositionDetails

Returns an investor position.


```solidity
function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investorAddress`|`address`|The address of the investor.|


## Events
### CapitalWithdrawn
This event is emitted when capital is successfully withdrawn by the project owner.


```solidity
event CapitalWithdrawn(uint256 amountToWithdraw, address projectOwner);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToWithdraw`|`uint256`|The amount of capital withdrawn.|
|`projectOwner`|`address`|The address of the project owner.|

### CapitalRefunded
This event is emitted when capital is successfully refunded to the investor.


```solidity
event CapitalRefunded(uint256 amount, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded to the investor.|
|`investor`|`address`|The address of the investor who requested the refund.|

### CapitalRefundedAfterCancel
This event is emitted when capital is successfully refunded to the investor after a sale has been
canceled.


```solidity
event CapitalRefundedAfterCancel(uint256 amount, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded to the investor.|
|`investor`|`address`|The address of the investor who requested the refund.|

### ExcessCapitalWithdrawn
This event is emitted when excess capital is successfully claimed by the investor after a sale has ended.


```solidity
event ExcessCapitalWithdrawn(uint256 amount, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded to the investor.|
|`investor`|`address`|The address of the investor who requested the refund.|

### AcceptedCapitalSet
This event is emitted when accepted capital has been successfully published by the Legion admin.


```solidity
event AcceptedCapitalSet(bytes32 merkleRoot);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The accepted capital merkle root published.|

### EmergencyWithdraw
This event is emitted when an emergency withdrawal of funds is performed by Legion.


```solidity
event EmergencyWithdraw(address receiver, address token, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address of the receiver.|
|`token`|`address`|The address of the token to be withdrawn.|
|`amount`|`uint256`|The amount to be withdrawn.|

### LegionAddressesSynced
This event is emitted when Legion addresses are successfully synced.


```solidity
event LegionAddressesSynced(
    address legionBouncer, address legionSigner, address legionFeeReceiver, address vestingFactory
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`legionBouncer`|`address`|The updated Legion bouncer address.|
|`legionSigner`|`address`|The updated Legion signer address.|
|`legionFeeReceiver`|`address`|The updated fee receiver address of Legion.|
|`vestingFactory`|`address`|The updated vesting factory address.|

### SaleCanceled
This event is emitted when a sale is successfully canceled.


```solidity
event SaleCanceled();
```

### TokensSuppliedForDistribution
This event is emitted when tokens are successfully supplied for distribution by the project admin.


```solidity
event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens supplied for distribution.|
|`legionFee`|`uint256`|The fee amount collected by Legion.|
|`referrerFee`|`uint256`|The fee amount collected by the referrer.|

### TokenAllocationClaimed
This event is emitted when tokens are successfully claimed by the investor.


```solidity
event TokenAllocationClaimed(uint256 amount, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens distributed to the vesting contract.|
|`investor`|`address`|The address of the investor owning the vesting contract.|

## Structs
### LegionSaleInitializationParams
A struct describing the Legion sale initialization params.


```solidity
struct LegionSaleInitializationParams {
    uint256 salePeriodSeconds;
    uint256 refundPeriodSeconds;
    uint256 lockupPeriodSeconds;
    uint256 legionFeeOnCapitalRaisedBps;
    uint256 legionFeeOnTokensSoldBps;
    uint256 referrerFeeOnCapitalRaisedBps;
    uint256 referrerFeeOnTokensSoldBps;
    uint256 minimumInvestAmount;
    address bidToken;
    address askToken;
    address projectAdmin;
    address addressRegistry;
    address referrerFeeReceiver;
}
```

### LegionVestingInitializationParams
A struct describing the Legion vesting initialization params.


```solidity
struct LegionVestingInitializationParams {
    uint256 vestingDurationSeconds;
    uint256 vestingCliffDurationSeconds;
    uint256 tokenAllocationOnTGERate;
}
```

### LegionSaleConfiguration
A struct describing the sale configuration.


```solidity
struct LegionSaleConfiguration {
    uint256 startTime;
    uint256 endTime;
    uint256 refundEndTime;
    uint256 lockupEndTime;
    uint256 legionFeeOnCapitalRaisedBps;
    uint256 legionFeeOnTokensSoldBps;
    uint256 referrerFeeOnCapitalRaisedBps;
    uint256 referrerFeeOnTokensSoldBps;
    uint256 minimumInvestAmount;
}
```

### LegionSaleAddressConfiguration
A struct describing the sale address configuration.


```solidity
struct LegionSaleAddressConfiguration {
    address bidToken;
    address askToken;
    address projectAdmin;
    address addressRegistry;
    address legionBouncer;
    address legionSigner;
    address legionFeeReceiver;
    address referrerFeeReceiver;
}
```

### LegionSaleStatus
A struct describing the sale status.


```solidity
struct LegionSaleStatus {
    uint256 totalCapitalInvested;
    uint256 totalTokensAllocated;
    uint256 totalCapitalRaised;
    uint256 totalCapitalWithdrawn;
    bytes32 claimTokensMerkleRoot;
    bytes32 acceptedCapitalMerkleRoot;
    bool isCanceled;
    bool tokensSupplied;
    bool capitalWithdrawn;
}
```

### LegionVestingConfiguration
A struct describing the vesting configuration.


```solidity
struct LegionVestingConfiguration {
    uint256 vestingDurationSeconds;
    uint256 vestingCliffDurationSeconds;
    uint256 tokenAllocationOnTGERate;
    uint256 vestingStartTime;
    address vestingFactory;
}
```

### InvestorPosition
A struct describing the investor position during the sale.


```solidity
struct InvestorPosition {
    uint256 investedCapital;
    bool hasSettled;
    bool hasClaimedExcess;
    bool hasRefunded;
    address vestingAddress;
}
```

