# ILegionLinearVesting
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/interfaces/vesting/ILegionLinearVesting.sol)


## Functions
### start

See [VestingWalletUpgradeable-start](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#start).


```solidity
function start() external view returns (uint256);
```

### duration

See [VestingWalletUpgradeable-duration](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#duration).


```solidity
function duration() external view returns (uint256);
```

### end

See [VestingWalletUpgradeable-end](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#end).


```solidity
function end() external view returns (uint256);
```

### released

See [VestingWalletUpgradeable-released](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#released).


```solidity
function released() external view returns (uint256);
```

### released

See [VestingWalletUpgradeable-released](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#released).


```solidity
function released(address token) external view returns (uint256);
```

### releasable

See [VestingWalletUpgradeable-releasable](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#releasable).


```solidity
function releasable() external view returns (uint256);
```

### releasable

See [VestingWalletUpgradeable-releasable](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#releasable).


```solidity
function releasable(address token) external view returns (uint256);
```

### release

See [VestingWalletUpgradeable-release](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#release).


```solidity
function release() external;
```

### release

See [VestingWalletUpgradeable-release](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#release).


```solidity
function release(address token) external;
```

### vestedAmount

See [VestingWalletUpgradeable-vestedAmount](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#vestedamount).


```solidity
function vestedAmount(uint64 timestamp) external view returns (uint256);
```

### vestedAmount

See [VestingWalletUpgradeable-vestedAmount](/src/interfaces/vesting/ILegionLinearEpochVesting.sol/interface.ILegionLinearEpochVesting.md#vestedamount).


```solidity
function vestedAmount(address token, uint64 timestamp) external view returns (uint256);
```

### cliffEnd

Returns the cliff end timestamp.


```solidity
function cliffEnd() external view returns (uint256);
```

