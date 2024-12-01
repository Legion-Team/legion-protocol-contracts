# LegionPreLiquidSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionPreLiquidSale.sol)

**Inherits:**
[ILegionPreLiquidSale](/src/interfaces/ILegionPreLiquidSale.sol/interface.ILegionPreLiquidSale.md), Initializable, Pausable

**Author:**
Legion.

A contract used to execute pre-liquid sales of ERC20 tokens before TGE.


## State Variables
### saleConfig
*A struct describing the pre-liquid sale configuration.*


```solidity
PreLiquidSaleConfiguration private saleConfig;
```


### vestingConfig
*A struct describing the vesting configuration.*


```solidity
LegionVestingConfiguration private vestingConfig;
```


### saleStatus
*A struct describing the pre-liquid sale status.*


```solidity
PreLiquidSaleStatus private saleStatus;
```


### investorPositions
*Mapping of investor address to investor position.*


```solidity
mapping(address investorAddress => InvestorPosition investorPosition) private investorPositions;
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

### constructor

LegionPreLiquidSale constructor.


```solidity
constructor();
```

### initialize

See [ILegionPreLiquidSale-initialize](/src/LegionLinearVesting.sol/contract.LegionLinearVesting.md#initialize).


```solidity
function initialize(
    PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams,
    LegionVestingInitializationParams calldata vestingInitParams
) external initializer;
```

### invest

See [ILegionPreLiquidSale-invest](/src/LegionSealedBidAuctionSale.sol/contract.LegionSealedBidAuctionSale.md#invest).


```solidity
function invest(
    uint256 amount,
    uint256 saftInvestAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes32[] calldata proof
) external whenNotPaused;
```

### refund

Cache the token allocation rate in 18 decimals precision
Emit successfully CapitalInvested

See [ILegionPreLiquidSale-refund](/src/LegionSale.sol/abstract.LegionSale.md#refund).


```solidity
function refund() external whenNotPaused;
```

### publishTgeDetails

See {ILegionPreLiquidSale-setTokenDetails}.


```solidity
function publishTgeDetails(
    address _askToken,
    uint256 _askTokenTotalSupply,
    uint256 _vestingStartTime,
    uint256 _totalTokensAllocated
) external onlyLegion;
```

### supplyTokens

Set the address of the token ditributed to investors

See [ILegionPreLiquidSale-supplyTokens](/src/LegionSale.sol/abstract.LegionSale.md#supplytokens).


```solidity
function supplyTokens(uint256 amount, uint256 legionFee) external onlyProject whenNotPaused;
```

### updateSAFTMerkleRoot

See [ILegionPreLiquidSale-updateSAFTMerkleRoot](/src/interfaces/ILegionPreLiquidSale.sol/interface.ILegionPreLiquidSale.md#updatesaftmerkleroot).


```solidity
function updateSAFTMerkleRoot(bytes32 merkleRoot) external onlyLegion;
```

### updateVestingTerms

See [ILegionPreLiquidSale-updateVestingTerms](/src/interfaces/ILegionPreLiquidSale.sol/interface.ILegionPreLiquidSale.md#updatevestingterms).


```solidity
function updateVestingTerms(
    uint256 _vestingDurationSeconds,
    uint256 _vestingCliffDurationSeconds,
    uint256 _tokenAllocationOnTGERate
) external onlyProject whenNotPaused;
```

### emergencyWithdraw

Verify that the sale is not canceled
Set the token allocation on TGE
Emit successfully VestingTermsUpdated

See [ILegionPreLiquidSale-emergencyWithdraw](/src/LegionSale.sol/abstract.LegionSale.md#emergencywithdraw).


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion;
```

### withdrawRaisedCapital

