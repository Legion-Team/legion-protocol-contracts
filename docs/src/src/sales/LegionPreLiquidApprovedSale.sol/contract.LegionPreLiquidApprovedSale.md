# LegionPreLiquidApprovedSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/sales/LegionPreLiquidApprovedSale.sol)

**Inherits:**
[ILegionPreLiquidApprovedSale](/src/interfaces/sales/ILegionPreLiquidApprovedSale.sol/interface.ILegionPreLiquidApprovedSale.md), [LegionVestingManager](/src/vesting/LegionVestingManager.sol/abstract.LegionVestingManager.md), [LegionPositionManager](/src/position/LegionPositionManager.sol/abstract.LegionPositionManager.md), Initializable, Pausable

**Author:**
Legion

Executes pre-liquid sales of ERC20 tokens before Token Generation Event (TGE).

*Manages pre-liquid sale lifecycle including investment, refunds, token supply, and vesting with signature-based
authorization.*


## State Variables
### s_saleConfig
*Struct containing the pre-liquid sale configuration.*


```solidity
PreLiquidSaleConfig private s_saleConfig;
```


### s_saleStatus
*Struct tracking the current sale status.*


```solidity
PreLiquidSaleStatus private s_saleStatus;
```


### s_investorPositions
*Mapping of position IDs to their respective positions.*


```solidity
mapping(uint256 s_positionId => InvestorPosition s_investorPosition) private s_investorPositions;
```


### s_usedSignatures
*Mapping to track used signatures per investor.*


```solidity
mapping(address s_investorAddress => mapping(bytes s_signature => bool s_used) s_usedSignature) private s_usedSignatures;
```


## Functions
### onlyLegion

Restricts function access to the Legion bouncer only.

*Reverts if the caller is not the configured Legion bouncer address.*


```solidity
modifier onlyLegion();
```

### onlyProject

Restricts function access to the project admin only.

*Reverts if the caller is not the configured project admin address.*


```solidity
modifier onlyProject();
```

### onlyLegionOrProject

Restricts function access to either Legion bouncer or project admin.

*Reverts if the caller is neither the project admin nor Legion bouncer.*


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

### whenSaleEnded

Restricts interaction to when the sale has ended.

*Reverts if the sale has not ended.*


```solidity
modifier whenSaleEnded();
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

### whenTokensSupplied

Restricts interaction to when tokens have been supplied for distribution.

*Reverts if tokens have not been supplied.*


```solidity
modifier whenTokensSupplied();
```

### whenTokensNotSupplied

Restricts interaction to when tokens have not been supplied for distribution.

*Reverts if tokens have been supplied.*


```solidity
modifier whenTokensNotSupplied();
```

### whenSaleResultsNotPublished

Restricts interaction to when the sale results have not been published.

*Reverts if sale results have been published.*


```solidity
modifier whenSaleResultsNotPublished();
```

### constructor

Constructor for the LegionPreLiquidApprovedSale contract.

*Prevents the implementation contract from being initialized directly.*


```solidity
constructor();
```

### initialize

Initializes the pre-liquid approved sale contract with parameters.


```solidity
function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The pre-liquid approved sale initialization parameters.|


### invest

Allows an investor to invest capital in the pre-liquid approved sale.


```solidity
function invest(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes calldata investSignature
)
    external
    whenNotPaused
    whenSaleNotCanceled
    whenSaleNotEnded;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
|`investAmount`|`uint256`|The maximum capital allowed.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals).|
|`investSignature`|`bytes`|The signature verifying investor eligibility.|


### refund

Processes a refund for an investor during the refund period.


```solidity
function refund() external whenNotPaused whenSaleNotCanceled whenRefundPeriodNotOver;
```

### publishTgeDetails

Publishes token details after Token Generation Event (TGE).


```solidity
function publishTgeDetails(
    address askToken,
    uint256 askTokenTotalSupply,
    uint256 totalTokensAllocated
)
    external
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenSaleEnded
    whenRefundPeriodIsOver;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`askToken`|`address`|The address of the token to be distributed.|
