# LegionAbstractSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/sales/LegionAbstractSale.sol)

**Inherits:**
[ILegionAbstractSale](/src/interfaces/sales/ILegionAbstractSale.sol/interface.ILegionAbstractSale.md), [LegionVestingManager](/src/vesting/LegionVestingManager.sol/abstract.LegionVestingManager.md), [LegionPositionManager](/src/position/LegionPositionManager.sol/abstract.LegionPositionManager.md), Initializable, Pausable

**Author:**
Legion

Provides core functionality for token sales in the Legion Protocol.

*Abstract base contract that implements common sale operations including investments, refunds, token
distribution, and position management using soulbound NFTs.*


## State Variables
### s_saleConfig
*Struct containing the sale configuration*


```solidity
LegionSaleConfiguration internal s_saleConfig;
```


### s_addressConfig
*Struct containing the sale addresses configuration*


```solidity
LegionSaleAddressConfiguration internal s_addressConfig;
```


### s_saleStatus
*Struct tracking the current sale status*


```solidity
LegionSaleStatus internal s_saleStatus;
```


### s_investorPositions
*Mapping of position IDs to their respective positions*


```solidity
mapping(uint256 s_positionId => InvestorPosition s_investorPosition) internal s_investorPositions;
```


## Functions
### onlyLegion

Restricts function access to the Legion bouncer only.

*Reverts if the caller is not the configured Legion bouncer.*


```solidity
modifier onlyLegion();
```

### onlyProject

Restricts function access to the project admin only.

*Reverts if the caller is not the configured project admin.*


```solidity
modifier onlyProject();
```

### onlyLegionOrProject

Restricts function access to either Legion bouncer or project admin.

*Reverts if the caller is neither project admin nor Legion bouncer.*


```solidity
modifier onlyLegionOrProject();
```

### whenSaleCanceled

Restricts interaction to when the sale is canceled.

*Reverts if the sale is not canceled.*


```solidity
modifier whenSaleCanceled();
```

### whenSaleNotCanceled

Restricts interaction to when the sale is not canceled.

*Reverts if the sale is canceled.*


```solidity
modifier whenSaleNotCanceled();
```

### whenSaleNotEnded

Restricts interaction to when the sale is not ended

*Reverts if the sale has ended.*


```solidity
modifier whenSaleNotEnded();
```

### whenRefundPeriodIsOver

Restricts interaction to when the refund period is over.

*Reverts if the refund period is not over.*


```solidity
modifier whenRefundPeriodIsOver();
```

### whenRefundPeriodNotOver

Restricts interaction to when the refund period is not over.

*Reverts if the refund period is over.*


```solidity
modifier whenRefundPeriodNotOver();
```

### whenTokensNotSupplied

Restricts interaction to when tokens have not been supplied for distribution.

*Reverts if tokens have been supplied.*


```solidity
modifier whenTokensNotSupplied();
```

### whenTokensSupplied

Restricts interaction to when tokens have been supplied for distribution.

*Reverts if tokens have not been supplied.*


```solidity
modifier whenTokensSupplied();
```

### whenSaleResultsArePublished

Restricts interaction to when the sale results have been published.

*Reverts if sale results have not been published.*


```solidity
modifier whenSaleResultsArePublished();
```

### whenSaleResultsNotPublished

Restricts interaction to when the sale results have not been published.

*Reverts if sale results have been published.*


```solidity
modifier whenSaleResultsNotPublished();
```

### constructor

Constructor for the LegionAbstractSale contract.

*Prevents the implementation contract from being initialized directly.*


```solidity
constructor();
```

### refund

Requests a refund from the sale during the refund window.


```solidity
function refund() external virtual whenNotPaused whenRefundPeriodNotOver whenSaleNotCanceled;
```

### withdrawRaisedCapital

Withdraws raised capital to the project admin.


```solidity
function withdrawRaisedCapital()
    external
    virtual
    onlyProject
    whenNotPaused
    whenRefundPeriodIsOver
    whenSaleNotCanceled
    whenSaleResultsArePublished
    whenTokensSupplied;
```

### claimTokenAllocation

Claims token allocation for an investor.


```solidity
function claimTokenAllocation(
    uint256 amount,
    LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes32[] calldata proof
)
    external
    virtual
    whenNotPaused
    whenSaleNotCanceled
    whenRefundPeriodIsOver
    whenSaleResultsArePublished;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The total amount of tokens to claim.|
|`investorVestingConfig`|`LegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`proof`|`bytes32[]`|The Merkle proof for claim verification.|


