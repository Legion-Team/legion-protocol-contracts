# ILegionPreLiquidSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/interfaces/ILegionPreLiquidSale.sol)


## Functions
### initialize

Initialized the contract with correct parameters.


```solidity
function initialize(
    PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams,
    LegionVestingInitializationParams calldata vestingInitParams
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The pre-liquid sale initialization params.|
|`vestingInitParams`|`LegionVestingInitializationParams`|The vesting initialization params.|


### invest

Invest capital to the pre-liquid sale.


```solidity
function invest(
    uint256 amount,
    uint256 saftInvestAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes32[] calldata proof
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`saftInvestAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the SAFT signed by the investor|
|`proof`|`bytes32[]`|The merkle proof that the investor has signed a SAFT|


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
    address tokenAddress,
    uint256 totalSupply,
    uint256 vestingStartTime,
    uint256 allocatedTokenAmount
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the token distributed to investors|
|`totalSupply`|`uint256`|The total supply of the token distributed to investors|
|`vestingStartTime`|`uint256`|The unix timestamp (seconds) of the block when the vesting starts.|
|`allocatedTokenAmount`|`uint256`|The allocated token amount for distribution to investors.|


### supplyTokens

Supply tokens for distribution after the Token Generation Event (TGE).

*Only callable by the Project.*


```solidity
function supplyTokens(uint256 amount, uint256 legionFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to be supplied for distribution.|
|`legionFee`|`uint256`|The Legion fee token amount.|


### updateSAFTMerkleRoot

Updates the SAFT merkle root.

*Only callable by Legion.*


```solidity
function updateSAFTMerkleRoot(bytes32 merkleRoot) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The merkle root used for investing capital.|


### updateVestingTerms

Updates the vesting terms.

*Only callable by Legion, before the token have been supplied by the Project.*


```solidity
function updateVestingTerms(
    uint256 vestingDurationSeconds,
    uint256 vestingCliffDurationSeconds,
    uint256 tokenAllocationOnTGERate
) external;
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
function withdrawRaisedCapital(address[] calldata investors) external returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investors`|`address[]`|Array of the addresses of the investors' capital which will be withdrawn|


### claimTokenAllocation

Claim token allocation by investors


```solidity
function claimTokenAllocation(bytes32[] calldata proof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proof`|`bytes32[]`|The merkle proof that the investor has signed a SAFT|


### cancelSale

Cancel the sale.

*Can be called only by the Project admin address.*


```solidity
function cancelSale() external;
```

### withdrawInvestedCapitalIfCanceled

Claim back capital from investors if the sale has been canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external;
```

### withdrawExcessInvestedCapital

Withdraw back excess capital from investors.


```solidity
function withdrawExcessInvestedCapital(
    uint256 amount,
    uint256 saftInvestAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes32[] calldata proof
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to be withdrawn.|
|`saftInvestAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the SAFT signed by the investor|
|`proof`|`bytes32[]`|The merkle proof that the investor has signed a SAFT|


### releaseVestedTokens

Releases tokens to the investor address.


```solidity
function releaseVestedTokens() external;
```

### toggleInvestmentAccepted

Toggles the `investmentAccepted` status.


```solidity
function toggleInvestmentAccepted() external;
```

### syncLegionAddresses

Syncs active Legion addresses from `LegionAddressRegistry.sol`


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
function saleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
```

### vestingConfiguration

Returns the vesting configuration.


```solidity
function vestingConfiguration() external view returns (LegionVestingConfiguration memory);
```

### saleStatusDetails

Returns the sale status details.


```solidity
function saleStatusDetails() external view returns (PreLiquidSaleStatus memory);
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
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the SAFT signed by the investor|
|`investTimestamp`|`uint256`|The unix timestamp (seconds) of the block when capital has been invested.|

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
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the SAFT signed by the investor|
|`investTimestamp`|`uint256`|The unix timestamp (seconds) of the block when capital has been invested.|

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
This event is emitted when capital is successfully refunded to the investor after a sale has been canceled.


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

### EmergencyWithdraw
This event is emitted when excess capital results are successfully published by the Legion admin.


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
This event is emitted when excess capital results are successfully published by the Legion admin.


```solidity
event LegionAddressesSynced(address legionBouncer, address legionFeeReceiver, address vestingFactory);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`legionBouncer`|`address`|The updated Legion bouncer address.|
|`legionFeeReceiver`|`address`|The updated fee receiver address of Legion.|
|`vestingFactory`|`address`|The updated vesting factory address.|

### SAFTMerkleRootUpdated
This event is emitted when the SAFT merkle root is updated by the Legion admin.


```solidity
event SAFTMerkleRootUpdated(bytes32 merkleRoot);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The new SAFT merkle root.|

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
|`tokenAddress`|`address`|The address of the token distributed to investors|
|`totalSupply`|`uint256`|The total supply of the token distributed to investors|
|`vestingStartTime`|`uint256`|The unix timestamp (seconds) of the block when the vesting starts.|
|`allocatedTokenAmount`|`uint256`|The allocated token amount for distribution to investors.|

### TokenAllocationClaimed
This event is emitted when tokens are successfully claimed by the investor.


```solidity
event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor, address vesting);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToBeVested`|`uint256`|The amount of tokens distributed to the vesting contract.|
|`amountOnClaim`|`uint256`|The amount of tokens to be deiistributed directly to the investor on claim|
|`investor`|`address`|The address of the investor owning the vesting contract.|
|`vesting`|`address`|The address of the vesting instance deployed.|

### TokensSuppliedForDistribution
This event is emitted when tokens are successfully supplied for distribution by the project admin.


```solidity
event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens supplied for distribution.|
|`legionFee`|`uint256`|The fee amount collected by Legion.|

### VestingTermsUpdated
This event is emitted when tokens are successfully supplied for distribution by the project admin.


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
This event is emitted when excess capital is successfully refunded by the project admin.


```solidity
event ExcessCapitalRefunded(uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital refunded to the sale.|

### ToggleInvestmentAccepted
This event is emitted when `investmentAccepted` status is changed.


```solidity
event ToggleInvestmentAccepted(bool investmentAccepted);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investmentAccepted`|`bool`|Wheter investment is accepted by the Project.|

## Structs
### PreLiquidSaleInitializationParams
A struct describing the pre-liquid sale initialization params.


```solidity
struct PreLiquidSaleInitializationParams {
    bytes32 saftMerkleRoot;
    uint256 refundPeriodSeconds;
    uint256 legionFeeOnCapitalRaisedBps;
    uint256 legionFeeOnTokensSoldBps;
    address bidToken;
    address projectAdmin;
    address addressRegistry;
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

### PreLiquidSaleConfiguration
A struct describing the pre-liquid sale period and fee configuration.


```solidity
struct PreLiquidSaleConfiguration {
    bytes32 saftMerkleRoot;
    uint256 refundPeriodSeconds;
    uint256 legionFeeOnCapitalRaisedBps;
    uint256 legionFeeOnTokensSoldBps;
    address askToken;
    address bidToken;
    address projectAdmin;
    address addressRegistry;
    address legionBouncer;
    address legionFeeReceiver;
}
```

### PreLiquidSaleStatus
A struct describing the pre-liquid sale status.


```solidity
struct PreLiquidSaleStatus {
    uint256 askTokenTotalSupply;
    uint256 totalCapitalInvested;
    uint256 totalTokensAllocated;
    uint256 totalCapitalWithdrawn;
    bool isCanceled;
    bool askTokensSupplied;
    bool investmentAccepted;
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
    uint256 withdrawnCapital;
    uint256 cachedInvestTimestamp;
    uint256 cachedSAFTInvestAmount;
    uint256 cachedTokenAllocationRate;
    bytes32 cachedSAFTHash;
    bool hasSettled;
    address vestingAddress;
}
```

