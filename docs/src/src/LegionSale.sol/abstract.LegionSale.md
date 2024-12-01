# LegionSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionSale.sol)

**Inherits:**
[ILegionSale](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md), Initializable, Pausable


## State Variables
### saleConfig
*A struct describing the sale configuration.*


```solidity
LegionSaleConfiguration internal saleConfig;
```


### addressConfig
*A struct describing the sale addresses configuration.*


```solidity
LegionSaleAddressConfiguration internal addressConfig;
```


### vestingConfig
*A struct describing the vesting configuration.*


```solidity
LegionVestingConfiguration internal vestingConfig;
```


### saleStatus
*A struct describing the sale status.*


```solidity
LegionSaleStatus internal saleStatus;
```


### investorPositions
*Mapping of investor address to investor position.*


```solidity
mapping(address investorAddress => InvestorPosition investorPosition) internal investorPositions;
```


## Functions
### onlyLegion

Throws if called by any account other than Legion.


```solidity
modifier onlyLegion();
```

### onlyProject

Throws if called by any account other than the Project.


```solidity
modifier onlyProject();
```

### askTokenAvailable

Throws when method is called and the `askToken` is unavailable.


```solidity
modifier askTokenAvailable();
```

### constructor

LegionSale constructor.


```solidity
constructor();
```

### refund

