# ILegionPreLiquidSaleV1
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/e045131669c5801ab2e88b13e55002362a64c068/src/interfaces/ILegionPreLiquidSaleV1.sol)


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
    bytes32 saftHash,
    bytes memory signature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.|
|`signature`|`bytes`|The signature proving that the investor is allowed to participate.|


### refund

Get a refund from the sale during the applicable time window.


```solidity
function refund() external;
```

### publishTgeDetails

Updates the token details after Token Generation Event (TGE).

*Only callable by Legion.*


```solidity
function publishTgeDetails(
    address _askToken,
    uint256 _askTokenTotalSupply,
    uint256 _vestingStartTime,
    uint256 _totalTokensAllocated
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_askToken`|`address`|The address of the token distributed to investors.|
|`_askTokenTotalSupply`|`uint256`|The total supply of the token distributed to investors.|
|`_vestingStartTime`|`uint256`|The Unix timestamp (seconds) of the block when the vesting starts.|
|`_totalTokensAllocated`|`uint256`|The allocated token amount for distribution to investors.|


### supplyAskTokens

Supply tokens for distribution after the Token Generation Event (TGE).

*Only callable by the Project.*


```solidity
function supplyAskTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to be supplied for distribution.|
|`legionFee`|`uint256`|The Legion fee token amount.|
|`referrerFee`|`uint256`|The Referrer fee token amount.|


### updateVestingTerms

Updates the vesting terms.

*Only callable by Legion, before the tokens have been supplied by the Project.*


```solidity
function updateVestingTerms(
    uint256 vestingDurationSeconds,
    uint256 vestingCliffDurationSeconds,
    uint256 tokenAllocationOnTGERate
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`vestingDurationSeconds`|`uint256`|The vesting schedule duration for the token sold in seconds.|
|`vestingCliffDurationSeconds`|`uint256`|The vesting cliff duration for the token sold in seconds.|
|`tokenAllocationOnTGERate`|`uint256`|The token allocation amount released to investors after TGE in 18 decimals precision.|


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

### claimAskTokenAllocation

Claim token allocation by investors.


```solidity
function claimAskTokenAllocation(
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes memory signature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.|
|`signature`|`bytes`|The signature proving that the investor has signed a SAFT.|


### cancelSale

Cancel the sale.

*Can be called only by the Project admin address.*


```solidity
function cancelSale() external;
```

### withdrawCapitalIfSaleIsCanceled

Withdraw capital if the sale has been canceled.


```solidity
function withdrawCapitalIfSaleIsCanceled() external;
```

### withdrawExcessCapital

Withdraw back excess capital from investors.


```solidity
function withdrawExcessCapital(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes memory signature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to be withdrawn.|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.|
|`signature`|`bytes`|The signature proving that the investor is allowed to participate.|


### releaseTokens

Releases tokens from vesting to the investor address.


```solidity
function releaseTokens() external;
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

### vestingConfiguration

Returns the sale vesting configuration.


```solidity
function vestingConfiguration() external view returns (PreLiquidSaleVestingConfig memory);
```

### investorPositionDetails

Returns an investor position details.


```solidity
function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);
```

## Events
### CapitalInvested
This event is emitted when capital is successfully invested.


```solidity
event CapitalInvested(
    uint256 amount, address investor, uint256 tokenAllocationRate, bytes32 saftHash, uint256 investTimestamp
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`investor`|`address`|The address of the investor.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.|
|`investTimestamp`|`uint256`|The Unix timestamp (seconds) of the block when capital has been invested.|

### ExcessCapitalWithdrawn
This event is emitted when excess capital is successfully withdrawn.


```solidity
event ExcessCapitalWithdrawn(
    uint256 amount, address investor, uint256 tokenAllocationRate, bytes32 saftHash, uint256 investTimestamp
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital withdrawn.|
|`investor`|`address`|The address of the investor.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.|
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
event TgeDetailsPublished(
    address tokenAddress, uint256 totalSupply, uint256 vestingStartTime, uint256 allocatedTokenAmount
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the token distributed to investors.|
|`totalSupply`|`uint256`|The total supply of the token distributed to investors.|
|`vestingStartTime`|`uint256`|The Unix timestamp (seconds) of the block when the vesting starts.|
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

### VestingTermsUpdated
This event is emitted when vesting terms have been successfully updated by the project admin.


```solidity
event VestingTermsUpdated(
    uint256 _vestingDurationSeconds, uint256 _vestingCliffDurationSeconds, uint256 _tokenAllocationOnTGERate
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_vestingDurationSeconds`|`uint256`|The vesting schedule duration for the token sold in seconds.|
|`_vestingCliffDurationSeconds`|`uint256`|The vesting cliff duration for the token sold in seconds.|
|`_tokenAllocationOnTGERate`|`uint256`|The token allocation amount released to investors after TGE in 18 decimals precision.|

### ExcessCapitalRefunded
This event is emitted when excess capital is successfully refunded to the investor.


```solidity
event ExcessCapitalRefunded(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital refunded to the investor.|

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
    uint256 vestingDurationSeconds;
    uint256 vestingCliffDurationSeconds;
    uint256 tokenAllocationOnTGERate;
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
    address vestingFactory;
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

### PreLiquidSaleVestingConfig
A struct describing the pre-liquid sale vesting configuration.


```solidity
struct PreLiquidSaleVestingConfig {
    uint256 vestingStartTime;
    uint256 vestingDurationSeconds;
    uint256 vestingCliffDurationSeconds;
    uint256 tokenAllocationOnTGERate;
}
```

### InvestorPosition
A struct describing the investor position during the sale.


```solidity
struct InvestorPosition {
    uint256 investedCapital;
    uint256 cachedInvestTimestamp;
    uint256 cachedInvestAmount;
    uint256 cachedTokenAllocationRate;
    bytes32 cachedSAFTHash;
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

