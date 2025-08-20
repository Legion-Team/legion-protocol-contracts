# ILegionSealedBidAuctionSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/factories/ILegionSealedBidAuctionSaleFactory.sol)

**Author:**
Legion

Interface for the LegionSealedBidAuctionSaleFactory contract.


## Functions
### createSealedBidAuctionSale

Deploys a new LegionSealedBidAuctionSale contract instance.


```solidity
function createSealedBidAuctionSale(
    ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams
)
    external
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


## Events
### NewSealedBidAuctionSaleCreated
Emitted when a new sealed bid auction sale contract is deployed and initialized.


```solidity
event NewSealedBidAuctionSaleCreated(
    address saleInstance,
    ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the newly deployed sealed bid auction sale contract.|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The Legion sale initialization parameters used.|
|`sealedBidAuctionSaleInitParams`|`ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters used.|

