# LegionVestingManager
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/vesting/LegionVestingManager.sol)

**Inherits:**
[ILegionVestingManager](/src/interfaces/vesting/ILegionVestingManager.sol/interface.ILegionVestingManager.md)

**Author:**
Legion

A contract for managing vesting creation and deployment in the Legion Protocol


## State Variables
### vestingConfig
*A struct describing the sale vesting configuration.*


```solidity
LegionVestingConfig public vestingConfig;
```


## Functions
### _createVesting

Create a vesting schedule contract for an investor.


```solidity
function _createVesting(LegionInvestorVestingConfig calldata investorVestingConfig)
    internal
    virtual
    returns (address payable vestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investorVestingConfig`|`LegionInvestorVestingConfig`|The configuration of the vesting schedule.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingInstance`|`address payable`|The address of the deployed vesting instance.|


### _createLinearVesting

Create a linear vesting schedule contract.


```solidity
function _createLinearVesting(
    address beneficiary,
    address vestingFactory,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds
)
    internal
    virtual
    returns (address payable vestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The beneficiary.|
|`vestingFactory`|`address`|The address of the vesting factory.|
|`startTimestamp`|`uint64`|The Unix timestamp when the vesting starts.|
|`durationSeconds`|`uint64`|The duration in seconds.|
|`cliffDurationSeconds`|`uint64`|The cliff duration in seconds.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingInstance`|`address payable`|The address of the deployed vesting instance.|


### _createLinearEpochVesting

Create a linear vesting schedule contract.


```solidity
function _createLinearEpochVesting(
    address beneficiary,
    address vestingFactory,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint64 cliffDurationSeconds,
    uint256 epochDurationSeconds,
    uint256 numberOfEpochs
)
    internal
    virtual
    returns (address payable vestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beneficiary`|`address`|The address that will receive the vested tokens|
|`vestingFactory`|`address`|The address of the vesting factory.|
|`startTimestamp`|`uint64`|The Unix timestamp when the vesting period starts|
|`durationSeconds`|`uint64`|The duration of the vesting period in seconds|
|`cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds|
|`epochDurationSeconds`|`uint256`|The duration of each epoch in seconds|
|`numberOfEpochs`|`uint256`|The number of epochs|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingInstance`|`address payable`|The address of the deployed vesting instance.|


### _verifyValidLinearVestingConfig

Verify that the  vesting configuration is valid.


```solidity
function _verifyValidLinearVestingConfig(LegionInvestorVestingConfig calldata investorVestingConfig)
    internal
    view
    virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investorVestingConfig`|`LegionInvestorVestingConfig`|The configuration of the vesting schedule.|


