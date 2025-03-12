# LegionSealedBidAuctionSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/a0becaf0413338ea78e3b0a0ce4527f7e1695849/src/factories/LegionSealedBidAuctionSaleFactory.sol)

**Inherits:**
[ILegionSealedBidAuctionSaleFactory](/src/interfaces/factories/ILegionSealedBidAuctionSaleFactory.sol/interface.ILegionSealedBidAuctionSaleFactory.md), Ownable

**Author:**
Legion

A factory contract for deploying proxy instances of Legion sealed bid auction sales


## State Variables
### sealedBidAuctionTemplate
*The LegionSealedBidAuctionSale implementation contract*


```solidity
address public immutable sealedBidAuctionTemplate = address(new LegionSealedBidAuctionSale());
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


### createSealedBidAuction

Deploy a LegionSealedBidAuctionSale contract.


```solidity
function createSealedBidAuction(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams
)
    external
    onlyOwner
    returns (address payable sealedBidAuctionInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sealedBidAuctionInstance`|`address payable`|The address of the SealedBidAuction instance deployed.|


