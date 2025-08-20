# LegionFixedPriceSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/sales/LegionFixedPriceSale.sol)

**Inherits:**
[LegionAbstractSale](/src/sales/LegionAbstractSale.sol/abstract.LegionAbstractSale.md), [ILegionFixedPriceSale](/src/interfaces/sales/ILegionFixedPriceSale.sol/interface.ILegionFixedPriceSale.md)

**Author:**
Legion

Executes fixed-price sales of ERC20 tokens after Token Generation Event (TGE).

*Inherits from LegionAbstractSale and implements ILegionFixedPriceSale for fixed-price token sales with prefund
periods.*


## State Variables
### s_fixedPriceSaleConfig
*Struct containing the fixed-price sale configuration*


```solidity
FixedPriceSaleConfiguration private s_fixedPriceSaleConfig;
```


## Functions
### whenNotPrefundAllocationPeriod

Restricts interaction to when the prefund allocation period is not active.

*Reverts if the current time is within the prefund allocation period.*


```solidity
modifier whenNotPrefundAllocationPeriod();
```

### initialize

Initializes the contract with sale parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
)
    external
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The common Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`FixedPriceSaleInitializationParams`|The fixed-price sale specific initialization parameters.|


### invest

Allows an investor to contribute capital to the fixed-price sale.


```solidity
function invest(
    uint256 amount,
    bytes calldata signature
)
    external
    whenNotPaused
    whenNotPrefundAllocationPeriod
    whenSaleNotEnded
    whenSaleNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
|`signature`|`bytes`|The Legion signature for investor verification.|


### publishSaleResults

Publishes the sale results after completion.


```solidity
function publishSaleResults(
    bytes32 claimMerkleRoot,
    bytes32 acceptedMerkleRoot,
    uint256 tokensAllocated,
    uint8 askTokenDecimals
)
    external
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenRefundPeriodIsOver;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The Merkle root for verifying token claims.|
|`acceptedMerkleRoot`|`bytes32`|The Merkle root for verifying accepted capital.|
|`tokensAllocated`|`uint256`|The total tokens allocated for distribution.|
|`askTokenDecimals`|`uint8`|The decimals of the ask token for raised capital calculation.|


### fixedPriceSaleConfiguration

Returns the current fixed-price sale configuration.


```solidity
function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`FixedPriceSaleConfiguration`|The complete fixed-price sale configuration struct.|


### _verifyValidParams

*Validates the fixed-price sale initialization parameters.*


```solidity
function _verifyValidParams(FixedPriceSaleInitializationParams calldata _fixedPriceSaleInitParams) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fixedPriceSaleInitParams`|`FixedPriceSaleInitializationParams`|The fixed-price sale initialization parameters to validate.|


### _isPrefund

*Checks if the current time is within the prefund period.*


```solidity
function _isPrefund() private view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if within prefund period, false otherwise.|


### _verifyNotPrefundAllocationPeriod

*Verifies that the current time is not within the prefund allocation period.*


```solidity
function _verifyNotPrefundAllocationPeriod() private view;
```

