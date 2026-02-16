# ILegionAbstractSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/interfaces/sales/ILegionAbstractSale.sol)

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

### withdrawExcessInvestedCapital

Withdraws excess invested capital back to the investor.


```solidity
function withdrawExcessInvestedCapital(uint256 amount, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to withdraw.|
|`signature`|`bytes`|The signature authorizing the withdrawal.|


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


### cancel

Cancels the ongoing sale.

*Allows cancellation before results are published; only callable by the project admin.*


```solidity
function cancel() external;
```

### updateLegionOpsFee

Updates Legion's operations fee.


```solidity
function updateLegionOpsFee(uint256 newFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFee`|`uint256`|The new fee amount in wei.|


### claimReceiptTokens

Claims sale receipt tokens after investment.


```solidity
function claimReceiptTokens() external;
```

### toggleTransferReceiptTokens

Toggles the transferability of receipt tokens.


```solidity
function toggleTransferReceiptTokens() external;
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
event CapitalRefunded(uint256 amount, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded.|
|`investor`|`address`|The address of the investor receiving refund.|

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
event ExcessCapitalWithdrawn(uint256 amount, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital withdrawn.|
|`investor`|`address`|The address of the investor claiming excess.|

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
event LegionAddressesSynced(address legionBouncer, address legionSigner, address legionFeeReceiver);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`legionBouncer`|`address`|The updated Legion bouncer address.|
|`legionSigner`|`address`|The updated Legion signer address.|
|`legionFeeReceiver`|`address`|The updated Legion fee receiver address.|

### LegionOpsFeeUpdated
Emitted when Legion's operations fee is updated.


```solidity
event LegionOpsFeeUpdated(uint256 oldFee, uint256 newFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oldFee`|`uint256`|The previous fee amount in wei.|
|`newFee`|`uint256`|The new fee amount in wei.|

### ReceiptTokensClaimed
Emitted when receipt tokens are claimed by an investor.


```solidity
event ReceiptTokensClaimed(address investor, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor claiming tokens.|
|`amount`|`uint256`|The amount of receipt tokens claimed.|

### SaleCanceled
Emitted when a sale is canceled.


```solidity
event SaleCanceled();
```

### TransferReceiptTokensToggled
Emitted when transfer of receipt tokens is toggled.


```solidity
event TransferReceiptTokensToggled(bool isPaused);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isPaused`|`bool`|The new paused state of receipt token transfers.|

## Structs
### LegionSaleInitializationParams
*Struct defining initialization parameters for a Legion sale*


```solidity
struct LegionSaleInitializationParams {
    uint64 refundPeriodSeconds;
    uint16 legionFeeOnCapitalRaisedBps;
    uint16 referrerFeeOnCapitalRaisedBps;
    uint256 minimumInvestAmount;
    uint256 legionOpsFeeInWei;
    uint8 bidTokenDecimals;
    address bidToken;
    address projectAdmin;
    address addressRegistry;
    address referrerFeeReceiver;
    bool transferReceiptTokensIsPaused;
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
    uint16 referrerFeeOnCapitalRaisedBps;
    uint256 minimumInvestAmount;
    uint256 legionOpsFeeInWei;
    uint8 bidTokenDecimals;
    bool transferReceiptTokensIsPaused;
}
```

### LegionSaleAddressConfiguration
*Struct containing the address configuration for the sale*


```solidity
struct LegionSaleAddressConfiguration {
    address bidToken;
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
    uint256 totalCapitalRaised;
    uint256 totalCapitalWithdrawn;
    bool isCanceled;
    bool capitalWithdrawn;
    bool hasEnded;
}
```

### InvestorPosition
*Struct representing an investor's position in the sale*


```solidity
struct InvestorPosition {
    uint256 investedCapital;
    bool hasClaimedExcess;
    bool hasRefunded;
}
```

## Enums
### SaleAction
*Enum defining possible actions during the sale*


```solidity
enum SaleAction {
    INVEST,
    WITHDRAW_EXCESS_CAPITAL
}
```

