# ILegionAbstractSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/sales/ILegionAbstractSale.sol)

**Author:**
Legion

Interface for the LegionAbstractSale contract.


## Functions
### refund

Requests a refund from the sale during the refund window.


```solidity
function refund() external;
```

### withdrawRaisedCapital

Withdraws raised capital to the project admin.


```solidity
function withdrawRaisedCapital() external;
```

### claimTokenAllocation

Claims token allocation for an investor.


```solidity
function claimTokenAllocation(
    uint256 amount,
    ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes32[] calldata proof
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The total amount of tokens to claim.|
|`investorVestingConfig`|`ILegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`proof`|`bytes32[]`|The Merkle proof for claim verification.|


### withdrawExcessInvestedCapital

Withdraws excess invested capital back to the investor.


```solidity
function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to withdraw.|
|`proof`|`bytes32[]`|The Merkle proof for excess capital verification.|


### releaseVestedTokens

Releases vested tokens to the investor.

*Interacts with the investor's vesting contract to release available tokens.*


```solidity
function releaseVestedTokens() external;
```

### supplyTokens

Supplies tokens for distribution after the sale.


```solidity
function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to supply.|
|`legionFee`|`uint256`|The fee amount for Legion.|
|`referrerFee`|`uint256`|The fee amount for the referrer.|


### setAcceptedCapital

Sets the Merkle root for accepted capital verification.


```solidity
function setAcceptedCapital(bytes32 merkleRoot) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The Merkle root for accepted capital verification.|


### withdrawInvestedCapitalIfCanceled

Withdraws invested capital if the sale is canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external;
```

### emergencyWithdraw

Performs an emergency withdrawal of tokens.


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to receive tokens.|
|`token`|`address`|The address of the token to withdraw.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external;
```

### pause

Pauses all sale operations.


```solidity
function pause() external;
```

### unpause

Resumes all sale operations.


```solidity
function unpause() external;
```

### saleConfiguration

Returns the current sale configuration.


```solidity
function saleConfiguration() external view returns (LegionSaleConfiguration memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LegionSaleConfiguration`|The complete sale configuration struct.|


### saleStatus

Returns the current sale status.


```solidity
function saleStatus() external view returns (LegionSaleStatus memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LegionSaleStatus`|The complete sale status struct.|


### investorPosition

Returns an investor's position details.


```solidity
function investorPosition(address investor) external view returns (InvestorPosition memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`InvestorPosition`|The complete investor position struct.|


### investorVestingStatus

Returns an investor's vesting status.


```solidity
function investorVestingStatus(address investor)
    external
    view
    returns (ILegionVestingManager.LegionInvestorVestingStatus memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`ILegionVestingManager.LegionInvestorVestingStatus`|vestingStatus The complete vesting status including timestamps, amounts, and release information.|


### cancel

Cancels the ongoing sale.

*Allows cancellation before results are published; only callable by the project admin.*


```solidity
function cancel() external;
```

## Events
### CapitalWithdrawn
Emitted when capital is withdrawn by the project owner.


```solidity
event CapitalWithdrawn(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital withdrawn.|

### CapitalRefunded
Emitted when capital is refunded to an investor.


```solidity
event CapitalRefunded(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded.|
|`investor`|`address`|The address of the investor receiving refund.|
|`positionId`|`uint256`|The ID of the investor's position.|

### CapitalRefundedAfterCancel
Emitted when capital is refunded after sale cancellation.


```solidity
event CapitalRefundedAfterCancel(uint256 amount, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded.|
|`investor`|`address`|The address of the investor receiving refund.|

### ExcessCapitalWithdrawn
Emitted when excess capital is claimed by an investor after sale completion.


```solidity
event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital withdrawn.|
|`investor`|`address`|The address of the investor claiming excess.|
|`positionId`|`uint256`|The ID of the investor's position.|

### AcceptedCapitalSet
Emitted when accepted capital Merkle root is published by Legion.


```solidity
event AcceptedCapitalSet(bytes32 merkleRoot);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The Merkle root for accepted capital verification.|

### EmergencyWithdraw
Emitted during an emergency withdrawal by Legion.


```solidity
event EmergencyWithdraw(address receiver, address token, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address receiving withdrawn tokens.|
|`token`|`address`|The address of the token withdrawn.|
|`amount`|`uint256`|The amount of tokens withdrawn.|

### LegionAddressesSynced
Emitted when Legion addresses are synced from the registry.


```solidity
event LegionAddressesSynced(
    address legionBouncer,
    address legionSigner,
    address legionFeeReceiver,
    address vestingFactory,
    address vestingController
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`legionBouncer`|`address`|The updated Legion bouncer address.|
|`legionSigner`|`address`|The updated Legion signer address.|
|`legionFeeReceiver`|`address`|The updated Legion fee receiver address.|
|`vestingFactory`|`address`|The updated vesting factory address.|
|`vestingController`|`address`|The updated vesting controller address.|

### SaleCanceled
Emitted when a sale is canceled.


```solidity
event SaleCanceled();
```

### TokensSuppliedForDistribution
Emitted when tokens are supplied for distribution by the project.


```solidity
event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens supplied.|
|`legionFee`|`uint256`|The fee amount collected by Legion.|
|`referrerFee`|`uint256`|The fee amount collected by referrer.|

### TokenAllocationClaimed
Emitted when an investor successfully claims their token allocation.


```solidity
event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToBeVested`|`uint256`|The amount of tokens sent to vesting contract.|
|`amountOnClaim`|`uint256`|The amount of tokens distributed immediately.|
|`investor`|`address`|The address of the claiming investor.|
|`positionId`|`uint256`|The ID of the investor's position.|

## Structs
### LegionSaleInitializationParams
*Struct defining initialization parameters for a Legion sale*


```solidity
struct LegionSaleInitializationParams {
    uint64 salePeriodSeconds;
    uint64 refundPeriodSeconds;
    uint16 legionFeeOnCapitalRaisedBps;
    uint16 legionFeeOnTokensSoldBps;
    uint16 referrerFeeOnCapitalRaisedBps;
    uint16 referrerFeeOnTokensSoldBps;
    uint256 minimumInvestAmount;
    address bidToken;
    address askToken;
    address projectAdmin;
    address addressRegistry;
    address referrerFeeReceiver;
    string saleName;
    string saleSymbol;
    string saleBaseURI;
}
```

### LegionSaleConfiguration
*Struct containing the runtime configuration of the sale*


```solidity
struct LegionSaleConfiguration {
    uint64 startTime;
    uint64 endTime;
    uint64 refundEndTime;
    uint16 legionFeeOnCapitalRaisedBps;
    uint16 legionFeeOnTokensSoldBps;
    uint16 referrerFeeOnCapitalRaisedBps;
    uint16 referrerFeeOnTokensSoldBps;
    uint256 minimumInvestAmount;
}
```

### LegionSaleAddressConfiguration
*Struct containing the address configuration for the sale*


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
*Struct tracking the current status of the sale*


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

### InvestorPosition
*Struct representing an investor's position in the sale*


```solidity
struct InvestorPosition {
    uint256 investedCapital;
    bool hasSettled;
    bool hasClaimedExcess;
    bool hasRefunded;
    address vestingAddress;
}
```

