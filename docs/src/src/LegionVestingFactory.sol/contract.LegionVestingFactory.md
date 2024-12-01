# LegionVestingFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionVestingFactory.sol)

**Inherits:**
[ILegionVestingFactory](/src/interfaces/ILegionVestingFactory.sol/interface.ILegionVestingFactory.md)

**Author:**
Legion.

A factory contract for deploying proxy instances of a Legion vesting contracts.


## State Variables
### linearVestingTemplate
*The LegionLinearVesting implementation contract.*


```solidity
address public immutable linearVestingTemplate = address(new LegionLinearVesting());
```


## Functions
### createLinearVesting

See {ILegionLinearVestingFactory-createLinearVesting}.


```solidity
function createLinearVesting(
    address beneficiary,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds
) external returns (address payable linearVestingInstance);
```

