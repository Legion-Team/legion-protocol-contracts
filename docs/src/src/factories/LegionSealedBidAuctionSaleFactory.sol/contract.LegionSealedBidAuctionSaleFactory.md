# LegionSealedBidAuctionSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/factories/LegionSealedBidAuctionSaleFactory.sol)

**Inherits:**
[ILegionSealedBidAuctionSaleFactory](/src/interfaces/factories/ILegionSealedBidAuctionSaleFactory.sol/interface.ILegionSealedBidAuctionSaleFactory.md), Ownable

**Author:**
Legion

Deploys proxy instances of Legion sealed bid auction sale contracts using the clone pattern.

*Creates gas-efficient clones of a single implementation contract for each sealed bid auction sale.*


## State Variables
### i_sealedBidAuctionTemplate
The address of the LegionSealedBidAuctionSale implementation contract used as a template.

*Immutable reference to the base implementation deployed during construction.*


```solidity
address public immutable i_sealedBidAuctionTemplate = address(new LegionSealedBidAuctionSale());
```


## Functions
### constructor

Constructor for the LegionSealedBidAuctionSaleFactory contract.

*Initializes ownership during contract deployment.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to be set as the initial owner of the factory.|


### createSealedBidAuctionSale

Deploys a new LegionSealedBidAuctionSale contract instance.


```solidity
function createSealedBidAuctionSale(
    ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams
)
    external
    onlyOwner
    returns (address payable sealedBidAuctionInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The general Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sealedBidAuctionInstance`|`address payable`|The address of the newly deployed and initialized LegionSealedBidAuctionSale instance.|