|`askTokenTotalSupply`|`uint256`|The total supply of the ask token.|
|`totalTokensAllocated`|`uint256`|The total tokens allocated for investors.|


### supplyTokens

Supplies tokens for distribution after TGE.


```solidity
function supplyTokens(
    uint256 amount,
    uint256 legionFee,
    uint256 referrerFee
)
    external
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


### emergencyWithdraw

Withdraws tokens in emergency situations.


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to receive withdrawn tokens.|
|`token`|`address`|The address of the token to withdraw.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### withdrawRaisedCapital

Withdraws raised capital to the project admin.


```solidity
function withdrawRaisedCapital()
    external
    onlyProject
    whenNotPaused
    whenSaleNotCanceled
    whenSaleEnded
    whenRefundPeriodIsOver;
```

### claimTokenAllocation

Allows investors to claim their token allocation.


```solidity
function claimTokenAllocation(
    uint256 investAmount,
    uint256 tokenAllocationRate,
    LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes calldata claimSignature,
    bytes calldata vestingSignature
)
    external
    whenNotPaused
    whenSaleNotCanceled
    whenSaleEnded
    whenRefundPeriodIsOver
    whenTokensSupplied;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investAmount`|`uint256`|The maximum capital allowed per SAFT.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals).|
|`investorVestingConfig`|`LegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`claimSignature`|`bytes`|The signature verifying investment eligibility.|
|`vestingSignature`|`bytes`|The signature verifying vesting terms.|


### cancel

Cancels the sale and handles capital return.


```solidity
function cancel() external onlyProject whenNotPaused whenSaleNotCanceled whenTokensNotSupplied;
```

### withdrawInvestedCapitalIfCanceled

Allows investors to withdraw capital if the sale is canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external whenNotPaused whenSaleCanceled;
```

### withdrawExcessInvestedCapital

Withdraws excess invested capital back to investors.


```solidity
function withdrawExcessInvestedCapital(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes calldata withdrawSignature
)
    external
    whenNotPaused
    whenSaleNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to withdraw.|
|`investAmount`|`uint256`|The maximum capital allowed.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals).|
|`withdrawSignature`|`bytes`|The signature verifying eligibility.|


### releaseVestedTokens

Releases vested tokens to the investor.


```solidity
function releaseVestedTokens() external whenNotPaused;
```

### end

Ends the sale manually.


```solidity
function end() external onlyLegionOrProject whenNotPaused whenSaleNotCanceled whenSaleNotEnded;
```

### publishRaisedCapital

Publishes the total capital raised.


```solidity
function publishRaisedCapital(uint256 capitalRaised)
    external
    onlyLegion
    whenNotPaused
    whenSaleEnded
    whenSaleNotCanceled
    whenRefundPeriodIsOver;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|


### transferInvestorPosition


```solidity
function transferInvestorPosition(
    address from,
    address to,
    uint256 positionId
)
    external
    override
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenSaleEnded
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
    whenSaleEnded
    whenRefundPeriodIsOver
    whenSaleResultsNotPublished;
```

### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external onlyLegion;
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

### saleConfiguration

Returns the current sale configuration.


```solidity
function saleConfiguration() external view returns (PreLiquidSaleConfig memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`PreLiquidSaleConfig`|The complete sale configuration struct.|


### saleStatus

Returns the current sale status.


```solidity
function saleStatus() external view returns (PreLiquidSaleStatus memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`PreLiquidSaleStatus`|The complete sale status struct.|


### investorPosition

Returns an investor's position details.


```solidity
function investorPosition(address investor) external view returns (InvestorPosition memory);
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


### _setLegionSaleConfig

*Sets the sale parameters during initialization.*


```solidity
function _setLegionSaleConfig(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams)
    private
    onlyInitializing;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The initialization parameters for the sale.|


### _syncLegionAddresses

*Synchronizes Legion addresses from the address registry.*


```solidity
function _syncLegionAddresses() private;
```

### _updateInvestorPosition

*Updates an investor's position with SAFT data.*


```solidity
function _updateInvestorPosition(uint256 _investAmount, uint256 _tokenAllocationRate, uint256 _positionId) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investAmount`|`uint256`|The maximum capital allowed per SAFT.|
|`_tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals).|
|`_positionId`|`uint256`|The ID of the investor position.|


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


