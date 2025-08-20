# LegionCapitalRaiseFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/factories/LegionCapitalRaiseFactory.sol)

**Inherits:**
[ILegionCapitalRaiseFactory](/src/interfaces/factories/ILegionCapitalRaiseFactory.sol/interface.ILegionCapitalRaiseFactory.md), Ownable

**Author:**
Legion

Deploys proxy instances of Legion capital raise contracts using the clone pattern.

*Creates gas-efficient clones of a single implementation contract for each capital raise campaign.*


## State Variables
### i_capitalRaiseTemplate
The address of the LegionCapitalRaise implementation contract used as a template.

*Immutable reference to the base implementation deployed during construction.*


```solidity
address public immutable i_capitalRaiseTemplate = address(new LegionCapitalRaise());
```


## Functions
### constructor

Constructor for the LegionCapitalRaiseFactory contract.

*Initializes ownership during contract deployment.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to be set as the initial owner of the factory.|


### createCapitalRaise

Deploys a new LegionCapitalRaise contract instance.


```solidity
function createCapitalRaise(LegionCapitalRaise.CapitalRaiseInitializationParams calldata capitalRaiseInitParams)
    external
    onlyOwner
    returns (address payable capitalRaiseInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaiseInitParams`|`LegionCapitalRaise.CapitalRaiseInitializationParams`|The initialization parameters for the capital raise campaign.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaiseInstance`|`address payable`|The address of the newly deployed and initialized LegionCapitalRaise instance.|


