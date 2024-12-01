# LegionSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionSaleFactory.sol)

**Inherits:**
[ILegionSaleFactory](/src/interfaces/ILegionSaleFactory.sol/interface.ILegionSaleFactory.md), Ownable

**Author:**
Legion.

A factory contract for deploying proxy instances of Legion sales.


## State Variables
### fixedPriceSaleTemplate
*The LegionFixedPriceSale implementation contract.*


```solidity
address public immutable fixedPriceSaleTemplate = address(new LegionFixedPriceSale());
```


### preLiquidSaleTemplate
*The LegionPreLiquidSale implementation contract.*


```solidity
address public immutable preLiquidSaleTemplate = address(new LegionPreLiquidSale());
```


### sealedBidAuctionTemplate
*The LegionSealedBidAuctionSale implementation contract.*


```solidity
address public immutable sealedBidAuctionTemplate = address(new LegionSealedBidAuctionSale());
```


## Functions
### constructor

*Constructor to initialize the LegionSaleFactory.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The owner of the factory contract.|


### createFixedPriceSale

See [ILegionSaleFactory-createFixedPriceSale](/src/interfaces/ILegionSaleFactory.sol/interface.ILegionSaleFactory.md#createfixedpricesale).


```solidity
function createFixedPriceSale(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory fixedPriceSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
) external onlyOwner returns (address payable fixedPriceSaleInstance);
```

### createPreLiquidSale

See [ILegionSaleFactory-createPreLiquidSale](/src/interfaces/ILegionSaleFactory.sol/interface.ILegionSaleFactory.md#createpreliquidsale).


```solidity
function createPreLiquidSale(
    ILegionPreLiquidSale.PreLiquidSaleInitializationParams memory preLiquidSaleInitParams,
    ILegionPreLiquidSale.LegionVestingInitializationParams memory vestingInitParams
) external onlyOwner returns (address payable preLiquidSaleInstance);
```

### createSealedBidAuction

See [ILegionSaleFactory-createSealedBidAuction](/src/interfaces/ILegionSaleFactory.sol/interface.ILegionSaleFactory.md#createsealedbidauction).


```solidity
function createSealedBidAuction(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
) external onlyOwner returns (address payable sealedBidAuctionInstance);
```