See [ILegionPreLiquidSale-withdrawRaisedCapital](/src/LegionSale.sol/abstract.LegionSale.md#withdrawraisedcapital).


```solidity
function withdrawRaisedCapital(address[] calldata investors)
    external
    onlyProject
    whenNotPaused
    returns (uint256 amount);
```

### claimTokenAllocation

See [ILegionPreLiquidSale-claimTokenAllocation](/src/LegionSale.sol/abstract.LegionSale.md#claimtokenallocation).


```solidity
function claimTokenAllocation(bytes32[] calldata proof) external whenNotPaused;
```

### cancelSale

Calculate the total token amount to be claimed
Calculate the amount to be distributed on claim

See [ILegionPreLiquidSale-cancelSale](/src/LegionSealedBidAuctionSale.sol/contract.LegionSealedBidAuctionSale.md#cancelsale).


```solidity
function cancelSale() external onlyProject whenNotPaused;
```

### withdrawInvestedCapitalIfCanceled

See {ILegionPreLiquidSale-claimBackCapitalIfSaleIsCanceled}.


```solidity
function withdrawInvestedCapitalIfCanceled() external whenNotPaused;
```

### withdrawExcessInvestedCapital

See [ILegionPreLiquidSale-withdrawExcessInvestedCapital](/src/LegionSale.sol/abstract.LegionSale.md#withdrawexcessinvestedcapital).


```solidity
function withdrawExcessInvestedCapital(
    uint256 amount,
    uint256 saftInvestAmount,
    uint256 tokenAllocationRate,
    bytes32 saftHash,
    bytes32[] calldata proof
) external whenNotPaused;
```

### releaseVestedTokens

Cache the token allocation rate in 18 decimals precision
Emit successfully ExcessCapitalWithdrawn

See [ILegionPreLiquidSale-releaseVestedTokens](/src/LegionSale.sol/abstract.LegionSale.md#releasevestedtokens).


```solidity
function releaseVestedTokens() external whenNotPaused;
```

### toggleInvestmentAccepted

See [ILegionPreLiquidSale-toggleInvestmentAccepted](/src/interfaces/ILegionPreLiquidSale.sol/interface.ILegionPreLiquidSale.md#toggleinvestmentaccepted).


```solidity
function toggleInvestmentAccepted() external onlyProject whenNotPaused;
```

### syncLegionAddresses

See [ILegionPreLiquidSale-syncLegionAddresses](/src/LegionSale.sol/abstract.LegionSale.md#synclegionaddresses).


```solidity
function syncLegionAddresses() external onlyLegion;
```

### pauseSale

See [ILegionPreLiquidSale-pauseSale](/src/LegionSale.sol/abstract.LegionSale.md#pausesale).


```solidity
function pauseSale() external onlyLegion;
```

### unpauseSale

See [ILegionPreLiquidSale-unpauseSale](/src/LegionSale.sol/abstract.LegionSale.md#unpausesale).


```solidity
function unpauseSale() external onlyLegion;
```

### saleConfiguration

See [ILegionSale-saleConfiguration](/src/LegionSale.sol/abstract.LegionSale.md#saleconfiguration).


```solidity
function saleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
```

### vestingConfiguration

See [ILegionSale-vestingConfiguration](/src/LegionSale.sol/abstract.LegionSale.md#vestingconfiguration).


```solidity
function vestingConfiguration() external view returns (LegionVestingConfiguration memory);
```

### saleStatusDetails

See [ILegionSale-saleStatusDetails](/src/LegionSale.sol/abstract.LegionSale.md#salestatusdetails).


```solidity
function saleStatusDetails() external view returns (PreLiquidSaleStatus memory);
```

### investorPositionDetails

See [ILegionSale-investorPositionDetails](/src/LegionSale.sol/abstract.LegionSale.md#investorpositiondetails).


```solidity
function investorPositionDetails(address investorAddress) external view returns (InvestorPosition memory);
```

### _syncLegionAddresses

Sync Legion addresses from `LegionAddressRegistry`.


```solidity
function _syncLegionAddresses() private;
```

### _createVesting

Create a vesting schedule contract.


```solidity
function _createVesting(
    address _beneficiary,
    uint64 _startTimestamp,
    uint64 _durationSeconds,
    uint64 _cliffDurationSeconds
) private returns (address payable vestingInstance);
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


### _verifyCanWithdrawInvestorPosition


```solidity
function _verifyCanWithdrawInvestorPosition(address _investor) private view;
```

### _verifyRefundPeriodIsNotOver

Verify that the refund period is not over.


```solidity
function _verifyRefundPeriodIsNotOver(address _investor) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor|


### _verifyRefundPeriodIsOver

Verify that the refund period is over.


```solidity
function _verifyRefundPeriodIsOver(address _investor) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor|


### _verifyCanSupplyTokens

Verify if the project can supply tokens for distribution.


```solidity
function _verifyCanSupplyTokens(uint256 _amount) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount to supply.|


### _verifyTokensNotAllocated

Verify if the tokens for distribution have not been allocated.


```solidity
function _verifyTokensNotAllocated() private view;
```

### _verifySaleNotCanceled

Verify that the sale is not canceled.


```solidity
function _verifySaleNotCanceled() private view;
```

### _verifySaleIsCanceled

Verify that the sale is canceled.


```solidity
function _verifySaleIsCanceled() private view;
```

### _verifyNoCapitalWithdrawn

Verify that the Project has not withdrawn any capital.


```solidity
function _verifyNoCapitalWithdrawn() private view;
```

### _verifyCanClaimTokenAllocation

Verify if an investor is eligible to claim token allocation.


```solidity
function _verifyCanClaimTokenAllocation(address _investor) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|


### _verifyInvestmentAccepted

Verify that the Project has not accepted the investment round.


```solidity
function _verifyInvestmentAccepted() private view;
```

### _verifyAskTokensNotSupplied

Verify that the project has not supplied ask tokens to the sale.


```solidity
function _verifyAskTokensNotSupplied() private view;
```

### _verifyValidPosition

Verify if the investor position is valid


```solidity
function _verifyValidPosition(address _investor, bytes32[] calldata _proof) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|
|`_proof`|`bytes32[]`|The merkle proof that the investor is part of the whitelist|


### _verifyValidParams

Verify if the sale configuration is valid.


```solidity
function _verifyValidParams(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) private pure;
```

