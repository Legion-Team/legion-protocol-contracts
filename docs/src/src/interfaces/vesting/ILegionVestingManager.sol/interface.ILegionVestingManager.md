# ILegionVestingManager
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/vesting/ILegionVestingManager.sol)

**Author:**
Legion

Interface for the LegionVestingManager contract.


## Functions
### vestingConfiguration

Returns the current vesting configuration.


```solidity
function vestingConfiguration() external view returns (ILegionVestingManager.LegionVestingConfig memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`ILegionVestingManager.LegionVestingConfig`|The complete vesting configuration struct.|


## Structs
### LegionVestingConfig
*Struct containing the vesting configuration for a sale.*


```solidity
struct LegionVestingConfig {
    address vestingFactory;
    address vestingController;
}
```

### LegionInvestorVestingStatus
*Struct representing an investor's vesting status.*


```solidity
struct LegionInvestorVestingStatus {
    uint64 start;
    uint64 end;
    uint64 cliffEnd;
    uint64 duration;
    uint256 released;
    uint256 releasable;
    uint256 vestedAmount;
}
```

### LegionInvestorVestingConfig
*Struct defining an investor's vesting configuration.*


```solidity
struct LegionInvestorVestingConfig {
    uint64 vestingStartTime;
    uint64 vestingDurationSeconds;
    uint64 vestingCliffDurationSeconds;
    ILegionVestingManager.VestingType vestingType;
    uint64 epochDurationSeconds;
    uint64 numberOfEpochs;
    uint64 tokenAllocationOnTGERate;
}
```

## Enums
### VestingType
*Enum defining supported vesting types in the Legion Protocol.*


```solidity
enum VestingType {
    LEGION_LINEAR,
    LEGION_LINEAR_EPOCH
}
```

