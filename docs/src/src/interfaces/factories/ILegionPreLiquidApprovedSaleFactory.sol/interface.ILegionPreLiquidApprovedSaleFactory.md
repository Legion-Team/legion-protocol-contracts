# ILegionPreLiquidApprovedSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/factories/ILegionPreLiquidApprovedSaleFactory.sol)

**Author:**
Legion

Interface for the LegionPreLiquidApprovedSaleFactory contract.


## Functions
### createPreLiquidApprovedSale

Deploys a new LegionPreLiquidApprovedSale contract instance.


```solidity
function createPreLiquidApprovedSale(
    ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
)
    external
    returns (address payable preLiquidApprovedSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams`|The initialization parameters for the pre-liquid approved sale.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidApprovedSaleInstance`|`address payable`|The address of the newly deployed and initialized LegionPreLiquidApprovedSale instance.|


## Events
### NewPreLiquidApprovedSaleCreated
Emitted when a new pre-liquid approved sale contract is deployed and initialized.


```solidity
event NewPreLiquidApprovedSaleCreated(
    address saleInstance, ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams preLiquidSaleInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the newly deployed pre-liquid approved sale contract.|
|`preLiquidSaleInitParams`|`ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams`|The pre-liquid sale initialization parameters used.|

