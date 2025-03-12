# LegionFixedPriceSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/sales/LegionFixedPriceSale.sol)

**Inherits:**
[LegionSale](/src/sales/LegionSale.sol/abstract.LegionSale.md), [ILegionFixedPriceSale](/src/interfaces/sales/ILegionFixedPriceSale.sol/interface.ILegionFixedPriceSale.md)

**Author:**
Legion

A contract used to execute fixed-price sales of ERC20 tokens after TGE


## State Variables
### fixedPriceSaleConfig
*A struct describing the fixed-price sale configuration*


```solidity
FixedPriceSaleConfiguration private fixedPriceSaleConfig;
```


## Functions
### initialize

Initializes the contract with correct parameters.


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
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|


### invest

Invest capital to the fixed price sale.


```solidity
function invest(uint256 amount, bytes memory signature) external whenNotPaused;
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
    external
    onlyLegion;
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

### _isPrefund

Verify whether the prefund period is active (before sale startTime)


```solidity
function _isPrefund() private view returns (bool);
```

### _verifyNotPrefundAllocationPeriod

Verify whether the prefund allocation period is active (after prefundEndTime and before sale startTime)


```solidity
function _verifyNotPrefundAllocationPeriod() private view;
```

### _verifyValidParams

Verify whether the sale initialization parameters are valid


```solidity
function _verifyValidParams(FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams) private pure;
```

