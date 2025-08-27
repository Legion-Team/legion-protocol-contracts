# LegionLinearVesting
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/vesting/LegionLinearVesting.sol)

**Inherits:**
VestingWalletUpgradeable

**Author:**
Legion

Releases vested tokens to users with a linear schedule and cliff protection.

*Extends OpenZeppelin's VestingWalletUpgradeable with cliff functionality.*


## State Variables
### s_cliffEndTimestamp
*Unix timestamp (seconds) when the cliff period ends.*


```solidity
uint64 private s_cliffEndTimestamp;
```


### s_vestingController
*Address of the vesting controller.*


```solidity
address private s_vestingController;
```


## Functions
### onlyCliffEnded

Restricts token release until the cliff period has ended.

*Reverts with LegionVesting__CliffNotEnded if block.timestamp is before s_cliffEndTimestamp.*


```solidity
modifier onlyCliffEnded();
```

### onlyVestingController

Restricts function access to the vesting controller only.

*Reverts if the caller is not the configured vesting controller address.*


```solidity
modifier onlyVestingController();
```

### constructor

Constructor for the LegionLinearVesting contract.

*Prevents the implementation contract from being initialized directly.*


```solidity
constructor();
```

### initialize

Initializes the vesting contract with specified parameters.

*Sets up the linear vesting schedule and cliff; callable only once.*


```solidity
function initialize(
    address beneficiary,
    address vestingController,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds
)
    external
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address to receive the vested tokens.|
|`vestingController`|`address`|The address of the vesting controller contract for access control.|
|`startTimestamp`|`uint64`|The Unix timestamp (seconds) when vesting starts.|
|`durationSeconds`|`uint64`|The total duration of the vesting period in seconds.|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|


### cliffEndTimestamp

Returns the timestamp when the cliff period ends.

*Indicates when tokens become releasable.*


```solidity
function cliffEndTimestamp() external view returns (uint64);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|The Unix timestamp (seconds) of the cliff end.|


### release

Releases vested tokens of a specific type to the beneficiary.

*Overrides VestingWalletUpgradeable; requires cliff to have ended.*


```solidity
function release(address token) public override onlyCliffEnded;
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


