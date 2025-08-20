# ILegionTokenDistributorFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/factories/ILegionTokenDistributorFactory.sol)

**Author:**
Legion

Interface for the LegionTokenDistributorFactory contract.

*Provides factory functionality for deploying and initializing token distributor contracts.*


## Functions
### createTokenDistributor

Deploys a new LegionTokenDistributor contract instance.


```solidity
function createTokenDistributor(
    ILegionTokenDistributor.TokenDistributorInitializationParams calldata distributorInitParams
)
    external
    returns (address payable distributorInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`distributorInitParams`|`ILegionTokenDistributor.TokenDistributorInitializationParams`|The Legion Token Distributor initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`distributorInstance`|`address payable`|The address of the newly deployed LegionTokenDistributor instance.|


## Events
### NewTokenDistributorCreated
Emitted when a new token distributor contract is deployed and initialized.


```solidity
event NewTokenDistributorCreated(
    address distributorInstance, ILegionTokenDistributor.TokenDistributorInitializationParams distributorInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`distributorInstance`|`address`|The address of the newly deployed token distributor contract.|
|`distributorInitParams`|`ILegionTokenDistributor.TokenDistributorInitializationParams`|The Legion Token Distributor initialization parameters used.|

