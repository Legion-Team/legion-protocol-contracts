# LegionSealedVestingSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/factories/LegionSealedVestingSaleFactory.sol)

**Inherits:**
[ILegionSealedVestingSaleFactory](/src/interfaces/factories/ILegionSealedVestingSaleFactory.sol/interface.ILegionSealedVestingSaleFactory.md), Ownable

**Author:**
Legion

Deploys proxy instances of Legion pre-liquid open application sale contracts using the clone pattern.

*Creates gas-efficient clones of a single implementation contract for each pre-liquid open application sale.*


## State Variables
### i_sealedVestingOpenApplicationSaleTemplate
The address of the LegionSealedVestingSale implementation contract used as a template.

*Immutable reference to the base implementation deployed during construction.*


```solidity
address public immutable i_sealedVestingOpenApplicationSaleTemplate = address(new LegionSealedVestingSale());
```


## Functions
### constructor

Constructor for the LegionPreLiquidSaleFactory contract.

*Initializes ownership during contract deployment.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to be set as the initial owner of the factory.|


### createSealedVestingOpenApplicationSale

Deploys a new LegionSealedVestingSale contract instance.


```solidity
function createSealedVestingOpenApplicationSale(
    ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedVestingSale.PreLiquidSaleInitializationParams calldata sealedVestingOpenApplicationSaleInitParams
)
    external
    onlyOwner
    returns (address payable sealedVestingOpenApplicationSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedVestingOpenApplicationSaleInitParams`|`ILegionSealedVestingSale.PreLiquidSaleInitializationParams`|The sealed-vesting pre-liquid open application sale specific initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sealedVestingOpenApplicationSaleInstance`|`address payable`|The address of the newly deployed and initialized LegionSealedVestingSale instance.|


