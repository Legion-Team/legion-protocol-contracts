# ILegionPreLiquidSaleV1
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/interfaces/sales/ILegionPreLiquidSaleV1.sol)


## Functions
### initialize

Initializes the contract with correct parameters.


```solidity
function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The pre-liquid sale initialization parameters.|


### invest

Invest capital to the pre-liquid sale.


```solidity
function invest(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes memory investSignature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`investSignature`|`bytes`|The signature proving that the investor is allowed to participate.|


### refund

Get a refund from the sale during the applicable time window.


```solidity
function refund() external;
```

### publishTgeDetails

Updates the token details after Token Generation Event (TGE).

*Only callable by Legion.*


```solidity
function publishTgeDetails(address _askToken, uint256 _askTokenTotalSupply, uint256 _totalTokensAllocated) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_askToken`|`address`|The address of the token distributed to investors.|
|`_askTokenTotalSupply`|`uint256`|The total supply of the token distributed to investors.|
|`_totalTokensAllocated`|`uint256`|The allocated token amount for distribution to investors.|


### supplyTokens

Supply tokens for distribution after the Token Generation Event (TGE).

*Only callable by the Project.*


```solidity
function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to be supplied for distribution.|
|`legionFee`|`uint256`|The Legion fee token amount.|
|`referrerFee`|`uint256`|The Referrer fee token amount.|


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


### withdrawRaisedCapital

Withdraw capital from the contract.

*Can be called only by the Project admin address.*


```solidity
function withdrawRaisedCapital() external;
```

### claimTokenAllocation

Claim token allocation by investors.


```solidity
function claimTokenAllocation(
    uint256 investAmount,
    uint256 tokenAllocationRate,
    ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes memory investSignature,
    bytes memory vestingSignature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`investorVestingConfig`|`ILegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`investSignature`|`bytes`|The signature proving that the investor has signed a SAFT.|
|`vestingSignature`|`bytes`|The signature proving that investor vesting terms are valid.|


### cancelSale

Cancel the sale.

*Can be called only by the Project admin address.*


```solidity
function cancelSale() external;
```

### withdrawInvestedCapitalIfCanceled

Withdraw capital if the sale has been canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external;
```

### withdrawExcessInvestedCapital

Withdraw back excess capital from investors.


```solidity
function withdrawExcessInvestedCapital(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes memory investSignature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to be withdrawn.|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`investSignature`|`bytes`|The signature proving that the investor is allowed to participate.|


### releaseVestedTokens

Releases tokens from vesting to the investor address.


```solidity
function releaseVestedTokens() external;
```

### endSale

Ends the sale.


```solidity
function endSale() external;
```

### publishCapitalRaised

Publish the total capital raised by the project.


```solidity
function publishCapitalRaised(uint256 capitalRaised) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|


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
function saleConfiguration() external view returns (PreLiquidSaleConfig memory);
```

### saleStatusDetails

Returns the sale status details.


```solidity
function saleStatusDetails() external view returns (PreLiquidSaleStatus memory);
```

### investorPositionDetails

Returns an investor position details.


```solidity
function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);
```

### investorVestingStatus

Returns the investor vesting status.


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


## Events
### CapitalInvested
This event is emitted when capital is successfully invested.


```solidity
event CapitalInvested(uint256 amount, address investor, uint256 tokenAllocationRate, uint256 investTimestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`investor`|`address`|The address of the investor.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`investTimestamp`|`uint256`|The Unix timestamp (seconds) of the block when capital has been invested.|

### ExcessCapitalWithdrawn
This event is emitted when excess capital is successfully withdrawn.


```solidity
event ExcessCapitalWithdrawn(uint256 amount, address investor, uint256 tokenAllocationRate, uint256 investTimestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital withdrawn.|
|`investor`|`address`|The address of the investor.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`investTimestamp`|`uint256`|The Unix timestamp (seconds) of the block when capital has been invested.|

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

### CapitalWithdrawn
This event is emitted when capital is successfully withdrawn by the Project.


```solidity
event CapitalWithdrawn(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital withdrawn by the project.|

### CapitalRaisedPublished
This event is emitted when the capital raised is successfully published by the Legion admin.


```solidity
event CapitalRaisedPublished(uint256 capitalRaised);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|

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

### TgeDetailsPublished
This event is emitted when the token details have been set by the Legion admin.


```solidity
event TgeDetailsPublished(address tokenAddress, uint256 totalSupply, uint256 allocatedTokenAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the token distributed to investors.|
|`totalSupply`|`uint256`|The total supply of the token distributed to investors.|
|`allocatedTokenAmount`|`uint256`|The allocated token amount for distribution to investors.|

### TokenAllocationClaimed
This event is emitted when tokens are successfully claimed by the investor.


```solidity
event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToBeVested`|`uint256`|The amount of tokens distributed to the vesting contract.|
|`amountOnClaim`|`uint256`|The amount of tokens to be distributed directly to the investor on claim.|
|`investor`|`address`|The address of the investor owning the vesting contract.|

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

### SaleEnded
This event is emitted when the sale has ended.


```solidity
event SaleEnded(uint256 endTime);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`endTime`|`uint256`|The Unix timestamp (seconds) of the block when the sale has been ended.|

## Structs
### PreLiquidSaleInitializationParams
A struct describing the pre-liquid sale initialization params.


```solidity
struct PreLiquidSaleInitializationParams {
    uint256 refundPeriodSeconds;
    uint256 legionFeeOnCapitalRaisedBps;
    uint256 legionFeeOnTokensSoldBps;
    uint256 referrerFeeOnCapitalRaisedBps;
    uint256 referrerFeeOnTokensSoldBps;
    address bidToken;
    address projectAdmin;
    address addressRegistry;
    address referrerFeeReceiver;
}
```

### PreLiquidSaleConfig
A struct describing the pre-liquid sale configuration.


```solidity
struct PreLiquidSaleConfig {
    uint256 refundPeriodSeconds;
    uint256 legionFeeOnCapitalRaisedBps;
    uint256 legionFeeOnTokensSoldBps;
    uint256 referrerFeeOnCapitalRaisedBps;
    uint256 referrerFeeOnTokensSoldBps;
    address bidToken;
    address projectAdmin;
    address addressRegistry;
    address legionBouncer;
    address legionSigner;
    address legionFeeReceiver;
    address referrerFeeReceiver;
}
```

### PreLiquidSaleStatus
A struct describing the pre-liquid sale status.


```solidity
struct PreLiquidSaleStatus {
    address askToken;
    uint256 askTokenTotalSupply;
    uint256 totalCapitalInvested;
    uint256 totalCapitalRaised;
    uint256 totalTokensAllocated;
    uint256 totalCapitalWithdrawn;
    uint256 endTime;
    uint256 refundEndTime;
    bool isCanceled;
    bool askTokensSupplied;
    bool hasEnded;
}
```

### InvestorPosition
A struct describing the investor position during the sale.


```solidity
struct InvestorPosition {
    uint256 investedCapital;
    uint256 cachedInvestAmount;
    uint256 cachedTokenAllocationRate;
    bool hasRefunded;
    bool hasSettled;
    address vestingAddress;
}
```

## Enums
### SaleAction
An enum describing possible actions during the sale.


```solidity
enum SaleAction {
    INVEST,
    WITHDRAW_EXCESS_CAPITAL,
    CLAIM_TOKEN_ALLOCATION
}
```

