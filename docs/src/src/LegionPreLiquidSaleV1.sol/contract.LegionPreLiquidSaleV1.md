# LegionPreLiquidSaleV1
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/ac3edaa080a44c4acca1531370a76a05f05491f5/src/LegionPreLiquidSaleV1.sol)

**Inherits:**
[ILegionPreLiquidSaleV1](/src/interfaces/ILegionPreLiquidSaleV1.sol/interface.ILegionPreLiquidSaleV1.md), Initializable, Pausable

A contract used to execute pre-liquid sales of ERC20 tokens before TGE


## State Variables
### saleConfig
*A struct describing the sale configuration.*


```solidity
PreLiquidSaleConfig internal saleConfig;
```


### vestingConfig
*A struct describing the vesting configuration.*


```solidity
PreLiquidSaleVestingConfig internal vestingConfig;
```


### saleStatus
*A struct describing the sale status.*


```solidity
PreLiquidSaleStatus internal saleStatus;
```


### investorPositions
*Mapping of investor address to investor position.*


```solidity
mapping(address investorAddress => InvestorPosition investorPosition) public investorPositions;
```


### usedSignatures
*Mapping of used signatures to prevent replay attacks.*


```solidity
mapping(address investorAddress => mapping(bytes signature => bool used) usedSignature) usedSignatures;
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

LegionPreLiquidSale constructor.


```solidity
constructor();
```

### initialize

Disable initialization

Initializes the contract with correct parameters.


```solidity
function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The pre-liquid sale initialization parameters.|


### invest

Invest capital to the pre-liquid sale.


```solidity
function invest(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes memory signature
)
    external
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.|
|`signature`|`bytes`|The signature proving that the investor is allowed to participate.|


### refund

Verify that the sale is not canceled
Verify that the signature has not been used
Load the investor position
Increment total capital invested from investors
Increment total capital for the investor
Mark the signature as used
Cache the SAFT amount the investor is allowed to invest
Cache the token allocation rate in 18 decimals precision
Cache the hash of the SAFT signed by the investor
Verify that the investor position is valid
Emit successfully CapitalInvested
Transfer the invested capital to the contract

Get a refund from the sale during the applicable time window.


```solidity
function refund() external whenNotPaused;
```

### publishTgeDetails

Verify that the sale is not canceled
Verify that the investor can get a refund
Load the investor position
Cache the amount to refund in memory
Revert in case there's nothing to refund
Set the total invested capital for the investor to 0
Decrement total capital invested from investors
Emit successfully CapitalRefunded
Transfer the refunded amount back to the investor

Updates the token details after Token Generation Event (TGE).

*Only callable by Legion.*


```solidity
function publishTgeDetails(
    address _askToken,
    uint256 _askTokenTotalSupply,
    uint256 _vestingStartTime,
    uint256 _totalTokensAllocated
)
    external
    onlyLegion
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_askToken`|`address`|The address of the token distributed to investors.|
|`_askTokenTotalSupply`|`uint256`|The total supply of the token distributed to investors.|
|`_vestingStartTime`|`uint256`|The Unix timestamp (seconds) of the block when the vesting starts.|
|`_totalTokensAllocated`|`uint256`|The allocated token amount for distribution to investors.|


### supplyAskTokens

Verify that the sale has not been canceled
Verify that the sale has ended
Veriify that the refund period is over
Set the address of the token distributed to investors
Set the total supply of the token distributed to investors
Set the vesting start time block timestamp
Set the total allocated amount of token for distribution.
Emit successfully TgeDetailsPublished

Supply tokens for distribution after the Token Generation Event (TGE).

*Only callable by the Project.*


```solidity
function supplyAskTokens(
    uint256 amount,
    uint256 legionFee,
    uint256 referrerFee
)
    external
    onlyProject
    whenNotPaused
    askTokenAvailable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to be supplied for distribution.|
|`legionFee`|`uint256`|The Legion fee token amount.|
|`referrerFee`|`uint256`|The Referrer fee token amount.|


### updateVestingTerms

Verify that the sale is not canceled
Verify that tokens can be supplied for distribution
Calculate and verify Legion Fee
Calculate and verify Legion Fee
Flag that ask tokens have been supplied
Emit successfully TokensSuppliedForDistribution
Transfer the allocated amount of tokens for distribution
Transfer the Legion fee to the Legion fee receiver address
Transfer the Legion fee to the Legion fee receiver address

Updates the vesting terms.

*Only callable by Legion, before the tokens have been supplied by the Project.*


```solidity
function updateVestingTerms(
    uint256 _vestingDurationSeconds,
    uint256 _vestingCliffDurationSeconds,
    uint256 _tokenAllocationOnTGERate
)
    external
    onlyProject
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_vestingDurationSeconds`|`uint256`|The vesting schedule duration for the token sold in seconds.|
|`_vestingCliffDurationSeconds`|`uint256`|The vesting cliff duration for the token sold in seconds.|
|`_tokenAllocationOnTGERate`|`uint256`|The token allocation amount released to investors after TGE in 18 decimals precision.|


