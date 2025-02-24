# LegionAddressRegistry
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/1a165deeea33dfd2b1dca142bf23d06b547c39a3/src/LegionAddressRegistry.sol)

**Inherits:**
[ILegionAddressRegistry](/src/interfaces/ILegionAddressRegistry.sol/interface.ILegionAddressRegistry.md), Ownable

**Author:**
Legion

A contract used to maintain the state of all addresses used in the Legion Protocol


## State Variables
### _legionAddresses
*Mapping of unique identifiers to Legion addresses*


```solidity
mapping(bytes32 => address) private _legionAddresses;
```


## Functions
### constructor

*Constructor to initialize the LegionAddressRegistry*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The owner of the registry contract|


### setLegionAddress

Sets a Legion address for the given identifier


```solidity
function setLegionAddress(bytes32 id, address updatedAddress) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier for the address|
|`updatedAddress`|`address`|The new address to set|


### getLegionAddress

Returns the Legion address for the given identifier


```solidity
function getLegionAddress(bytes32 id) public view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The unique identifier for the address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The registered Legion address|


