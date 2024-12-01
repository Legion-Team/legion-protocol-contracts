# ILegionLinearVesting
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/interfaces/ILegionLinearVesting.sol)


## Functions
### start

See [VestingWalletUpgradeable-start](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#start).


```solidity
function start() external view returns (uint256);
```

### duration

See [VestingWalletUpgradeable-duration](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#duration).


```solidity
function duration() external view returns (uint256);
```

### end

See [VestingWalletUpgradeable-end](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#end).


```solidity
function end() external view returns (uint256);
```

### released

See [VestingWalletUpgradeable-released](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#released).


```solidity
function released() external view returns (uint256);
```

### released

See [VestingWalletUpgradeable-released](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#released).


```solidity
function released(address token) external view returns (uint256);
```

### releasable

See [VestingWalletUpgradeable-releasable](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#releasable).


```solidity
function releasable() external view returns (uint256);
```

### releasable

See [VestingWalletUpgradeable-releasable](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#releasable).


```solidity
function releasable(address token) external view returns (uint256);
```

### release

See [VestingWalletUpgradeable-release](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#release).


```solidity
function release() external;
```

### release

See [VestingWalletUpgradeable-release](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#release).


```solidity
function release(address token) external;
```

### vestedAmount

See [VestingWalletUpgradeable-vestedAmount](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#vestedamount).


```solidity
function vestedAmount(uint64 timestamp) external view returns (uint256);
```

### vestedAmount

See [VestingWalletUpgradeable-vestedAmount](/lib/openzeppelin-contracts-upgradeable/contracts/finance/VestingWalletUpgradeable.sol/contract.VestingWalletUpgradeable.md#vestedamount).


```solidity
function vestedAmount(address token, uint64 timestamp) external view returns (uint256);
```

