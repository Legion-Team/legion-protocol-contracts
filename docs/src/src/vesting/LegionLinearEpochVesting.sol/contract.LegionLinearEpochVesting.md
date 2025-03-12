# LegionLinearEpochVesting
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/vesting/LegionLinearEpochVesting.sol)

**Inherits:**
VestingWalletUpgradeable

**Author:**
Legion

A contract used to release vested tokens to users

*The contract fully utilizes OpenZeppelin's VestingWallet.sol implementation*


## State Variables
### cliffEndTimestamp
*The Unix timestamp (seconds) of the block when the cliff ends*


```solidity
uint256 private cliffEndTimestamp;
```


### epochDurationSeconds
*The duration of each epoch in seconds*


```solidity
uint256 public epochDurationSeconds;
```


### numberOfEpochs
*The number of epochs*


```solidity
uint256 public numberOfEpochs;
```


### lastClaimedEpoch
*The last claimed epoch*


```solidity
uint256 public lastClaimedEpoch;
```


## Functions
### onlyCliffEnded

Throws if a user tries to release tokens before the cliff period has ended


```solidity
modifier onlyCliffEnded();
```

### constructor

*LegionLinearVesting constructor.*


```solidity
constructor();
```

### initialize

Initializes the contract with the correct parameters


```solidity
function initialize(
    address _beneficiary,
    uint64 _startTimestamp,
    uint64 _durationSeconds,
    uint64 _cliffDurationSeconds,
    uint256 _epochDurationSeconds,
    uint256 _numberOfEpochs
)
    public
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beneficiary`|`address`|The beneficiary to receive tokens|
|`_startTimestamp`|`uint64`|The Unix timestamp when the vesting schedule starts|
|`_durationSeconds`|`uint64`|The duration of the vesting period in seconds|
|`_cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds|
|`_epochDurationSeconds`|`uint256`|The duration of each epoch in seconds|
|`_numberOfEpochs`|`uint256`|The number of epochs|


### _vestingSchedule

*Overriden implementation of the vesting formula. This returns the amount vested, as a function of time, for
an asset given its total historical allocation.*


```solidity
function _vestingSchedule(
    uint256 totalAllocation,
    uint64 timestamp
)
    internal
    view
    override
    returns (uint256 amountVested);
```

### _updateLastClaimedEpoch

*Updates the last claimed epoch*


```solidity
function _updateLastClaimedEpoch() internal;
```

### release

Release the native token (ether) that have already vested.
Emits a {EtherReleased} event.


```solidity
function release() public override onlyCliffEnded;
```

### release

Release the tokens that have already vested.


```solidity
function release(address token) public override onlyCliffEnded;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The vested token to release Emits a {ERC20Released} event.|


### getCurrentEpoch

Returns the current epoch.


```solidity
function getCurrentEpoch() public view returns (uint256);
```

### getCurrentEpochAtTimestamp

Returns the current epoch for a specific timestamp.


```solidity
function getCurrentEpochAtTimestamp(uint256 timestamp) public view returns (uint256);
```

### cliffEnd

Returns the cliff end timestamp.


```solidity
function cliffEnd() public view returns (uint256);
```

