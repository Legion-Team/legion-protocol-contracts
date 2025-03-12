# LegionSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/a0becaf0413338ea78e3b0a0ce4527f7e1695849/src/LegionSale.sol)

**Inherits:**
[ILegionSale](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md), [LegionVestingManager](/src/vesting/LegionVestingManager.sol/abstract.LegionVestingManager.md), Initializable, Pausable

**Author:**
Legion

A contract used for managing token sales in the Legion Protocol


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

### onlyLegionOrProject

Throws if called by any account other than Legion or the Project.


```solidity
modifier onlyLegionOrProject();
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

Request a refund from the sale during the applicable time window.


```solidity
function refund() external virtual whenNotPaused;
```

### withdrawRaisedCapital

Withdraw raised capital from the sale contract.

*Can be called only by the Project admin address.*


```solidity
function withdrawRaisedCapital() external virtual onlyProject whenNotPaused;
```

### claimTokenAllocation

Claims the investor token allocation.


```solidity
function claimTokenAllocation(
    uint256 amount,
    LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes32[] calldata proof
)
    external
    virtual
    askTokenAvailable
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount to be distributed.|
|`investorVestingConfig`|`LegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`proof`|`bytes32[]`|The merkle proof verification for claiming.|


### withdrawExcessInvestedCapital

Load the investor position

Withdraw excess capital back to the investor.


```solidity
function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external virtual whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount to be returned.|
|`proof`|`bytes32[]`|The merkle proof verification for the return.|


### releaseVestedTokens

Releases tokens to the investor address.


```solidity
function releaseVestedTokens() external virtual askTokenAvailable whenNotPaused;
```

### supplyTokens

Supply tokens once the sale results have been published.

*Can be called only by the Project admin address.*


```solidity
function supplyTokens(
    uint256 amount,
    uint256 legionFee,
    uint256 referrerFee
)
    external
    virtual
    onlyProject
    askTokenAvailable
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The token amount supplied by the project.|
|`legionFee`|`uint256`|The legion fee token amount supplied by the project.|
|`referrerFee`|`uint256`|The referrer fee token amount supplied by the project.|


### setAcceptedCapital

Publish merkle root for accepted capital.

*Can be called only by the Legion admin address.*


```solidity
function setAcceptedCapital(bytes32 merkleRoot) external virtual onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The merkle root to verify against.|


### cancelSale

Cancels an ongoing sale.

*Can be called only by the Project admin address.*


```solidity
function cancelSale() public virtual onlyProject whenNotPaused;
```

### withdrawInvestedCapitalIfCanceled

Withdraws back capital in case the sale has been canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external virtual whenNotPaused;
```

### emergencyWithdraw

Withdraw tokens from the contract in case of emergency.

*Can be called only by the Legion admin address.*


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external virtual onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address of the receiver.|
|`token`|`address`|The address of the token to be withdrawn.|
|`amount`|`uint256`|The amount to be withdrawn.|


### syncLegionAddresses

Syncs active Legion addresses from `LegionAddressRegistry.sol`.


```solidity
function syncLegionAddresses() external virtual onlyLegion;
```

### pauseSale

Pauses the sale.


```solidity
function pauseSale() external virtual onlyLegion;
```

### unpauseSale

Unpauses the sale.


```solidity
function unpauseSale() external virtual onlyLegion;
```

### saleConfiguration

Returns the sale configuration.


```solidity
function saleConfiguration() external view virtual returns (LegionSaleConfiguration memory);
```

### vestingConfiguration

Returns the vesting configuration.


```solidity
function vestingConfiguration() external view virtual returns (LegionVestingConfig memory);
```

### saleStatusDetails

Returns the sale status details.


```solidity
function saleStatusDetails() external view virtual returns (LegionSaleStatus memory);
```

### investorPositionDetails

Returns an investor position.


```solidity
function investorPositionDetails(address investorAddress) external view virtual returns (InvestorPosition memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investorAddress`|`address`|The address of the investor.|


### investorVestingStatus

Returns the investor vesting status.


```solidity
function investorVestingStatus(address investor)
    external
    view
    returns (LegionInvestorVestingStatus memory vestingStatus);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|


### _setLegionSaleConfig

Get the investor position details

Sets the sale and vesting params.


```solidity
function _setLegionSaleConfig(LegionSaleInitializationParams calldata saleInitParams)
    internal
    virtual
    onlyInitializing;
```

### _syncLegionAddresses

Sync the Legion addresses from `LegionAddressRegistry`.


```solidity
function _syncLegionAddresses() internal virtual;
```

### _verifyCanClaimTokenAllocation

Verify if an investor is eligible to claim tokens allocated from the sale.


```solidity
function _verifyCanClaimTokenAllocation(
    address _investor,
    uint256 _amount,
    LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes32[] calldata _proof
)
    internal
    view
    virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|
|`_amount`|`uint256`|The amount to claim.|
|`investorVestingConfig`|`LegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`_proof`|`bytes32[]`|The Merkle proof that the investor is part of the whitelist.|


### _verifyCanClaimExcessCapital

Verify if an investor is eligible to get excess capital back.


```solidity
function _verifyCanClaimExcessCapital(
    address _investor,
    uint256 _amount,
    bytes32[] calldata _proof
)
    internal
    view
    virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor trying to participate.|
|`_amount`|`uint256`|The amount to claim.|
|`_proof`|`bytes32[]`|The Merkle proof that the investor is part of the whitelist.|


### _verifyMinimumInvestAmount

Verify that the amount invested is more than the minimum required.


```solidity
function _verifyMinimumInvestAmount(uint256 _amount) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount being invested.|


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

### _verifyHasNotRefunded

Verify that the investor has not received a refund.


```solidity
function _verifyHasNotRefunded() internal view virtual;
```

### _verifyHasNotClaimedExcess

Verify that the investor has not claimed excess capital.


```solidity
function _verifyHasNotClaimedExcess() internal view virtual;
```

### _verifyValidInitParams

Verify the common sale configuration is valid.


```solidity
function _verifyValidInitParams(LegionSaleInitializationParams memory saleInitParams) internal view virtual;
```

