# ILegionFixedPriceSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/sales/ILegionFixedPriceSale.sol)

**Inherits:**
[ILegionAbstractSale](/src/interfaces/sales/ILegionAbstractSale.sol/interface.ILegionAbstractSale.md)

**Author:**
Legion

Interface for the LegionFixedPriceSale contract.


## Functions
### initialize

Initializes the contract with sale parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The common Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`FixedPriceSaleInitializationParams`|The fixed-price sale specific initialization parameters.|


### invest

Allows an investor to contribute capital to the fixed-price sale.


```solidity
function invest(uint256 amount, bytes calldata signature) external;
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
    external;
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


## Events
### CapitalInvested
Emitted when capital is successfully invested in the sale.


```solidity
event CapitalInvested(uint256 amount, address investor, bool isPrefund, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested (in bid tokens).|
|`investor`|`address`|The address of the investor.|
|`isPrefund`|`bool`|Indicates if investment occurred before sale start.|
|`positionId`|`uint256`|The unique identifier for the investment position.|

### SaleResultsPublished
Emitted when sale results are published by the Legion admin.


```solidity
event SaleResultsPublished(bytes32 claimMerkleRoot, bytes32 acceptedMerkleRoot, uint256 tokensAllocated);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The Merkle root for verifying token claims.|
|`acceptedMerkleRoot`|`bytes32`|The Merkle root for verifying accepted capital.|
|`tokensAllocated`|`uint256`|The total amount of tokens allocated from the sale.|

## Structs
### FixedPriceSaleInitializationParams
*Struct defining the initialization parameters for a fixed-price sale*


```solidity
struct FixedPriceSaleInitializationParams {
    uint64 prefundPeriodSeconds;
    uint64 prefundAllocationPeriodSeconds;
    uint256 tokenPrice;
}
```

### FixedPriceSaleConfiguration
*Struct containing the runtime configuration of the fixed-price sale*


```solidity
struct FixedPriceSaleConfiguration {
    uint64 prefundStartTime;
    uint64 prefundEndTime;
    uint256 tokenPrice;
}
```

