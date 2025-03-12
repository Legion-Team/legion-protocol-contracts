# ILegionVestingFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/interfaces/factories/ILegionVestingFactory.sol)


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


### createLinearEpochVesting

Deploy a LegionLinearEpochVesting contract.


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
|`linearEpochVestingInstance`|`address payable`|The address of the deployed LegionLinearEpochVesting instance.|


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

### NewLinearEpochVestingCreated
This event is emitted when a new linear epoch vesting schedule contract is deployed for an investor.


```solidity
event NewLinearEpochVestingCreated(
    address beneficiary,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds,
    uint256 epochDurationSeconds,
    uint256 numberOfEpochs
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address of the beneficiary.|
|`startTimestamp`|`uint64`|The Unix timestamp (seconds) when the vesting period starts.|
|`durationSeconds`|`uint64`|The vesting duration in seconds.|
|`cliffDurationSeconds`|`uint64`|The vesting cliff duration in seconds.|
|`epochDurationSeconds`|`uint256`|The duration of each epoch in seconds|
|`numberOfEpochs`|`uint256`|The number of epochs|

