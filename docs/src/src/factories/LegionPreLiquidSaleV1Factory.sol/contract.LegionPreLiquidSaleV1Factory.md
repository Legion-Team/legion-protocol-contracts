# LegionPreLiquidSaleV1Factory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/e045131669c5801ab2e88b13e55002362a64c068/src/factories/LegionPreLiquidSaleV1Factory.sol)

**Inherits:**
[ILegionPreLiquidSaleV1Factory](/src/interfaces/factories/ILegionPreLiquidSaleV1Factory.sol/interface.ILegionPreLiquidSaleV1Factory.md), Ownable

**Author:**
Legion

A factory contract for deploying proxy instances of Legion pre-liquid V1 sales


## State Variables
### preLiquidSaleV1Template
*The LegionPreLiquidSaleV1 implementation contract*


```solidity
address public immutable preLiquidSaleV1Template = address(new LegionPreLiquidSaleV1());
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


### createPreLiquidSaleV1

Deploy a LegionPreLiquidSaleV1 contract.


```solidity
function createPreLiquidSaleV1(LegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams)
    external
    onlyOwner
    returns (address payable preLiquidSaleV1Instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`LegionPreLiquidSaleV1.PreLiquidSaleInitializationParams`|The Pre-Liquid sale initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleV1Instance`|`address payable`|The address of the PreLiquidSale V1 instance deployed.|