### withdrawExcessInvestedCapital

Withdraws excess invested capital back to the investor.


```solidity
function withdrawExcessInvestedCapital(
    uint256 amount,
    bytes32[] calldata proof
)
    external
    virtual
    whenNotPaused
    whenSaleNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to withdraw.|
|`proof`|`bytes32[]`|The Merkle proof for excess capital verification.|


### releaseVestedTokens

Releases vested tokens to the investor.

*Interacts with the investor's vesting contract to release available tokens.*


```solidity
function releaseVestedTokens() external virtual whenNotPaused;
```

### supplyTokens

Supplies tokens for distribution after the sale.


```solidity
function supplyTokens(
    uint256 amount,
    uint256 legionFee,
    uint256 referrerFee
)
    external
    virtual
    onlyProject
    whenNotPaused
    whenSaleNotCanceled
    whenTokensNotSupplied;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to supply.|
|`legionFee`|`uint256`|The fee amount for Legion.|
|`referrerFee`|`uint256`|The fee amount for the referrer.|


### setAcceptedCapital

Sets the Merkle root for accepted capital verification.


```solidity
function setAcceptedCapital(bytes32 merkleRoot) external virtual onlyLegion whenSaleNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The Merkle root for accepted capital verification.|


### withdrawInvestedCapitalIfCanceled

Withdraws invested capital if the sale is canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external virtual whenNotPaused whenSaleCanceled;
```

### emergencyWithdraw

Performs an emergency withdrawal of tokens.


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external virtual onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to receive tokens.|
|`token`|`address`|The address of the token to withdraw.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external virtual onlyLegion;
```

### pause

Pauses all sale operations.


```solidity
function pause() external virtual onlyLegion;
```

### unpause

Resumes all sale operations.


```solidity
function unpause() external virtual onlyLegion;
```

### transferInvestorPosition


```solidity
function transferInvestorPosition(
    address from,
    address to,
    uint256 positionId
)
    external
    virtual
    override
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenRefundPeriodIsOver
    whenSaleResultsNotPublished;
```

### transferInvestorPositionWithAuthorization


```solidity
function transferInvestorPositionWithAuthorization(
    address from,
    address to,
    uint256 positionId,
    bytes calldata transferSignature
)
    external
    virtual
    override
    whenNotPaused
    whenSaleNotCanceled
    whenRefundPeriodIsOver
    whenSaleResultsNotPublished;