See [ILegionSale-refund](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#refund).


```solidity
function refund() external virtual whenNotPaused;
```

### withdrawRaisedCapital

See [ILegionSale-withdrawRaisedCapital](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#withdrawraisedcapital).


```solidity
function withdrawRaisedCapital() external virtual onlyProject whenNotPaused;
```

### claimTokenAllocation

See [ILegionSale-claimTokenAllocation](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#claimtokenallocation).


```solidity
function claimTokenAllocation(uint256 amount, bytes32[] calldata proof)
    external
    virtual
    askTokenAvailable
    whenNotPaused;
```

### withdrawExcessInvestedCapital

See [ILegionSale-withdrawExcessInvestedCapital](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#withdrawexcessinvestedcapital).


```solidity
function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external virtual whenNotPaused;
```

### releaseVestedTokens

See [ILegionSale-releaseVestedTokens](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#releasevestedtokens).


```solidity
function releaseVestedTokens() external virtual askTokenAvailable whenNotPaused;
```

### supplyTokens

See [ILegionSale-supplyTokens](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#supplytokens).


```solidity
function supplyTokens(uint256 amount, uint256 legionFee) external virtual onlyProject askTokenAvailable whenNotPaused;
```

### setExcessInvestedCapital

See [ILegionSale-setExcessInvestedCapital](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#setexcessinvestedcapital).


```solidity
function setExcessInvestedCapital(bytes32 merkleRoot) external virtual onlyLegion;
```

### cancelSale

See [ILegionSale-cancelSale](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#cancelsale).


```solidity
function cancelSale() public virtual onlyProject whenNotPaused;
```

### cancelExpiredSale

See [ILegionSale-cancelExpiredSale](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#cancelexpiredsale).


```solidity
function cancelExpiredSale() external virtual whenNotPaused;
```

### withdrawInvestedCapitalIfCanceled

See [ILegionSale-withdrawInvestedCapitalIfCanceled](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#withdrawinvestedcapitalifcanceled).


```solidity
function withdrawInvestedCapitalIfCanceled() external virtual whenNotPaused;
```

### emergencyWithdraw

See [ILegionSale-emergencyWithdraw](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#emergencywithdraw).


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external virtual onlyLegion;
```

### syncLegionAddresses

See [ILegionSale-syncLegionAddresses](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#synclegionaddresses).


```solidity
function syncLegionAddresses() external virtual onlyLegion;
```

### pauseSale

See [ILegionSale-pauseSale](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#pausesale).


```solidity
function pauseSale() external virtual onlyLegion;
```

### unpauseSale

See [ILegionSale-unpauseSale](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#unpausesale).


```solidity
function unpauseSale() external virtual onlyLegion;
```

### saleConfiguration

See [ILegionSale-saleConfiguration](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#saleconfiguration).


```solidity
function saleConfiguration() external view virtual returns (LegionSaleConfiguration memory);
```

### vestingConfiguration

See [ILegionSale-vestingConfiguration](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#vestingconfiguration).


```solidity
function vestingConfiguration() external view virtual returns (LegionVestingConfiguration memory);
```

### saleStatusDetails

See [ILegionSale-saleStatusDetails](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#salestatusdetails).


```solidity
function saleStatusDetails() external view virtual returns (LegionSaleStatus memory);
```

### investorPositionDetails

See [ILegionSale-investorPositionDetails](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md#investorpositiondetails).


```solidity
function investorPositionDetails(address investorAddress) external view virtual returns (InvestorPosition memory);
```

### _setLegionSaleConfig

Sets the sale and vesting params.


```solidity
function _setLegionSaleConfig(
    LegionSaleInitializationParams calldata saleInitParams,
    LegionVestingInitializationParams calldata vestingInitParams
) internal virtual onlyInitializing;
```

### _syncLegionAddresses

Sync Legion addresses from `LegionAddressRegistry`.


```solidity
function _syncLegionAddresses() internal virtual;
```

### _createVesting

Create a vesting schedule contract.


```solidity
function _createVesting(
    address _beneficiary,
    uint64 _startTimestamp,
    uint64 _durationSeconds,
    uint64 _cliffDurationSeconds
) internal virtual returns (address payable vestingInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_beneficiary`|`address`|The beneficiary.|
|`_startTimestamp`|`uint64`|The start timestamp.|
|`_durationSeconds`|`uint64`|The duration in seconds.|
|`_cliffDurationSeconds`|`uint64`|The cliff duration in seconds.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingInstance`|`address payable`|The address of the deployed vesting instance.|


### _verifyCanClaimTokenAllocation

Verify if an investor is eligible to claim tokens allocated from the sale.


```solidity
function _verifyCanClaimTokenAllocation(address _investor, uint256 _amount, bytes32[] calldata _proof)
    internal
    view
    virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor trying to participate.|
|`_amount`|`uint256`|The amount to claim.|
|`_proof`|`bytes32[]`|The merkle proof that the investor is part of the whitelist|


### _verifyCanClaimExcessCapital

Verify if an investor is eligible to get excess capital back.


```solidity
function _verifyCanClaimExcessCapital(address _investor, uint256 _amount, bytes32[] calldata _proof)
    internal
    view
    virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor trying to participate.|
|`_amount`|`uint256`|The amount to claim.|
|`_proof`|`bytes32[]`|The merkle proof that the investor is part of the whitelist|


### _verifyMinimumPledgeAmount

Verify that the amount pledge is more than the minimum required.


```solidity
function _verifyMinimumPledgeAmount(uint256 _amount) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount being pledged.|


### _verifySaleHasEnded

Verify that the sale has ended.


```solidity
function _verifySaleHasEnded() internal view virtual;
```

### _verifySaleHasNotEnded

Verify that the sale has not ended.


```solidity
function _verifySaleHasNotEnded() internal view virtual;
```

### _verifyRefundPeriodIsOver

Verify that the refund period is over.


```solidity
function _verifyRefundPeriodIsOver() internal view virtual;
```

### _verifyRefundPeriodIsNotOver

Verify that the refund period is not over.


```solidity
function _verifyRefundPeriodIsNotOver() internal view virtual;
```

### _verifyLockupPeriodIsOver

Verify that the lockup period is over.


```solidity
function _verifyLockupPeriodIsOver() internal view virtual;
```

### _verifySaleResultsArePublished

Verify if sale results are published.


```solidity
function _verifySaleResultsArePublished() internal view virtual;
```

### _verifySaleResultsNotPublished

Verify if sale results are not published.


```solidity
function _verifySaleResultsNotPublished() internal view virtual;
```

### _verifyCanSupplyTokens

Verify if the project can supply tokens for distribution.


```solidity
function _verifyCanSupplyTokens(uint256 _amount) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount to supply.|


### _verifyCanPublishSaleResults

Verify if Legion can publish sale results.


```solidity
function _verifyCanPublishSaleResults() internal view virtual;
```

### _verifyCanPublishExcessCapitalResults

Verify if Legion can publish the excess capital results.


```solidity
function _verifyCanPublishExcessCapitalResults() internal view virtual;
```

### _verifySaleNotCanceled

Verify that the sale is not canceled.


```solidity
function _verifySaleNotCanceled() internal view virtual;
```

### _verifySaleIsCanceled

Verify that the sale is canceled.


```solidity
function _verifySaleIsCanceled() internal view virtual;
```

### _verifyTokensNotSupplied

Verify that the project has not supplied tokens to the sale.


```solidity
function _verifyTokensNotSupplied() internal view virtual;
```

### _verifyTokensSupplied

Verify that the project has supplied tokens to the sale.


```solidity
function _verifyTokensSupplied() internal view virtual;
```

### _verifyLegionSignature

Verify that the signature provided is signed by Legion.


```solidity
function _verifyLegionSignature(bytes memory _signature) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_signature`|`bytes`|The signature to verify.|


### _verifyCanWithdrawCapital

Verify that the project can withdraw capital.


```solidity
function _verifyCanWithdrawCapital() internal view virtual;
```

### _verifyValidInitParams

Verify the common sale configuration is valid.


```solidity
function _verifyValidInitParams(LegionSaleInitializationParams memory saleInitParams) internal view virtual;
```