### emergencyWithdraw

Verify that the sale is not canceled
Verify that the project has not withdrawn any capital
Verify that tokens for distribution have not been allocated
Set the vesting duration in seconds
Set the vesting cliff duration in seconds
Set the token allocation on TGE
Verify that the vesting configuration is valid
Emit successfully VestingTermsUpdated

Withdraw tokens from the contract in case of emergency.

*Can be called only by the Legion admin address.*


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address of the receiver.|
|`token`|`address`|The address of the token to be withdrawn.|
|`amount`|`uint256`|The amount to be withdrawn.|


### withdrawRaisedCapital

Emit successfully EmergencyWithdraw
Transfer the amount to Legion's address

Withdraw capital from the contract.

*Can be called only by the Project admin address.*


```solidity
function withdrawRaisedCapital() external onlyProject whenNotPaused;
```

### claimAskTokenAllocation

Verify that the sale is not canceled
Verify that the sale has ended
Verify that the project can withdraw capital
Account for the capital withdrawn
Calculate Legion Fee
Calculate Referrer Fee
Emit successfully CapitalWithdrawn
Transfer the amount to the Project's address
Transfer the Legion fee to the Legion fee receiver address
Transfer the Referrer fee to the Referrer fee receiver address

Claim token allocation by investors.


```solidity
function claimAskTokenAllocation(
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes memory signature
)
    external
    whenNotPaused
    askTokenAvailable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.|
|`signature`|`bytes`|The signature proving that the investor has signed a SAFT.|


### cancelSale

Verify that the sale has not been canceled
Load the investor position
Cache the SAFT amount the investor is allowed to invest
Cache the token allocation rate in 18 decimals precision
Cache the hash of the SAFT signed by the investor
Verify that the investor can claim the token allocation
Verify that the investor position is valid
Verify that the signature has not been used
Mark the signature as used
Mark that the token amount has been settled
Calculate the total token amount to be claimed
Calculate the amount to be distributed on claim
Calculate the remaining amount to be vested
Emit successfully TokenAllocationClaimed
Deploy a linear vesting schedule contract
Save the vesting address for the investor
Transfer the allocated amount of tokens for distribution
Transfer the allocated amount of tokens for distribution on claim

Cancel the sale.

*Can be called only by the Project admin address.*


```solidity
function cancelSale() external onlyProject whenNotPaused;
```

### withdrawCapitalIfSaleIsCanceled

Verify that the sale has not been canceled
Verify that no tokens have been supplied to the sale by the Project
Cache the amount of funds to be returned to the sale
Mark the sale as canceled
Emit successfully CapitalWithdrawn
In case there's capital to return, transfer the funds back to the contract
Set the totalCapitalWithdrawn to zero
Transfer the allocated amount of tokens for distribution

Withdraw capital if the sale has been canceled.


```solidity
function withdrawCapitalIfSaleIsCanceled() external whenNotPaused;
```

### withdrawExcessCapital

Verify that the sale has been actually canceled
Cache the amount to refund in memory
Revert in case there's nothing to claim
Set the total pledged capital for the investor to 0
Decrement total capital pledged from investors
Emit successfully CapitalRefundedAfterCancel
Transfer the refunded amount back to the investor

Withdraw back excess capital from investors.


```solidity
function withdrawExcessCapital(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes memory signature
)
    external
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to be withdrawn.|
|`investAmount`|`uint256`|The amount of capital the investor is allowed to invest, according to the SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation the investor will receive as a percentage of totalSupply, represented in 18 decimals precision.|
|`saftHash`|`bytes32`|The hash of the Simple Agreement for Future Tokens (SAFT) signed by the investor.|
|`signature`|`bytes`|The signature proving that the investor is allowed to participate.|


### releaseTokens

Verify that the sale has not been canceled
Verify that the signature has not been used
Load the investor position
Decrement total capital invested from investors
Decrement total investor capital for the investor
Mark the signature as used
Cache the maximum amount the investor is allowed to invest
Cache the token allocation rate in 18 decimals precision
Cache the hash of the SAFT signed by the investor
Verify that the investor position is valid
Emit successfully ExcessCapitalWithdrawn
Transfer the excess capital to the investor

Releases tokens from vesting to the investor address.


```solidity
function releaseTokens() external whenNotPaused askTokenAvailable;
```

### endSale

Get the investor position details
Revert in case there's no vesting for the investor
Release tokens to the investor account

Ends the sale.


```solidity
function endSale() external onlyLegionOrProject whenNotPaused;
```

### publishCapitalRaised

Verify that the sale has not been canceled
Emit successfully SaleEnded

Publish the total capital raised by the project.


