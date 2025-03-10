# ILegionAddressRegistry
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/1a165deeea33dfd2b1dca142bf23d06b547c39a3/src/interfaces/ILegionAddressRegistry.sol)

An interface for managing Legion Protocol addresses


## Functions
### setLegionAddress

Sets a Legion address


```solidity
function setLegionAddress(bytes32 id, address updatedAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier of the address|
|`updatedAddress`|`address`|The new address to set|


### getLegionAddress

Gets a Legion address


```solidity
function getLegionAddress(bytes32 id) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier of the address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The registered Legion address|


## Events
### LegionAddressSet
Emitted when a Legion address is set or updated


```solidity
event LegionAddressSet(bytes32 id, address previousAddress, address updatedAddress);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier of the address|
|`previousAddress`|`address`|The previous address before the update|
|`updatedAddress`|`address`|The updated address|

