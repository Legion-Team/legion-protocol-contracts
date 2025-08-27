# ILegionAddressRegistry
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/registries/ILegionAddressRegistry.sol)

**Author:**
Legion

Interface for the LegionAddressRegistry contract.


## Functions
### setLegionAddress

Sets a Legion address for a given identifier.


```solidity
function setLegionAddress(bytes32 id, address updatedAddress) external;
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


## Events
### LegionAddressSet
Emitted when a Legion address is set or updated.


```solidity
event LegionAddressSet(bytes32 id, address previousAddress, address updatedAddress);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier (bytes32) of the address.|
|`previousAddress`|`address`|The address previously associated with the identifier.|
|`updatedAddress`|`address`|The new address associated with the identifier.|

