# LegionVestingManager
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/vesting/LegionVestingManager.sol)

**Inherits:**
[ILegionVestingManager](/src/interfaces/vesting/ILegionVestingManager.sol/interface.ILegionVestingManager.md)

**Author:**
Legion

Manages vesting creation and deployment in the Legion Protocol.

*Abstract contract implementing ILegionVestingManager with vesting type logic and factory interactions.*


## State Variables
### s_vestingConfig
*Struct containing the vesting configuration for the sale.*


```solidity
LegionVestingConfig internal s_vestingConfig;
```


## Functions
### vestingConfiguration

Returns the current vesting configuration.


```solidity
function vestingConfiguration() external view virtual returns (LegionVestingConfig memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LegionVestingConfig`|The complete vesting configuration struct.|


### _createVesting

*Creates a vesting schedule contract for an investor based on configuration.*


```solidity
function _createVesting(
    LegionInvestorVestingConfig calldata _investorVestingConfig,
    address _askToken
)
    internal
    virtual
    returns (address payable vestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investorVestingConfig`|`LegionInvestorVestingConfig`|The vesting schedule configuration for the investor.|
|`_askToken`|`address`|The address of the token used for vesting.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingInstance`|`address payable`|The address of the deployed vesting contract instance.|


### _createLinearVesting

*Creates a linear vesting schedule contract.*


```solidity
function _createLinearVesting(
    address _beneficiary,
    address _vestingController,
    address _vestingFactory,
    uint64 _startTimestamp,
    uint64 _durationSeconds,
    uint64 _cliffDurationSeconds
)
    internal
    virtual
    returns (address payable vestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beneficiary`|`address`|The address to receive the vested tokens.|
|`_vestingController`|`address`|The address of the vesting controller contract.|
|`_vestingFactory`|`address`|The address of the vesting factory contract.|
|`_startTimestamp`|`uint64`|The Unix timestamp (seconds) when vesting starts.|
|`_durationSeconds`|`uint64`|The duration of the vesting period in seconds.|
|`_cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingInstance`|`address payable`|The address of the deployed linear vesting contract.|


### _createLinearEpochVesting

*Creates a linear epoch-based vesting schedule contract.*


```solidity
function _createLinearEpochVesting(
    address _beneficiary,
    address _vestingController,
    address _vestingFactory,
    address _askToken,
    uint64 _startTimestamp,
    uint64 _durationSeconds,
    uint64 _cliffDurationSeconds,
    uint64 _epochDurationSeconds,
    uint64 _numberOfEpochs
)
    internal
    virtual
    returns (address payable vestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beneficiary`|`address`|The address to receive the vested tokens.|
|`_vestingController`|`address`|The address of the vesting controller contract.|
|`_vestingFactory`|`address`|The address of the vesting factory contract.|
|`_askToken`|`address`|The address of the token to be vested.|
|`_startTimestamp`|`uint64`|The Unix timestamp (seconds) when vesting starts.|
|`_durationSeconds`|`uint64`|The duration of the vesting period in seconds.|
|`_cliffDurationSeconds`|`uint64`|The duration of the cliff period in seconds.|
|`_epochDurationSeconds`|`uint64`|The duration of each epoch in seconds.|
|`_numberOfEpochs`|`uint64`|The total number of epochs in the vesting schedule.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingInstance`|`address payable`|The address of the deployed epoch vesting contract.|


### _verifyValidVestingConfig

*Verifies the validity of a vesting configuration.*


```solidity
function _verifyValidVestingConfig(LegionInvestorVestingConfig calldata _investorVestingConfig) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investorVestingConfig`|`LegionInvestorVestingConfig`|The vesting schedule configuration to validate.|


