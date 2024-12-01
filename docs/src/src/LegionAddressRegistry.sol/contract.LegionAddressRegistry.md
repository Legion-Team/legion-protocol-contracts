# LegionAddressRegistry
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionAddressRegistry.sol)

**Inherits:**
[ILegionAddressRegistry](/src/interfaces/ILegionAddressRegistry.sol/interface.ILegionAddressRegistry.md), Ownable

**Author:**
Legion.

A contract used to keep state of all addresses used in the Legion Protocol.


## State Variables
### _legionAddresses
*Mapping of unique identifier to a Legion address.*


```solidity
mapping(bytes32 => address) private _legionAddresses;
```


## Functions
### constructor

*Constructor to initialize the LegionAddressRegistry.*


```solidity
constructor(address newOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The owner of the registry contract.|


### setLegionAddress

See [ILegionAddressRegistry-setLegionAddress](/src/interfaces/ILegionAddressRegistry.sol/interface.ILegionAddressRegistry.md#setlegionaddress).


```solidity
function setLegionAddress(bytes32 id, address updatedAddress) external onlyOwner;
```

### getLegionAddress

See [ILegionAddressRegistry-getLegionAddress](/src/interfaces/ILegionAddressRegistry.sol/interface.ILegionAddressRegistry.md#getlegionaddress).


```solidity
function getLegionAddress(bytes32 id) public view returns (address);
```

