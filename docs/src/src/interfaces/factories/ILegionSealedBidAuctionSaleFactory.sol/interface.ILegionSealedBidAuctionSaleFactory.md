# ILegionSealedBidAuctionSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/1a165deeea33dfd2b1dca142bf23d06b547c39a3/src/interfaces/factories/ILegionSealedBidAuctionSaleFactory.sol)


## Functions
### createSealedBidAuction

Deploy a LegionSealedBidAuctionSale contract.


```solidity
function createSealedBidAuction(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
)
    external
    returns (address payable sealedBidAuctionInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters.|
|`vestingInitParams`|`ILegionSale.LegionVestingInitializationParams`|The vesting initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sealedBidAuctionInstance`|`address payable`|The address of the SealedBidAuction instance deployed.|


## Events
### NewSealedBidAuctionCreated
This event is emitted when a new sealed bid auction is deployed and initialized.


```solidity
event NewSealedBidAuctionCreated(
    address saleInstance,
    ILegionSale.LegionSaleInitializationParams saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams,
    ILegionSale.LegionVestingInitializationParams vestingInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the sale instance deployed.|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters.|
|`vestingInitParams`|`ILegionSale.LegionVestingInitializationParams`|The vesting initialization parameters.|