```

### saleConfiguration

Returns the current sale configuration.


```solidity
function saleConfiguration() external view virtual returns (LegionSaleConfiguration memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LegionSaleConfiguration`|The complete sale configuration struct.|


### saleStatus

Returns the current sale status.


```solidity
function saleStatus() external view virtual returns (LegionSaleStatus memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LegionSaleStatus`|The complete sale status struct.|


### investorPosition

Returns an investor's position details.


```solidity
function investorPosition(address investor) external view virtual returns (InvestorPosition memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`InvestorPosition`|The complete investor position struct.|


### investorVestingStatus

Returns an investor's vesting status.


```solidity
function investorVestingStatus(address investor)
    external
    view
    virtual
    returns (LegionInvestorVestingStatus memory vestingStatus);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingStatus`|`LegionInvestorVestingStatus`|The complete vesting status including timestamps, amounts, and release information.|


### cancel

Cancels the ongoing sale.

*Allows cancellation before results are published; only callable by the project admin.*


```solidity
function cancel() public virtual onlyProject whenNotPaused whenSaleResultsNotPublished whenSaleNotCanceled;
```

### _setLegionSaleConfig

Sets the sale parameters during initialization

*Virtual function to configure sale*


```solidity
function _setLegionSaleConfig(LegionSaleInitializationParams calldata _saleInitParams)
    internal
    virtual
    onlyInitializing;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_saleInitParams`|`LegionSaleInitializationParams`|Calldata struct with initialization parameters|


### _syncLegionAddresses

*Synchronizes Legion addresses from the address registry.*


```solidity
function _syncLegionAddresses() internal virtual;
```

### _burnOrTransferInvestorPosition

*Burns or transfers an investor position based on receiver's existing position.*


```solidity
function _burnOrTransferInvestorPosition(address _from, address _to, uint256 _positionId) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The address of the current owner.|
|`_to`|`address`|The address of the new owner.|
|`_positionId`|`uint256`|The ID of the position to transfer or burn.|


### _verifyCanClaimTokenAllocation

*Verifies investor eligibility to claim token allocation using Merkle proof.*


```solidity
function _verifyCanClaimTokenAllocation(
    address _investor,
    uint256 _amount,
    LegionVestingManager.LegionInvestorVestingConfig calldata _investorVestingConfig,
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
|`_amount`|`uint256`|The amount of tokens to claim.|
|`_investorVestingConfig`|`LegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`_proof`|`bytes32[]`|The Merkle proof for claim verification.|


### _verifyCanClaimExcessCapital

*Verifies investor eligibility to claim excess capital using Merkle proof.*


```solidity
function _verifyCanClaimExcessCapital(
    address _investor,
    uint256 _positionId,
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
|`_investor`|`address`|The address of the investor.|
|`_positionId`|`uint256`|The position ID of the investor.|
|`_amount`|`uint256`|The amount of excess capital to claim.|
|`_proof`|`bytes32[]`|The Merkle proof for excess capital verification.|


### _verifyValidInitParams

*Validates the sale initialization parameters.*


```solidity
function _verifyValidInitParams(LegionSaleInitializationParams calldata _saleInitParams) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_saleInitParams`|`LegionSaleInitializationParams`|The initialization parameters to validate.|


### _verifyMinimumInvestAmount

*Verifies that the invested amount meets the minimum requirement.*


```solidity
function _verifyMinimumInvestAmount(uint256 _amount) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount being invested.|


### _verifySaleHasNotEnded

*Verifies that the sale has not ended.*


```solidity
function _verifySaleHasNotEnded() internal view virtual;
```

### _verifyRefundPeriodIsOver

*Verifies that the refund period has ended.*


```solidity
function _verifyRefundPeriodIsOver() internal view virtual;
```

### _verifyRefundPeriodIsNotOver

*Verifies that the refund period is still active.*


```solidity
function _verifyRefundPeriodIsNotOver() internal view virtual;
```

### _verifySaleResultsArePublished

*Verifies that sale results have been published.*


```solidity
function _verifySaleResultsArePublished() internal view virtual;
```

### _verifySaleResultsNotPublished

*Verifies that sale results have not been published.*


```solidity
function _verifySaleResultsNotPublished() internal view virtual;
```

### _verifyCanSupplyTokens

*Verifies conditions for supplying tokens.*


```solidity
function _verifyCanSupplyTokens(uint256 _amount) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount of tokens to supply.|


### _verifyCanPublishSaleResults

*Verifies conditions for publishing sale results.*


```solidity
function _verifyCanPublishSaleResults() internal view virtual;
```

### _verifySaleNotCanceled

*Verifies that the sale is not canceled.*


```solidity
function _verifySaleNotCanceled() internal view virtual;
```

### _verifySaleIsCanceled

*Verifies that the sale is canceled.*


```solidity
function _verifySaleIsCanceled() internal view virtual;
```

### _verifyTokensNotSupplied

*Verifies that tokens have not been supplied.*


```solidity
function _verifyTokensNotSupplied() internal view virtual;
```

### _verifyTokensSupplied

*Verifies that tokens have been supplied.*


```solidity
function _verifyTokensSupplied() internal view virtual;
```

### _verifyInvestSignature

*Verifies that an investment signature is valid.*


```solidity
function _verifyInvestSignature(bytes calldata _signature) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_signature`|`bytes`|The signature to verify.|


### _verifyCanWithdrawCapital

*Verifies conditions for withdrawing capital.*


```solidity
function _verifyCanWithdrawCapital() internal view virtual;
```

### _verifyHasNotRefunded

*Verifies that the investor has not refunded.*


```solidity
function _verifyHasNotRefunded(uint256 _positionId) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The ID of the investor's position.|


### _verifyHasNotClaimedExcess

*Verifies that the investor has not claimed excess capital.*


```solidity
function _verifyHasNotClaimedExcess(uint256 _positionId) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The ID of the investor's position.|


### _verifyCanTransferInvestorPosition

*Verifies conditions for transferring an investor position.*


```solidity
function _verifyCanTransferInvestorPosition(uint256 _positionId) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The ID of the investor's position.|


