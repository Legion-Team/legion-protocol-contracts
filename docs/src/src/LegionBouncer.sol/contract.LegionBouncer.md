# LegionBouncer
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionBouncer.sol)

**Inherits:**
[ILegionBouncer](/src/interfaces/ILegionBouncer.sol/interface.ILegionBouncer.md), OwnableRoles

**Author:**
Legion.

A contract used to keep access control for the Legion Protocol.


## State Variables
### BROADCASTER_ROLE
*Constant representing the broadcaster role.*


```solidity
uint256 public constant BROADCASTER_ROLE = _ROLE_0;
```


## Functions
### constructor

*Constructor to initialize the LegionBouncer.*


```solidity
constructor(address defaultAdmin, address defaultBroadcaster);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`defaultAdmin`|`address`|The default admin role for the `LegionBouncer` contract.|
|`defaultBroadcaster`|`address`|The default broadcaster role for the `LegionBouncer` contract.|


### functionCall

See [ILegionBouncer-functionCall](/src/interfaces/ILegionBouncer.sol/interface.ILegionBouncer.md#functioncall).


```solidity
function functionCall(address target, bytes memory data) external onlyRoles(BROADCASTER_ROLE);
```

