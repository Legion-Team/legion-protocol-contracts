# LegionLinearVesting
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/vesting/LegionLinearVesting.sol)

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
    address beneficiary,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds
)
    public
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The beneficiary to receive tokens|
|`startTimestamp`|`uint64`|The Unix timestamp when the vesting schedule starts|
|`durationSeconds`|`uint64`|The duration of the vesting period in seconds|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds|


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


### cliffEnd

Returns the cliff end timestamp.


```solidity
function cliffEnd() public view returns (uint256);
```

