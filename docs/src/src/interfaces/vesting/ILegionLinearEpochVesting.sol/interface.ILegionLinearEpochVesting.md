# ILegionLinearEpochVesting
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/interfaces/vesting/ILegionLinearEpochVesting.sol)

**Inherits:**
[ILegionVesting](/src/interfaces/vesting/ILegionVesting.sol/interface.ILegionVesting.md)

**Author:**
Legion

Interface for the LegionLinearEpochVesting contract.


## Functions
### epochDurationSeconds

Returns the duration of each epoch in seconds


```solidity
function epochDurationSeconds() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Duration of each epoch in seconds|


### numberOfEpochs

Returns the total number of epochs in the vesting schedule


```solidity
function numberOfEpochs() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Total number of epochs in the vesting schedule|


### lastClaimedEpoch

Returns the last epoch for which tokens were claimed


```solidity
function lastClaimedEpoch() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Last epoch number for which tokens were claimed|


