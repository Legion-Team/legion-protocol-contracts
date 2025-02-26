# LegionFixedPriceSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/e045131669c5801ab2e88b13e55002362a64c068/src/factories/LegionFixedPriceSaleFactory.sol)

**Inherits:**
[ILegionFixedPriceSaleFactory](/src/interfaces/factories/ILegionFixedPriceSaleFactory.sol/interface.ILegionFixedPriceSaleFactory.md), Ownable

**Author:**
Legion

A factory contract for deploying proxy instances of Legion fixed price sales


## State Variables
### fixedPriceSaleTemplate
*The LegionFixedPriceSale implementation contract*


```solidity
address public immutable fixedPriceSaleTemplate = address(new LegionFixedPriceSale());
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


### createFixedPriceSale

Deploy a LegionFixedPriceSale contract.


```solidity
function createFixedPriceSale(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory fixedPriceSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
)
    external
    onlyOwner
    returns (address payable fixedPriceSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`ILegionFixedPriceSale.FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|
|`vestingInitParams`|`ILegionSale.LegionVestingInitializationParams`|The vesting initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fixedPriceSaleInstance`|`address payable`|The address of the FixedPriceSale instance deployed.|


