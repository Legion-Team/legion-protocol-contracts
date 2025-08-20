# ILegionCapitalRaise
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/raise/ILegionCapitalRaise.sol)

**Author:**
Legion

Interface for the LegionCapitalRaise contract.


## Functions
### initialize

Initializes the capital raise contract with configuration parameters.


```solidity
function initialize(CapitalRaiseInitializationParams calldata capitalRaiseInitParams) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaiseInitParams`|`CapitalRaiseInitializationParams`|The initialization parameters for the capital raise.|


### invest

Allows an investor to contribute capital to the capital raise.


```solidity
function invest(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes calldata investSignature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
|`investAmount`|`uint256`|The maximum capital allowed for this investor.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals precision).|
|`investSignature`|`bytes`|The signature verifying investor eligibility and terms.|


### refund

Processes a refund for an investor during the refund period.


```solidity
function refund() external;
```

### emergencyWithdraw

Withdraws tokens in emergency situations.


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to receive the withdrawn tokens.|
|`token`|`address`|The address of the token to withdraw.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### withdrawRaisedCapital

Withdraws raised capital to the project admin.


```solidity
function withdrawRaisedCapital() external;
```

### cancel

Cancels the capital raise and handles capital return.


```solidity
function cancel() external;
```

### withdrawInvestedCapitalIfCanceled

Allows investors to withdraw capital if the capital raise is canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external;
```

### withdrawExcessInvestedCapital

Withdraws excess invested capital back to investors.


```solidity
function withdrawExcessInvestedCapital(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes calldata claimExcessSignature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to withdraw.|
|`investAmount`|`uint256`|The maximum capital allowed for this investor.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals precision).|
|`claimExcessSignature`|`bytes`|The signature verifying eligibility to claim excess capital.|


### end

Ends the capital raise manually.


```solidity
function end() external;
```

### publishRaisedCapital

Publishes the total capital raised amount.


```solidity
function publishRaisedCapital(uint256 capitalRaised) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|


### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external;
```

### pause

Pauses all capital raise operations.


```solidity
function pause() external;
```

### unpause

Resumes all capital raise operations.


```solidity
function unpause() external;
```

### saleConfiguration

Returns the current capital raise configuration.


```solidity
function saleConfiguration() external view returns (CapitalRaiseConfig memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`CapitalRaiseConfig`|The complete capital raise configuration struct.|


### saleStatus

Returns the current capital raise status.


```solidity
function saleStatus() external view returns (CapitalRaiseStatus memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`CapitalRaiseStatus`|The complete capital raise status struct.|


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


## Events
### CapitalInvested
Emitted when capital is successfully invested in the pre-liquid capital raise.


```solidity
event CapitalInvested(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested (in bid tokens).|
|`investor`|`address`|The address of the investor.|
|`positionId`|`uint256`|The unique identifier for the investor's position.|

### ExcessCapitalWithdrawn
Emitted when excess capital is successfully withdrawn by an investor.


```solidity
event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital withdrawn.|
|`investor`|`address`|The address of the investor.|
|`positionId`|`uint256`|The unique identifier for the investor's position.|

### CapitalRefunded
Emitted when capital is successfully refunded to an investor.


```solidity
event CapitalRefunded(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded.|
|`investor`|`address`|The address of the investor receiving the refund.|
|`positionId`|`uint256`|The unique identifier for the investor's position.|

### CapitalRefundedAfterCancel
Emitted when capital is refunded after capital raise cancellation.


```solidity
event CapitalRefundedAfterCancel(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded.|
|`investor`|`address`|The address of the investor receiving the refund.|
|`positionId`|`uint256`|The unique identifier for the investor's position.|

### CapitalWithdrawn
Emitted when capital is successfully withdrawn by the project.


```solidity
event CapitalWithdrawn(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The total amount of capital withdrawn.|

### CapitalRaisedPublished
Emitted when the total capital raised is published by Legion.


```solidity
event CapitalRaisedPublished(uint256 capitalRaised);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|

### EmergencyWithdraw
Emitted during an emergency withdrawal by Legion.


```solidity
event EmergencyWithdraw(address receiver, address token, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address receiving the withdrawn tokens.|
|`token`|`address`|The address of the token withdrawn.|
|`amount`|`uint256`|The amount of tokens withdrawn.|

### LegionAddressesSynced
Emitted when Legion addresses are successfully synced.


```solidity
event LegionAddressesSynced(address legionBouncer, address legionSigner, address legionFeeReceiver);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`legionBouncer`|`address`|The updated Legion bouncer address.|
|`legionSigner`|`address`|The updated Legion signer address.|
|`legionFeeReceiver`|`address`|The updated Legion fee receiver address.|

### CapitalRaiseCanceled
Emitted when the capital raise is successfully canceled.


```solidity
event CapitalRaiseCanceled();
```

### CapitalRaiseEnded
Emitted when the capital raise has ended.


```solidity
event CapitalRaiseEnded();
```

## Structs
### CapitalRaiseInitializationParams
*Struct defining initialization parameters for the pre-liquid capital raise*


```solidity
struct CapitalRaiseInitializationParams {
    uint64 refundPeriodSeconds;
    uint16 legionFeeOnCapitalRaisedBps;
    uint16 referrerFeeOnCapitalRaisedBps;
    address bidToken;
    address projectAdmin;
    address addressRegistry;
    address referrerFeeReceiver;
    string saleName;
    string saleSymbol;
    string saleBaseURI;
}
```

### CapitalRaiseConfig
*Struct containing the runtime configuration of the pre-liquid capital raise*


```solidity
struct CapitalRaiseConfig {
    uint64 refundPeriodSeconds;
    uint16 legionFeeOnCapitalRaisedBps;
    uint16 referrerFeeOnCapitalRaisedBps;
    address bidToken;
    address projectAdmin;
    address addressRegistry;
    address legionBouncer;
    address legionSigner;
    address legionFeeReceiver;
    address referrerFeeReceiver;
}
```

### CapitalRaiseStatus
*Struct tracking the current status of the pre-liquid capital raise*


```solidity
struct CapitalRaiseStatus {
    uint64 endTime;
    uint64 refundEndTime;
    bool isCanceled;
    bool hasEnded;
    uint256 totalCapitalInvested;
    uint256 totalCapitalRaised;
    uint256 totalCapitalWithdrawn;
}
```

### InvestorPosition
*Struct representing an investor's position in the capital raise*


```solidity
struct InvestorPosition {
    bool hasClaimedExcess;
    bool hasRefunded;
    uint256 investedCapital;
    uint256 cachedInvestAmount;
    uint256 cachedTokenAllocationRate;
}
```

## Enums
### CapitalRaiseAction
*Enum defining possible actions during the capital raise*


```solidity
enum CapitalRaiseAction {
    INVEST,
    WITHDRAW_EXCESS_CAPITAL
}
```