```solidity
function publishCapitalRaised(uint256 capitalRaised) external onlyLegion whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|


### syncLegionAddresses

Syncs active Legion addresses from `LegionAddressRegistry.sol`.


```solidity
function syncLegionAddresses() external onlyLegion;
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
function saleConfiguration() external view returns (PreLiquidSaleConfig memory);
```

### saleStatusDetails

Get the pre-liquid sale config

Returns the sale status details.


```solidity
function saleStatusDetails() external view returns (PreLiquidSaleStatus memory);
```

### vestingConfiguration

Get the pre-liquid sale status

Returns the sale vesting configuration.


```solidity
function vestingConfiguration() external view returns (PreLiquidSaleVestingConfig memory);
```

### investorPositionDetails

Get the pre-liquid sale vesting config

Returns an investor position details.


```solidity
function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);
```

### _createVesting

Create a vesting schedule contract.


```solidity
function _createVesting(
    address _beneficiary,
    uint64 _startTimestamp,
    uint64 _durationSeconds,
    uint64 _cliffDurationSeconds
)
    internal
    returns (address payable vestingInstance);
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


### _setLegionSaleConfig

Deploy a vesting schedule instance

Sets the sale and vesting params.


```solidity
function _setLegionSaleConfig(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams)
    internal
    virtual
    onlyInitializing;
```

### _syncLegionAddresses

Verify if the sale configuration is valid
Initialize pre-liquid sale configuration
Initialize pre-liquid sale vesting configuration
Verify that the vesting configuration is valid
Cache Legion addresses from `LegionAddressRegistry`

Sync Legion addresses from `LegionAddressRegistry`.


```solidity
function _syncLegionAddresses() internal virtual;
```

### _verifyValidConfig

Verify if the sale configuration is valid.


```solidity
function _verifyValidConfig(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The configuration for the pre-liquid sale.|


### _verifyCanSupplyTokens

Check for zero addresses provided
Check for zero values provided
Check if the refund period is within range

Verify if the project can supply tokens for distribution.


```solidity
function _verifyCanSupplyTokens(uint256 _amount) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount to supply.|


### _verifyTokensNotAllocated

Revert if Legion has not set the total amount of tokens allocated for distribution
Revert if tokens have already been supplied
Revert if the amount of tokens supplied is different than the amount set by Legion

Verify if the tokens for distribution have not been allocated.


```solidity
function _verifyTokensNotAllocated() private view;
```

### _verifySaleNotCanceled

Revert if the tokens for distribution have already been allocated

Verify that the sale is not canceled.


```solidity
function _verifySaleNotCanceled() internal view;
```

### _verifySaleIsCanceled

Verify that the sale is canceled.


```solidity
function _verifySaleIsCanceled() internal view;
```

### _verifyNoCapitalWithdrawn

Verify that the Project has not withdrawn any capital.


```solidity
function _verifyNoCapitalWithdrawn() internal view;
```

### _verifySaleHasNotEnded

Verify that the sale has not ended.


```solidity
function _verifySaleHasNotEnded() internal view;
```

### _verifySaleHasEnded

Verify that the sale has ended.


```solidity
function _verifySaleHasEnded() internal view;
```

### _verifyCanClaimTokenAllocation

Verify if an investor is eligible to claim token allocation.


```solidity
function _verifyCanClaimTokenAllocation() internal view;
```

### _verifyAskTokensNotSupplied

Load the investor position
Check if the askToken has been supplied to the sale
Check if the investor has already settled their allocation

Verify that the project has not supplied ask tokens to the sale.


```solidity
function _verifyAskTokensNotSupplied() internal view virtual;
```

### _verifySignatureNotUsed

Verify that the signature has not been used.


```solidity
function _verifySignatureNotUsed(bytes memory signature) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signature`|`bytes`|The signature proving the investor is part of the whitelist|


### _verifyCanWithdrawCapital

Check if the signature is used

Verify that the project can withdraw capital.


```solidity
function _verifyCanWithdrawCapital() internal view virtual;
```

### _verifyRefundPeriodIsOver

Verify that the refund period is over.


```solidity
function _verifyRefundPeriodIsOver() internal view;
```

### _verifyRefundPeriodIsNotOver

Verify that the refund period is not over.


```solidity
function _verifyRefundPeriodIsNotOver() internal view;
```

### _verifyHasNotRefunded

Verify that the investor has not received a refund.


```solidity
function _verifyHasNotRefunded() internal view virtual;
```

### _verifyCanPublishCapitalRaised

Verify that capital raised can be published.


```solidity
function _verifyCanPublishCapitalRaised() internal view;
```

### _verifyValidVestingConfig

Verify that the vesting configuration is valid.


```solidity
function _verifyValidVestingConfig() internal view virtual;
```

### _verifyValidPosition

Check if vesting duration is no more than 10 years, if vesting cliff duration is not more than vesting
duration or the token allocation on TGE rate is no more than 100%

Verify if the investor position is valid


```solidity
function _verifyValidPosition(bytes memory signature, SaleAction actionType) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signature`|`bytes`|The signature proving the investor is part of the whitelist|
|`actionType`|`SaleAction`|The type of sale action|


