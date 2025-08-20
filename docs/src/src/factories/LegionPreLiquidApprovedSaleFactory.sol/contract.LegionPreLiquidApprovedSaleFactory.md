# LegionPreLiquidApprovedSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/factories/LegionPreLiquidApprovedSaleFactory.sol)

**Inherits:**
[ILegionPreLiquidApprovedSaleFactory](/src/interfaces/factories/ILegionPreLiquidApprovedSaleFactory.sol/interface.ILegionPreLiquidApprovedSaleFactory.md), Ownable

**Author:**
Legion

Deploys proxy instances of Legion pre-liquid approved sale contracts using the clone pattern.

*Creates gas-efficient clones of a single implementation contract for each pre-liquid approved sale.*


## State Variables
### i_preLiquidApprovedSaleTemplate
The address of the LegionPreLiquidApprovedSale implementation contract used as a template.

*Immutable reference to the base implementation deployed during construction.*


```solidity
address public immutable i_preLiquidApprovedSaleTemplate = address(new LegionPreLiquidApprovedSale());
```


## Functions
### constructor

Constructor for the LegionPreLiquidApprovedSaleFactory contract.

*Initializes ownership during contract deployment.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to be set as the initial owner of the factory.|


### createPreLiquidApprovedSale

Deploys a new LegionPreLiquidApprovedSale contract instance.


```solidity
function createPreLiquidApprovedSale(
    LegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
)
    external
    onlyOwner
    returns (address payable preLiquidApprovedSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`LegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams`|The initialization parameters for the pre-liquid approved sale.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidApprovedSaleInstance`|`address payable`|The address of the newly deployed and initialized LegionPreLiquidApprovedSale instance.|


