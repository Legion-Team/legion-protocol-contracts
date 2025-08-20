# LegionPreLiquidOpenApplicationSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/factories/LegionPreLiquidOpenApplicationSaleFactory.sol)

**Inherits:**
[ILegionPreLiquidOpenApplicationSaleFactory](/src/interfaces/factories/ILegionPreLiquidOpenApplicationSaleFactory.sol/interface.ILegionPreLiquidOpenApplicationSaleFactory.md), Ownable

**Author:**
Legion

Deploys proxy instances of Legion pre-liquid open application sale contracts using the clone pattern.

*Creates gas-efficient clones of a single implementation contract for each pre-liquid open application sale.*


## State Variables
### i_preLiquidOpenApplicationSaleTemplate
The address of the LegionPreLiquidOpenApplicationSale implementation contract used as a template.

*Immutable reference to the base implementation deployed during construction.*


```solidity
address public immutable i_preLiquidOpenApplicationSaleTemplate = address(new LegionPreLiquidOpenApplicationSale());
```


## Functions
### constructor

Constructor for the LegionPreLiquidOpenApplicationSaleFactory contract.

*Initializes ownership during contract deployment.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to be set as the initial owner of the factory.|


### createPreLiquidOpenApplicationSale

Deploys a new LegionPreLiquidOpenApplicationSale contract instance.


```solidity
function createPreLiquidOpenApplicationSale(ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams)
    external
    onlyOwner
    returns (address payable preLiquidOpenApplicationSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidOpenApplicationSaleInstance`|`address payable`|The address of the newly deployed and initialized LegionPreLiquidOpenApplicationSale instance.|


