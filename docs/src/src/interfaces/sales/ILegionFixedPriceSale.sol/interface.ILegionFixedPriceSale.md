# ILegionFixedPriceSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/interfaces/sales/ILegionFixedPriceSale.sol)

**Inherits:**
[ILegionSale](/src/interfaces/sales/ILegionSale.sol/interface.ILegionSale.md)


## Functions
### initialize

Initializes the contract with correct parameters.


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
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|


### invest

Invest capital to the fixed price sale.


```solidity
function invest(uint256 amount, bytes memory signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`signature`|`bytes`|The Legion signature for verification.|


### publishSaleResults

Publish sale results, once the sale has concluded.

*Can be called only by the Legion admin address.*


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
|`claimMerkleRoot`|`bytes32`|The merkle root to verify token claims.|
|`acceptedMerkleRoot`|`bytes32`|The merkle root to verify accepted capital.|
|`tokensAllocated`|`uint256`|The total amount of tokens allocated for distribution among investors.|
|`askTokenDecimals`|`uint8`|The decimals number of the ask token.|


### fixedPriceSaleConfiguration

Returns the fixed price sale configuration.


```solidity
function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory);
```

## Events
### CapitalInvested
This event is emitted when capital is successfully invested.


```solidity
event CapitalInvested(uint256 amount, address investor, bool isPrefund, uint256 investTimestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`investor`|`address`|The address of the investor.|
|`isPrefund`|`bool`|Whether capital is invested before sale start.|
|`investTimestamp`|`uint256`|The unix timestamp (seconds) of the block when capital has been invested.|

### SaleResultsPublished
This event is emitted when sale results are successfully published by the Legion admin.


```solidity
event SaleResultsPublished(bytes32 claimMerkleRoot, bytes32 acceptedMerkleRoot, uint256 tokensAllocated);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The merkle root to verify token claims.|
|`acceptedMerkleRoot`|`bytes32`|The merkle root to verify accepted capital.|
|`tokensAllocated`|`uint256`|The amount of tokens allocated from the sale.|

## Structs
### FixedPriceSaleInitializationParams
A struct describing the fixed price sale initialization params.


```solidity
struct FixedPriceSaleInitializationParams {
    uint256 prefundPeriodSeconds;
    uint256 prefundAllocationPeriodSeconds;
    uint256 tokenPrice;
}
```

### FixedPriceSaleConfiguration
A struct describing the fixed price sale configuration.


```solidity
struct FixedPriceSaleConfiguration {
    uint256 tokenPrice;
    uint256 prefundStartTime;
    uint256 prefundEndTime;
}
```

