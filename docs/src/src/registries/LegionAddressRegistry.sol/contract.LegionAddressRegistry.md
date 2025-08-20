# LegionAddressRegistry
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/registries/LegionAddressRegistry.sol)

**Inherits:**
[ILegionAddressRegistry](/src/interfaces/registries/ILegionAddressRegistry.sol/interface.ILegionAddressRegistry.md), Ownable

**Author:**
Legion

Maintains a registry of all addresses used in the Legion Protocol.

*Provides a centralized mapping of unique identifiers to addresses for the Legion ecosystem.*


## State Variables
### s_legionAddresses
*Mapping of unique identifiers to their corresponding Legion addresses.*


```solidity
mapping(bytes32 => address) private s_legionAddresses;
```


## Functions
### constructor

*@notice Constructor for the LegionAddressRegistry contract.*

*@dev Initializes ownership during contract deployment.*

*@param newOwner The address to be set as the initial owner of the registry.*


```solidity
constructor(address newOwner);
```

### setLegionAddress

Sets a Legion address for a given identifier.


```solidity
function setLegionAddress(bytes32 id, address updatedAddress) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier for the address.|
|`updatedAddress`|`address`|The new address to associate with the identifier.|


### getLegionAddress

Retrieves the Legion address associated with a given identifier.


```solidity
function getLegionAddress(bytes32 id) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier for the address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The registered Legion address associated with the identifier.|


