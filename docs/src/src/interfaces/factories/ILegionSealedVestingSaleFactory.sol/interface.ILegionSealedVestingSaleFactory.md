# ILegionSealedVestingSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/interfaces/factories/ILegionSealedVestingSaleFactory.sol)

**Author:**
Legion

Interface for the Legion LegionSealedVestingSaleFactory contract.


## Functions
### createSealedVestingOpenApplicationSale

Deploys a new LegionSealedVestingSale contract instance.


```solidity
function createSealedVestingOpenApplicationSale(
    ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedVestingSale.PreLiquidSaleInitializationParams memory sealedVestingOpenApplicationSaleInitParams
)
    external
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


## Events
### NewSealedVestingOpenApplicationSaleCreated
Emitted when a new sealed-vesting pre-liquid open application sale contract is deployed and initialized.


```solidity
event NewSealedVestingOpenApplicationSaleCreated(
    address saleInstance,
    ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
    ILegionSealedVestingSale.PreLiquidSaleInitializationParams sealedVestingOpenApplicationSaleInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the newly deployed sealed-vesting pre-liquid open application sale contract.|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The Legion sale initialization parameters used.|
|`sealedVestingOpenApplicationSaleInitParams`|`ILegionSealedVestingSale.PreLiquidSaleInitializationParams`|The sealed-vesting pre-liquid open application sale specific|

