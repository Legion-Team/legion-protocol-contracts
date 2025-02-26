# LegionSealedBidAuctionSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/e045131669c5801ab2e88b13e55002362a64c068/src/factories/LegionSealedBidAuctionSaleFactory.sol)

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
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
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
|`vestingInitParams`|`ILegionSale.LegionVestingInitializationParams`|The vesting initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sealedBidAuctionInstance`|`address payable`|The address of the SealedBidAuction instance deployed.|


