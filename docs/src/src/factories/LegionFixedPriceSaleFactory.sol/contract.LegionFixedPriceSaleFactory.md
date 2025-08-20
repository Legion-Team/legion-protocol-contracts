# LegionFixedPriceSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/factories/LegionFixedPriceSaleFactory.sol)

**Inherits:**
[ILegionFixedPriceSaleFactory](/src/interfaces/factories/ILegionFixedPriceSaleFactory.sol/interface.ILegionFixedPriceSaleFactory.md), Ownable

**Author:**
Legion

Deploys proxy instances of Legion fixed price sale contracts using the clone pattern.

*Creates gas-efficient clones of a single implementation contract for each fixed price sale.*


## State Variables
### i_fixedPriceSaleTemplate
The address of the LegionFixedPriceSale implementation contract used as a template.

*Immutable reference to the base implementation deployed during construction.*


```solidity
address public immutable i_fixedPriceSaleTemplate = address(new LegionFixedPriceSale());
```


## Functions
### constructor

Constructor for the LegionFixedPriceSaleFactory contract.

*Initializes ownership during contract deployment.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to be set as the initial owner of the factory.|


### createFixedPriceSale

Deploys a new LegionFixedPriceSale contract instance.


```solidity
function createFixedPriceSale(
    ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
)
    external
    onlyOwner
    returns (address payable fixedPriceSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The general Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`ILegionFixedPriceSale.FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fixedPriceSaleInstance`|`address payable`|The address of the newly deployed and initialized LegionFixedPriceSale instance.|


