# ILegionVestingFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/1a165deeea33dfd2b1dca142bf23d06b547c39a3/src/interfaces/factories/ILegionVestingFactory.sol)


## Functions
### createLinearVesting

Deploy a LegionLinearVesting contract.


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
|`beneficiary`|`address`|The address of the beneficiary.|
|`startTimestamp`|`uint64`|The Unix timestamp (seconds) when the vesting starts.|
|`durationSeconds`|`uint64`|The total duration of the vesting period in seconds.|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`linearVestingInstance`|`address payable`|The address of the deployed LegionLinearVesting instance.|


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
|`startTimestamp`|`uint64`|The Unix timestamp (seconds) when the vesting period starts.|
|`durationSeconds`|`uint64`|The vesting duration in seconds.|
|`cliffDurationSeconds`|`uint64`|The vesting cliff duration in seconds.|

