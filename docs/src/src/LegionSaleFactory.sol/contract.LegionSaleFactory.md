# LegionSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/ac3edaa080a44c4acca1531370a76a05f05491f5/src/LegionSaleFactory.sol)

**Inherits:**
[ILegionSaleFactory](/src/interfaces/ILegionSaleFactory.sol/interface.ILegionSaleFactory.md), Ownable

**Author:**
Legion

A factory contract for deploying proxy instances of Legion sales


## State Variables
### fixedPriceSaleTemplate
*The LegionFixedPriceSale implementation contract*


```solidity
address public immutable fixedPriceSaleTemplate = address(new LegionFixedPriceSale());
```


### preLiquidSaleV1Template
*The LegionPreLiquidSaleV1 implementation contract*


```solidity
address public immutable preLiquidSaleV1Template = address(new LegionPreLiquidSaleV1());
```


### preLiquidSaleV2Template
*The LegionPreLiquidSaleV2 implementation contract*


```solidity
address public immutable preLiquidSaleV2Template = address(new LegionPreLiquidSaleV2());
```


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


### createPreLiquidSaleV1

Deploy a LegionPreLiquidSaleV1 contract.


```solidity
function createPreLiquidSaleV1(LegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams)
    external
    onlyOwner
    returns (address payable preLiquidSaleV1Instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`LegionPreLiquidSaleV1.PreLiquidSaleInitializationParams`|The Pre-Liquid sale initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleV1Instance`|`address payable`|The address of the PreLiquidSale V1 instance deployed.|


### createPreLiquidSaleV2

Deploy a LegionPreLiquidSaleV2 contract.


```solidity
function createPreLiquidSaleV2(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionPreLiquidSaleV2.LegionVestingInitializationParams memory vestingInitParams
)
    external
    onlyOwner
    returns (address payable preLiquidSaleV2Instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`vestingInitParams`|`ILegionPreLiquidSaleV2.LegionVestingInitializationParams`|The vesting initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleV2Instance`|`address payable`|The address of the preLiquidSaleV2Instance deployed.|


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


