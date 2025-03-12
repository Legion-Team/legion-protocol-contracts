# ILegionVestingManager
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/a0becaf0413338ea78e3b0a0ce4527f7e1695849/src/interfaces/vesting/ILegionVestingManager.sol)

**Author:**
Legion

An interface for managing vesting creation and deployment in the Legion Protocol


## Structs
### LegionVestingConfig
A struct describing the vesting configuration for the sale.


```solidity
struct LegionVestingConfig {
    address vestingFactory;
}
```

### LegionInvestorVestingStatus
A struct describing the vesting status for an investor.


```solidity
struct LegionInvestorVestingStatus {
    uint256 start;
    uint256 end;
    uint256 cliffEnd;
    uint256 duration;
    uint256 released;
    uint256 releasable;
    uint256 vestedAmount;
}
```

### LegionInvestorVestingConfig
A struct describing the vesting configuration for an investor.


```solidity
struct LegionInvestorVestingConfig {
    ILegionVestingManager.VestingType vestingType;
    uint256 vestingStartTime;
    uint256 vestingDurationSeconds;
    uint256 vestingCliffDurationSeconds;
    uint256 epochDurationSeconds;
    uint256 numberOfEpochs;
    uint256 tokenAllocationOnTGERate;
}
```

## Enums
### VestingType
An enum describing possible vesting types.


```solidity
enum VestingType {
    LEGION_LINEAR,
    LEGION_LINEAR_EPOCH
}
```

