# LegionBouncer
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/access/LegionBouncer.sol)

**Inherits:**
[ILegionBouncer](/src/interfaces/access/ILegionBouncer.sol/interface.ILegionBouncer.md), OwnableRoles

**Author:**
Legion

Provides access control for the Legion Protocol through role-based permissions.

*Implements role-based access control using OwnableRoles to manage broadcaster permissions for executing calls on
target contracts.*


## State Variables
### BROADCASTER_ROLE
The role identifier for broadcaster permissions.

*Used to check permissions for function calls, corresponds to _ROLE_0.*


```solidity
uint256 public constant BROADCASTER_ROLE = _ROLE_0;
```


## Functions
### constructor

Constructor for the Legion Bouncer contract.


```solidity
constructor(address defaultAdmin, address defaultBroadcaster);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`defaultAdmin`|`address`|The address to receive the default admin role.|
|`defaultBroadcaster`|`address`|The address to receive the default broadcaster role.|


### functionCall

Executes a function call on a target contract.


```solidity
function functionCall(address target, bytes memory data) external onlyRoles(BROADCASTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|The address of the contract to call.|
|`data`|`bytes`|The encoded function data to execute on the target contract.|


