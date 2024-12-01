# ILegionVestingFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/interfaces/ILegionVestingFactory.sol)


## Functions
### createLinearVesting

Deploy a LegionLinearVesting contract.

*Can be called only by addresses allowed to deploy.*


```solidity
function createLinearVesting(
    address beneficiary,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds
) external returns (address payable linearVestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The beneficiary.|
|`startTimestamp`|`uint64`|The start timestamp.|
|`durationSeconds`|`uint64`|The duration in seconds.|
|`cliffDurationSeconds`|`uint64`|The cliff duration in seconds.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`linearVestingInstance`|`address payable`|The address of the deployed linearVesting instance.|


## Events
### NewLinearVestingCreated
This event is emitted when a new linear vesting schedule contract is deployed for an investor.


```solidity
event NewLinearVestingCreated(
    address beneficiary, uint64 startTimestamp, uint64 durationSeconds, uint64 cliffDurationSeconds
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address of the beneficiary.|
|`startTimestamp`|`uint64`|The start timestamp of the vesting period.|
|`durationSeconds`|`uint64`|The vesting duration in seconds.|
|`cliffDurationSeconds`|`uint64`|The vesting cliff duration in seconds.|

