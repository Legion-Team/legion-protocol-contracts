# LegionBouncer
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/a0becaf0413338ea78e3b0a0ce4527f7e1695849/src/LegionBouncer.sol)

**Inherits:**
[ILegionBouncer](/src/interfaces/ILegionBouncer.sol/interface.ILegionBouncer.md), OwnableRoles

**Author:**
Legion

A contract used to maintain access control for the Legion Protocol


## State Variables
### BROADCASTER_ROLE
*Constant representing the broadcaster role*


```solidity
uint256 public constant BROADCASTER_ROLE = _ROLE_0;
```


## Functions
### constructor

*Constructor to initialize the Legion Bouncer contract*


```solidity
constructor(address defaultAdmin, address defaultBroadcaster);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`defaultAdmin`|`address`|The address that will have the default admin role|
|`defaultBroadcaster`|`address`|The address that will have the default broadcaster role|


### functionCall

Executes a function call on a target contract

*Only callable by addresses with the BROADCASTER_ROLE*


```solidity
function functionCall(address target, bytes memory data) external onlyRoles(BROADCASTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|The address of the contract to call|
|`data`|`bytes`|The encoded function data to execute|


