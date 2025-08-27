# ILegionVestingFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/factories/ILegionVestingFactory.sol)

**Author:**
Legion

Interface for the LegionVestingFactory contract.

*Provides factory functionality for deploying and initializing vesting contracts with different schedules.*


## Functions
### createLinearVesting

Creates a new linear vesting contract instance.


```solidity
function createLinearVesting(
    address beneficiary,
    address vestingController,
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
|`beneficiary`|`address`|The address that will receive the vested tokens.|
|`vestingController`|`address`|The address of the vesting controller contract for access control.|
|`startTimestamp`|`uint64`|The Unix timestamp when the vesting period begins.|
|`durationSeconds`|`uint64`|The total duration of the vesting period in seconds.|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`linearVestingInstance`|`address payable`|The address of the newly deployed and initialized LegionLinearVesting instance.|


### createLinearEpochVesting

Creates a new linear epoch vesting contract instance.


```solidity
function createLinearEpochVesting(
    address beneficiary,
    address vestingController,
    address askToken,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds,
    uint64 epochDurationSeconds,
    uint64 numberOfEpochs
)
    external
    returns (address payable linearEpochVestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive the vested tokens.|
|`vestingController`|`address`|The address of the vesting controller contract for access control.|
|`askToken`|`address`|The address of the token to be vested.|
|`startTimestamp`|`uint64`|The Unix timestamp when the vesting period begins.|
|`durationSeconds`|`uint64`|The total duration of the vesting period in seconds.|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|
|`epochDurationSeconds`|`uint64`|The duration of each epoch in seconds.|
|`numberOfEpochs`|`uint64`|The total number of epochs in the vesting schedule.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`linearEpochVestingInstance`|`address payable`|The address of the newly deployed and initialized LegionLinearEpochVesting instance.|


## Events
### NewLinearVestingCreated
Emitted when a new linear vesting schedule contract is deployed for an investor.


```solidity
event NewLinearVestingCreated(
    address beneficiary,
    address vestingController,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address of the beneficiary receiving the vested tokens.|
|`vestingController`|`address`|The address of the vesting controller contract for access control.|
|`startTimestamp`|`uint64`|The Unix timestamp (in seconds) when the vesting period begins.|
|`durationSeconds`|`uint64`|The total duration of the vesting period in seconds.|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|

### NewLinearEpochVestingCreated
Emitted when a new linear epoch vesting schedule contract is deployed for an investor.


```solidity
event NewLinearEpochVestingCreated(
    address beneficiary,
    address vestingController,
    address askToken,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds,
    uint64 epochDurationSeconds,
    uint64 numberOfEpochs
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address of the beneficiary receiving the vested tokens.|
|`vestingController`|`address`|The address of the vesting controller contract for access control.|
|`askToken`|`address`|The address of the token to be vested.|
|`startTimestamp`|`uint64`|The Unix timestamp (in seconds) when the vesting period begins.|
|`durationSeconds`|`uint64`|The total duration of the vesting period in seconds.|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|
|`epochDurationSeconds`|`uint64`|The duration of each epoch in seconds.|
|`numberOfEpochs`|`uint64`|The total number of epochs in the vesting schedule.|

