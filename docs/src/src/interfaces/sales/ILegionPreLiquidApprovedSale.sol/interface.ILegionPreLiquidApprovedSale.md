# ILegionPreLiquidApprovedSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/sales/ILegionPreLiquidApprovedSale.sol)

**Author:**
Legion

Interface for the LegionPreLiquidApprovedSale contract.


## Functions
### initialize

Initializes the pre-liquid approved sale contract with parameters.


```solidity
function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The pre-liquid approved sale initialization parameters.|


### invest

Allows an investor to invest capital in the pre-liquid approved sale.


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
|`investAmount`|`uint256`|The maximum capital allowed.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals).|
|`investSignature`|`bytes`|The signature verifying investor eligibility.|


### refund

Processes a refund for an investor during the refund period.


```solidity
function refund() external;
```

### publishTgeDetails

Publishes token details after Token Generation Event (TGE).


```solidity
function publishTgeDetails(address askToken, uint256 askTokenTotalSupply, uint256 totalTokensAllocated) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`askToken`|`address`|The address of the token to be distributed.|
|`askTokenTotalSupply`|`uint256`|The total supply of the ask token.|
|`totalTokensAllocated`|`uint256`|The total tokens allocated for investors.|


### supplyTokens

Supplies tokens for distribution after TGE.


```solidity
function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to supply.|
|`legionFee`|`uint256`|The fee amount for Legion.|
|`referrerFee`|`uint256`|The fee amount for the referrer.|


### emergencyWithdraw

Withdraws tokens in emergency situations.


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to receive withdrawn tokens.|
|`token`|`address`|The address of the token to withdraw.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### withdrawRaisedCapital

Withdraws raised capital to the project admin.


```solidity
function withdrawRaisedCapital() external;
```

### claimTokenAllocation

Allows investors to claim their token allocation.


```solidity
function claimTokenAllocation(
    uint256 investAmount,
    uint256 tokenAllocationRate,
    ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes calldata claimSignature,
    bytes calldata vestingSignature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investAmount`|`uint256`|The maximum capital allowed per SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals).|
|`investorVestingConfig`|`ILegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`claimSignature`|`bytes`|The signature verifying investment eligibility.|
|`vestingSignature`|`bytes`|The signature verifying vesting terms.|


### cancel

Cancels the sale and handles capital return.


```solidity
function cancel() external;
```

### withdrawInvestedCapitalIfCanceled

Allows investors to withdraw capital if the sale is canceled.


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
    bytes calldata withdrawSignature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to withdraw.|
|`investAmount`|`uint256`|The maximum capital allowed.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals).|
|`withdrawSignature`|`bytes`|The signature verifying eligibility.|


### releaseVestedTokens

Releases vested tokens to the investor.


```solidity
function releaseVestedTokens() external;
```

### end

Ends the sale manually.


```solidity
function end() external;
```

### publishRaisedCapital

Publishes the total capital raised.


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
function saleConfiguration() external view returns (PreLiquidSaleConfig memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`PreLiquidSaleConfig`|The complete sale configuration struct.|


### saleStatus

Returns the current sale status.


```solidity
function saleStatus() external view returns (PreLiquidSaleStatus memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`PreLiquidSaleStatus`|The complete sale status struct.|


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


## Events
### CapitalInvested
Emitted when capital is successfully invested in the pre-liquid sale.


```solidity
event CapitalInvested(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested (in bid tokens).|
|`investor`|`address`|The address of the investor.|
|`positionId`|`uint256`|The ID of the investor's position.|

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
|`positionId`|`uint256`|The ID of the investor's position.|

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
|`positionId`|`uint256`|The ID of the investor's position.|

### CapitalRefundedAfterCancel
Emitted when capital is refunded after sale cancellation.


```solidity
event CapitalRefundedAfterCancel(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital refunded.|
|`investor`|`address`|The address of the investor receiving the refund.|
|`positionId`|`uint256`|The ID of the investor's position.|

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
Emitted when the sale is successfully canceled.


```solidity
event SaleCanceled();
```

### TgeDetailsPublished
Emitted when token details are published after TGE by Legion.


```solidity
event TgeDetailsPublished(address tokenAddress, uint256 totalSupply, uint256 allocatedTokenAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the token distributed.|
|`totalSupply`|`uint256`|The total supply of the distributed token.|
|`allocatedTokenAmount`|`uint256`|The amount of tokens allocated for investors.|

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
|`referrerFee`|`uint256`|The fee amount collected by the referrer.|

### SaleEnded
Emitted when the sale has ended.


```solidity
event SaleEnded();
```

## Structs
### PreLiquidSaleInitializationParams
*Struct defining initialization parameters for the pre-liquid sale*


```solidity
struct PreLiquidSaleInitializationParams {
    address bidToken;
    address projectAdmin;
    address addressRegistry;
    address referrerFeeReceiver;
    uint64 refundPeriodSeconds;
    uint16 legionFeeOnCapitalRaisedBps;
    uint16 legionFeeOnTokensSoldBps;
    uint16 referrerFeeOnCapitalRaisedBps;
    uint16 referrerFeeOnTokensSoldBps;
    string saleName;
    string saleSymbol;
    string saleBaseURI;
}
```

### PreLiquidSaleConfig
*Struct containing the runtime configuration of the pre-liquid sale*


```solidity
struct PreLiquidSaleConfig {
    address bidToken;
    address projectAdmin;
    address addressRegistry;
    address legionBouncer;
    address legionSigner;
    address legionFeeReceiver;
    address referrerFeeReceiver;
    uint64 refundPeriodSeconds;
    uint16 legionFeeOnCapitalRaisedBps;
    uint16 legionFeeOnTokensSoldBps;
    uint16 referrerFeeOnCapitalRaisedBps;
    uint16 referrerFeeOnTokensSoldBps;
}
```

### PreLiquidSaleStatus
*Struct tracking the current status of the pre-liquid sale*


```solidity
struct PreLiquidSaleStatus {
    address askToken;
    uint256 askTokenTotalSupply;
    uint256 totalCapitalInvested;
    uint256 totalCapitalRaised;
    uint256 totalTokensAllocated;
    uint256 totalCapitalWithdrawn;
    uint64 endTime;
    uint64 refundEndTime;
    bool isCanceled;
    bool tokensSupplied;
    bool hasEnded;
}
```

### InvestorPosition
*Struct representing an investor's position in the sale*


```solidity
struct InvestorPosition {
    address vestingAddress;
    uint256 investedCapital;
    uint256 cachedInvestAmount;
    uint256 cachedTokenAllocationRate;
    bool hasClaimedExcess;
    bool hasRefunded;
    bool hasSettled;
}
```

## Enums
### SaleAction
*Enum defining possible actions during the sale*


```solidity
enum SaleAction {
    INVEST,
    WITHDRAW_EXCESS_CAPITAL,
    CLAIM_TOKEN_ALLOCATION
}
```

