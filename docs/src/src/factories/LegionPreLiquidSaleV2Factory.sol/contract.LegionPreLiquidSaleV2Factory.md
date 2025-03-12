# LegionPreLiquidSaleV2Factory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/a0becaf0413338ea78e3b0a0ce4527f7e1695849/src/factories/LegionPreLiquidSaleV2Factory.sol)

**Inherits:**
[ILegionPreLiquidSaleV2Factory](/src/interfaces/factories/ILegionPreLiquidSaleV2Factory.sol/interface.ILegionPreLiquidSaleV2Factory.md), Ownable

**Author:**
Legion

A factory contract for deploying proxy instances of Legion pre-liquid V2 sales


## State Variables
### preLiquidSaleV2Template
*The LegionPreLiquidSaleV2 implementation contract*


```solidity
address public immutable preLiquidSaleV2Template = address(new LegionPreLiquidSaleV2());
```


## Functions
### constructor

*Constructor to initialize the LegionSaleFactory*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The owner of the factory contract|


### createPreLiquidSaleV2

Deploy a LegionPreLiquidSaleV2 contract.


```solidity
function createPreLiquidSaleV2(ILegionSale.LegionSaleInitializationParams memory saleInitParams)
    external
    onlyOwner
    returns (address payable preLiquidSaleV2Instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleV2Instance`|`address payable`|The address of the preLiquidSaleV2Instance deployed.|


