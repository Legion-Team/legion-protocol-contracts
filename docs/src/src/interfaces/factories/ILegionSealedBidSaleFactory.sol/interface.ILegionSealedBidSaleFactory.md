# ILegionSealedBidSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/interfaces/factories/ILegionSealedBidSaleFactory.sol)

**Author:**
Legion

Interface for the LegionSealedBidSaleFactory contract.


## Functions
### createSealedBidSale

Deploys a new LegionSealedBidSale contract instance.


```solidity
function createSealedBidSale(
    ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedBidSale.SealedBidSaleInitializationParams memory sealedBidSaleInitParams
)
    external
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


## Events
### NewSealedBidSaleCreated
Emitted when a new sealed bid sale contract is deployed and initialized.


```solidity
event NewSealedBidSaleCreated(
    address saleInstance,
    ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
    ILegionSealedBidSale.SealedBidSaleInitializationParams sealedBidSaleInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the newly deployed sealed bid sale contract.|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The Legion sale initialization parameters used.|
|`sealedBidSaleInitParams`|`ILegionSealedBidSale.SealedBidSaleInitializationParams`|The sealed bid sale specific initialization parameters used.|

