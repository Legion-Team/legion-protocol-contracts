# LegionLinearVesting
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionLinearVesting.sol)

**Inherits:**
VestingWalletUpgradeable

**Author:**
Legion.

A contract used to release vested tokens to users.

*The contract fully utilizes OpenZeppelin's VestingWallet.sol implementation.*


## State Variables
### cliffEndTimestamp
*The unix timestamp (seconds) of the block when the cliff ends.*


```solidity
uint256 private cliffEndTimestamp;
```


## Functions
### onlyCliffEnded

Throws if an user tries to release tokens before the cliff period has ended


```solidity
modifier onlyCliffEnded();
```

### constructor

*LegionLinearVesting constructor.*


```solidity
constructor();
```

### initialize

Initializes the contract with correct parameters.


```solidity
function initialize(address beneficiary, uint64 startTimestamp, uint64 durationSeconds, uint64 cliffDurationSeconds)
    public
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The beneficiary to receive tokens.|
|`startTimestamp`|`uint64`|The start timestamp of the vesting schedule.|
|`durationSeconds`|`uint64`|The vesting duration in seconds.|
|`cliffDurationSeconds`|`uint64`||


### release

See [VestingWalletUpgradeable-release](/src/interfaces/ILegionLinearVesting.sol/interface.ILegionLinearVesting.md#release).


```solidity
function release() public override onlyCliffEnded;
```

### release

See [VestingWalletUpgradeable-release](/src/interfaces/ILegionLinearVesting.sol/interface.ILegionLinearVesting.md#release).


```solidity
function release(address token) public override onlyCliffEnded;
```

### cliffEnd

Returns the cliff end timestamp.


```solidity
function cliffEnd() public view returns (uint256);
```

