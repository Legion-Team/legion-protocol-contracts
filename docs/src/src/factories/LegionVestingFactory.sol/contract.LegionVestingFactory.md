# LegionVestingFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/e045131669c5801ab2e88b13e55002362a64c068/src/factories/LegionVestingFactory.sol)

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


### linearEpochVestingTemplate
*The LegionLinearVesting implementation contract*


```solidity
address public immutable linearEpochVestingTemplate = address(new LegionLinearEpochVesting());
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


### createLinearEpochVesting

Creates a new linear epoch vesting contract


```solidity
function createLinearEpochVesting(
    address beneficiary,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds,
    uint256 epochDurationSeconds,
    uint256 numberOfEpochs
)
    external
    returns (address payable linearEpochVestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive the vested tokens|
|`startTimestamp`|`uint64`|The Unix timestamp when the vesting period starts|
|`durationSeconds`|`uint64`|The duration of the vesting period in seconds|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds|
|`epochDurationSeconds`|`uint256`|The duration of each epoch in seconds|
|`numberOfEpochs`|`uint256`|The number of epochs|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`linearEpochVestingInstance`|`address payable`|The address of the deployed LegionLinearVesting instance|


