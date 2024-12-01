# ILegionAddressRegistry
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/interfaces/ILegionAddressRegistry.sol)


## Functions
### setLegionAddress

Sets a Legion address.


```solidity
function setLegionAddress(bytes32 id, address updatedAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier of the address.|
|`updatedAddress`|`address`|The updated address.|


### getLegionAddress

Gets a Legion address.


```solidity
function getLegionAddress(bytes32 id) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier of the address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The requested address.|


## Events
### LegionAddressSet
This event is emitted when a new Legion address is set or updated.


```solidity
event LegionAddressSet(bytes32 id, address previousAddress, address updatedAddress);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier of the address.|
|`previousAddress`|`address`|The previous address before the update.|
|`updatedAddress`|`address`|The updated address.|

