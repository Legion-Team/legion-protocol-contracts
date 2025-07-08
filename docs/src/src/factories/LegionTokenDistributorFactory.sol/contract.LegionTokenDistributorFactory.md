# LegionTokenDistributorFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/ee293af08cf63f9bfeacc7adda6146d75c306212/src/factories/LegionTokenDistributorFactory.sol)

**Inherits:**
[ILegionTokenDistributorFactory](/src/interfaces/factories/ILegionTokenDistributorFactory.sol/interface.ILegionTokenDistributorFactory.md), Ownable

**Author:**
Legion

Deploys proxy instances of Legion token distributor contracts using the clone pattern.

*Creates gas-efficient clones of a single implementation contract for each token distributor.*


## State Variables
### i_tokenDistributorTemplate
The address of the LegionTokenDistributor implementation contract used as a template.

*Immutable reference to the base implementation deployed during construction.*


```solidity
address public immutable i_tokenDistributorTemplate = address(new LegionTokenDistributor());
```


## Functions
### constructor

Constructor for the LegionTokenDistributorFactory contract.

*Initializes ownership during contract deployment.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to be set as the initial owner of the factory.|


### createTokenDistributor

Deploys a new LegionTokenDistributor contract instance.


```solidity
function createTokenDistributor(
    ILegionTokenDistributor.TokenDistributorInitializationParams calldata distributorInitParams
)
    external
    onlyOwner
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


