# LegionLinearEpochVesting
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/vesting/LegionLinearEpochVesting.sol)

**Inherits:**
VestingWalletUpgradeable

**Author:**
Legion

Releases vested tokens to users on an epoch-based schedule with cliff protection.

*Extends OpenZeppelin's VestingWalletUpgradeable with linear epoch vesting functionality.*


## State Variables
### s_cliffEndTimestamp
*Unix timestamp (seconds) when the cliff period ends.*


```solidity
uint64 private s_cliffEndTimestamp;
```


### s_epochDurationSeconds
*Duration of each epoch in seconds.*


```solidity
uint64 private s_epochDurationSeconds;
```


### s_numberOfEpochs
*Total number of epochs in the vesting schedule.*


```solidity
uint64 private s_numberOfEpochs;
```


### s_lastClaimedEpoch
*The last epoch for which tokens were claimed.*


```solidity
uint64 private s_lastClaimedEpoch;
```


### s_vestingController
*Address of the vesting controller.*


```solidity
address private s_vestingController;
```


### s_askToken
*The address of the token to be vested.*


```solidity
address private s_askToken;
```


## Functions
### onlyCliffEnded

Restricts token release until the cliff period has ended.

*Reverts with LegionVesting__CliffNotEnded if block.timestamp is before cliffEndTimestamp.*


```solidity
modifier onlyCliffEnded();
```

### onlyVestingController

Restricts function access to the vesting controller only.

*Reverts if the caller is not the configured vesting controller address.*


```solidity
modifier onlyVestingController();
```

### onlyAskToken

Restricts function access to release the ask token only.

*Reverts if the token being released is not the configured ask token.*


```solidity
modifier onlyAskToken(address token);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to release.|


### constructor

Constructor for the LegionLinearEpochVesting contract.

*Prevents the implementation contract from being initialized directly.*


```solidity
constructor();
```

### initialize

Initializes the vesting contract with specified parameters.

*Sets up the vesting schedule, cliff, and epoch details; callable only once.*


```solidity
function initialize(
    address _beneficiary,
    address _vestingController,
    address _askToken,
    uint64 _startTimestamp,
    uint64 _durationSeconds,
    uint64 _cliffDurationSeconds,
    uint64 _epochDurationSeconds,
    uint64 _numberOfEpochs
)
    external
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beneficiary`|`address`|The address to receive the vested tokens.|
|`_vestingController`|`address`|The address of the vesting controller contract for access control.|
|`_askToken`|`address`|The address of the token to be vested.|
|`_startTimestamp`|`uint64`|The Unix timestamp (seconds) when vesting starts.|
|`_durationSeconds`|`uint64`|The total duration of the vesting period in seconds.|
|`_cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|
|`_epochDurationSeconds`|`uint64`|The duration of each epoch in seconds.|
|`_numberOfEpochs`|`uint64`|The number of epochs in the vesting schedule.|


### cliffEndTimestamp

Returns the timestamp when the cliff period ends

*Indicates when the vesting cliff ends and tokens can be released.*


```solidity
function cliffEndTimestamp() external view returns (uint64);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The Unix timestamp (seconds) of the cliff end.|


### epochDurationSeconds

Returns the duration of each epoch in seconds.

*Defines the vesting interval for epoch-based releases.*


```solidity
function epochDurationSeconds() external view returns (uint64);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The duration of each epoch in seconds.|


### numberOfEpochs

Returns the total number of epochs in the vesting schedule.

*Determines the granularity of token releases.*


```solidity
function numberOfEpochs() external view returns (uint64);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The total number of epochs in the vesting schedule.|


### lastClaimedEpoch

Returns the last epoch for which tokens were claimed.

*Tracks the progress of vesting claims.*


```solidity
function lastClaimedEpoch() external view returns (uint64);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The last epoch number for which tokens were claimed.|


### release

Releases vested tokens of a specific type to the beneficiary.

*Overrides VestingWalletUpgradeable; requires cliff to have ended.*


```solidity
function release(address token) public override onlyAskToken(token) onlyCliffEnded;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to release.|


### emergencyTransferOwnership

Transfers ownership of the contract to a new address.

*Can only be called by the vesting controller.*


```solidity
function emergencyTransferOwnership(address newOwner) external onlyVestingController;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOwner`|`address`|The address to transfer ownership to.|


### getCurrentEpoch

Returns the current epoch based on the current block timestamp.

*Calculates the epoch number starting from 0 before vesting begins.*


```solidity
function getCurrentEpoch() public view returns (uint64);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The current epoch number (0 if before start, 1+ otherwise).|


### getCurrentEpochAtTimestamp

Returns the epoch at a specific timestamp.

*Calculates the epoch number for a given timestamp.*


```solidity
function getCurrentEpochAtTimestamp(uint256 timestamp) public view returns (uint64);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|The Unix timestamp (seconds) to evaluate.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The epoch number at the given timestamp (0 if before start).|


### _updateLastClaimedEpoch

*Updates the last claimed epoch after a release.*


```solidity
function _updateLastClaimedEpoch() internal;
```

### _vestingSchedule

*Calculates the vested amount based on an epoch-based schedule.*


```solidity
function _vestingSchedule(
    uint256 _totalAllocation,
    uint64 _timestamp
)
    internal
    view
    override
    returns (uint256 amountVested);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_totalAllocation`|`uint256`|The total amount of tokens allocated for vesting.|
|`_timestamp`|`uint64`|The Unix timestamp (seconds) to calculate vesting up to.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountVested`|`uint256`|The amount of tokens vested by the given timestamp.|