### _verifyValidVestingPosition

*Validates an investor's vesting position using signature verification.*


```solidity
function _verifyValidVestingPosition(
    bytes calldata _vestingSignature,
    uint256 _positionId,
    LegionVestingManager.LegionInvestorVestingConfig calldata _investorVestingConfig
)
    private
    view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_vestingSignature`|`bytes`|The signature proving vesting terms.|
|`_positionId`|`uint256`|The position ID of the investor.|
|`_investorVestingConfig`|`LegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration to verify.|


### _verifyValidConfig

*Validates the sale configuration parameters.*


```solidity
function _verifyValidConfig(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The initialization parameters to validate.|


### _verifyCanSupplyTokens

*Verifies conditions for supplying tokens.*


```solidity
function _verifyCanSupplyTokens(uint256 _amount) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount of tokens to supply.|


### _verifySaleNotCanceled

*Verifies that the sale is not canceled.*


```solidity
function _verifySaleNotCanceled() private view;
```

### _verifySaleIsCanceled

*Verifies that the sale is canceled.*


```solidity
function _verifySaleIsCanceled() private view;
```

### _verifySaleHasNotEnded

*Verifies that the sale has not ended.*


```solidity
function _verifySaleHasNotEnded() private view;
```

### _verifySaleHasEnded

*Verifies that the sale has ended.*


```solidity
function _verifySaleHasEnded() private view;
```

### _verifyCanClaimTokenAllocation

*Verifies conditions for claiming token allocation.*


```solidity
function _verifyCanClaimTokenAllocation(uint256 _positionId) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The ID of the investor's position.|


### _verifyTokensSupplied

*Verifies that tokens have been supplied to the sale.*


```solidity
function _verifyTokensSupplied() private view;
```

### _verifyTokensNotSupplied

*Verifies that no tokens have been supplied.*


```solidity
function _verifyTokensNotSupplied() private view;
```

### _verifySignatureNotUsed

*Verifies that a signature has not been used before.*


```solidity
function _verifySignatureNotUsed(bytes calldata _signature) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_signature`|`bytes`|The signature to verify.|


### _verifyCanWithdrawCapital

*Verifies conditions for withdrawing capital.*


```solidity
function _verifyCanWithdrawCapital() private view;
```

### _verifyRefundPeriodIsOver

*Verifies that the refund period has ended.*


```solidity
function _verifyRefundPeriodIsOver() private view;
```

### _verifyRefundPeriodIsNotOver

*Verifies that the refund period is still active.*


```solidity
function _verifyRefundPeriodIsNotOver() private view;
```

### _verifySaleResultsNotPublished

*Verifies that sale results have not been published.*


```solidity
function _verifySaleResultsNotPublished() internal view virtual;
```

### _verifyHasNotRefunded

*Verifies that the investor has not refunded.*


```solidity
function _verifyHasNotRefunded(uint256 _positionId) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The ID of the investor's position.|


### _verifyCanPublishCapitalRaised

*Verifies conditions for publishing capital raised.*


```solidity
function _verifyCanPublishCapitalRaised() private view;
```

### _verifyValidPosition

*Validates an investor's position using signature verification.*


```solidity
function _verifyValidPosition(bytes calldata _signature, uint256 _positionId, SaleAction _actionType) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_signature`|`bytes`|The signature to verify.|
|`_positionId`|`uint256`|The ID of the investor's position.|
|`_actionType`|`SaleAction`|The type of sale action being performed.|


### _verifyCanClaimExcessCapital

*Verifies investor eligibility to claim excess capital.*


```solidity
function _verifyCanClaimExcessCapital(uint256 _positionId) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The position ID of the investor.|


### _verifyCanTransferInvestorPosition

*Verifies conditions for transferring an investor position.*


```solidity
function _verifyCanTransferInvestorPosition(uint256 _positionId) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The ID of the investor's position.|


