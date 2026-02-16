# LegionSealedBidSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/factories/LegionSealedBidSaleFactory.sol)

**Inherits:**
[ILegionSealedBidSaleFactory](/src/interfaces/factories/ILegionSealedBidSaleFactory.sol/interface.ILegionSealedBidSaleFactory.md), Ownable

**Author:**
Legion

Deploys proxy instances of Legion sealed bid  sale contracts using the clone pattern.

*Creates gas-efficient clones of a single implementation contract for each sealed bid  sale.*


## State Variables
### i_sealedBidSaleTemplate
The address of the LegionSealedBidSale implementation contract used as a template.

*Immutable reference to the base implementation deployed during construction.*


```solidity
address public immutable i_sealedBidSaleTemplate = address(new LegionSealedBidSale());
```


## Functions
### constructor

Constructor for the LegionSealedBidSaleFactory contract.

*Initializes ownership during contract deployment.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to be set as the initial owner of the factory.|


### createSealedBidSale

Deploys a new LegionSealedBidSale contract instance.


```solidity
function createSealedBidSale(
    ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
    ILegionSealedBidSale.SealedBidSaleInitializationParams calldata sealedBidSaleInitParams
)
    external
    onlyOwner
    returns (address payable sealedBidSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The general Legion sale initialization parameters.|
|`sealedBidSaleInitParams`|`ILegionSealedBidSale.SealedBidSaleInitializationParams`|The sealed bid sale specific initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sealedBidSaleInstance`|`address payable`|The address of the newly deployed and initialized LegionSealedBidSale instance.|


