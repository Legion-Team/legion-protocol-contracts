# ILegionCapitalRaiseFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/8b23239dfc702a4510efb5dd06fb67719eb5eab0/src/interfaces/factories/ILegionCapitalRaiseFactory.sol)

**Author:**
Legion

Interface for the LegionCapitalRaiseFactory contract.


## Functions
### createCapitalRaise

Deploys a new LegionCapitalRaise contract instance.


```solidity
function createCapitalRaise(ILegionCapitalRaise.CapitalRaiseInitializationParams calldata capitalRaiseInitParams)
    external
    returns (address payable capitalRaiseInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaiseInitParams`|`ILegionCapitalRaise.CapitalRaiseInitializationParams`|The initialization parameters for the capital raise campaign.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaiseInstance`|`address payable`|The address of the newly deployed and initialized LegionCapitalRaise instance.|


## Events
### NewCapitalRaiseCreated
Emitted when a new capital raise contract is deployed and initialized


```solidity
event NewCapitalRaiseCreated(
    address capitalRaiseInstance, ILegionCapitalRaise.CapitalRaiseInitializationParams capitalRaiseInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaiseInstance`|`address`|Address of the newly deployed capital raise contract|
|`capitalRaiseInitParams`|`ILegionCapitalRaise.CapitalRaiseInitializationParams`|Struct containing capital raise initialization parameters|

