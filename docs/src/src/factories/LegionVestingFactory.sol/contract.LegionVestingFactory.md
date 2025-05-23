# LegionVestingFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/1a165deeea33dfd2b1dca142bf23d06b547c39a3/src/factories/LegionVestingFactory.sol)

**Inherits:**
[ILegionVestingFactory](/src/interfaces/factories/ILegionVestingFactory.sol/interface.ILegionVestingFactory.md)

**Author:**
Legion

A factory contract for deploying proxy instances of Legion vesting contracts


## State Variables
### linearVestingTemplate
*The LegionLinearVesting implementation contract*


```solidity
address public immutable linearVestingTemplate = address(new LegionLinearVesting());
```


## Functions
### createLinearVesting

Creates a new linear vesting contract


```solidity
function createLinearVesting(
    address beneficiary,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds
)
    external
    returns (address payable linearVestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive the vested tokens|
|`startTimestamp`|`uint64`|The Unix timestamp when the vesting period starts|
|`durationSeconds`|`uint64`|The duration of the vesting period in seconds|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`linearVestingInstance`|`address payable`|The address of the deployed LegionLinearVesting instance|


