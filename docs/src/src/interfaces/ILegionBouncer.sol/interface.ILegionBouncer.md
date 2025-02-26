# ILegionBouncer
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/e045131669c5801ab2e88b13e55002362a64c068/src/interfaces/ILegionBouncer.sol)

**Author:**
Legion

An interface for managing function call permissions in the Legion Protocol


## Functions
### functionCall

Executes a function call on a target contract


```solidity
function functionCall(address target, bytes memory data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|The address of the target contract|
|`data`|`bytes`|The encoded function data to execute|


