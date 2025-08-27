# LegionCapitalRaise
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/raise/LegionCapitalRaise.sol)

**Inherits:**
[ILegionCapitalRaise](/src/interfaces/raise/ILegionCapitalRaise.sol/interface.ILegionCapitalRaise.md), [LegionPositionManager](/src/position/LegionPositionManager.sol/abstract.LegionPositionManager.md), Initializable, Pausable

**Author:**
Legion

Manages capital raising for ERC20 token sales before Token Generation Event (TGE).

*Handles the complete pre-liquid capital raise lifecycle including investments, refunds, withdrawals, and
position management using soulbound NFTs.*


## State Variables
### s_capitalRaiseConfig
*Struct containing the pre-liquid capital raise configuration.*


```solidity
CapitalRaiseConfig private s_capitalRaiseConfig;
```


### s_capitalRaiseStatus
*Struct tracking the current capital raise status.*


```solidity
CapitalRaiseStatus private s_capitalRaiseStatus;
```


### s_investorPositions
*Mapping of position IDs to their positions.*


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

### whenRaiseCanceled

Restricts function execution when the capital raise is canceled.

*Reverts if the capital raise has not been canceled.*


```solidity
modifier whenRaiseCanceled();
```

### whenRaiseNotCanceled

Restricts function execution when the capital raise is not canceled.

*Reverts if the capital raise has been canceled.*


```solidity
modifier whenRaiseNotCanceled();
```

### whenRaiseHasEnded

Restricts function execution when the capital raise has ended.

*Reverts if the capital raise has not ended.*


```solidity
modifier whenRaiseHasEnded();
```

### whenRaiseNotEnded

Restricts function execution when the capital raise has not ended.

*Reverts if the capital raise has ended.*


```solidity
modifier whenRaiseNotEnded();
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

### constructor

Constructor for the LegionCapitalRaise contract.

*Prevents the implementation contract from being initialized directly.*


```solidity
constructor();
```

### initialize

Initializes the capital raise contract with configuration parameters.


```solidity
function initialize(CapitalRaiseInitializationParams calldata capitalRaiseInitParams) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaiseInitParams`|`CapitalRaiseInitializationParams`|The initialization parameters for the capital raise.|


### invest

Allows an investor to contribute capital to the capital raise.


```solidity
function invest(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes calldata investSignature
)
    external
    whenNotPaused
    whenRaiseNotCanceled
    whenRaiseNotEnded;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
|`investAmount`|`uint256`|The maximum capital allowed for this investor.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals precision).|
|`investSignature`|`bytes`|The signature verifying investor eligibility and terms.|


### refund

Processes a refund for an investor during the refund period.


```solidity
function refund() external whenNotPaused whenRaiseNotCanceled whenRefundPeriodNotOver;
```

### emergencyWithdraw

Withdraws tokens in emergency situations.


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to receive the withdrawn tokens.|
|`token`|`address`|The address of the token to withdraw.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### withdrawRaisedCapital

Withdraws raised capital to the project admin.


```solidity
function withdrawRaisedCapital()
    external
    onlyProject
    whenNotPaused
    whenRaiseNotCanceled
    whenRaiseHasEnded
    whenRefundPeriodIsOver;
```

### cancel

Cancels the capital raise and handles capital return.


```solidity
function cancel() external onlyProject whenNotPaused whenRaiseNotCanceled;
```

### withdrawInvestedCapitalIfCanceled

Allows investors to withdraw capital if the capital raise is canceled.


```solidity
function withdrawInvestedCapitalIfCanceled() external whenNotPaused whenRaiseCanceled;
```

### withdrawExcessInvestedCapital

Withdraws excess invested capital back to investors.


```solidity
function withdrawExcessInvestedCapital(
    uint256 amount,
    uint256 investAmount,
    uint256 tokenAllocationRate,
    bytes calldata claimExcessSignature
)
    external
    whenNotPaused
    whenRaiseNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of excess capital to withdraw.|
|`investAmount`|`uint256`|The maximum capital allowed for this investor.|
|`tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals precision).|
|`claimExcessSignature`|`bytes`|The signature verifying eligibility to claim excess capital.|


### end

Ends the capital raise manually.


```solidity
function end() external onlyLegionOrProject whenNotPaused whenRaiseNotEnded whenRaiseNotCanceled;
```

### publishRaisedCapital

Publishes the total capital raised amount.


```solidity
function publishRaisedCapital(uint256 capitalRaised)
    external
    onlyLegion
    whenNotPaused
    whenRaiseNotCanceled
    whenRaiseHasEnded
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
    whenRaiseNotCanceled
    whenRaiseHasEnded
    whenRefundPeriodIsOver;
```

### transferInvestorPositionWithAuthorization


```solidity
function transferInvestorPositionWithAuthorization(
    address from,
    address to,
    uint256 positionId,
    bytes calldata signature
)
    external
    virtual
    override
    whenNotPaused
    whenRaiseNotCanceled
    whenRaiseHasEnded
    whenRefundPeriodIsOver;
```

### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external onlyLegion;
```

### pause

Pauses all capital raise operations.


```solidity
function pause() external virtual onlyLegion;
```

### unpause

Resumes all capital raise operations.


```solidity
function unpause() external virtual onlyLegion;
```

### saleConfiguration

Returns the current capital raise configuration.


```solidity
function saleConfiguration() external view returns (CapitalRaiseConfig memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`CapitalRaiseConfig`|The complete capital raise configuration struct.|


### saleStatus

Returns the current capital raise status.


```solidity
function saleStatus() external view returns (CapitalRaiseStatus memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`CapitalRaiseStatus`|The complete capital raise status struct.|


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


### _setLegionCapitalRaiseConfig

*Sets the capital raise parameters during initialization.*


```solidity
function _setLegionCapitalRaiseConfig(CapitalRaiseInitializationParams calldata _preLiquidSaleInitParams)
    private
    onlyInitializing;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_preLiquidSaleInitParams`|`CapitalRaiseInitializationParams`|The initialization parameters.|


### _syncLegionAddresses

*Synchronizes Legion addresses from the registry.*


```solidity
function _syncLegionAddresses() private;
```

### _updateInvestorPosition

*Updates an investor's position with new investment and allocation data.*


```solidity
function _updateInvestorPosition(uint256 _investAmount, uint256 _tokenAllocationRate) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investAmount`|`uint256`|The maximum capital allowed to invest.|
|`_tokenAllocationRate`|`uint256`|The token allocation percentage (18 decimals precision).|


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


### _verifyValidConfig

*Validates the capital raise configuration parameters.*


```solidity
function _verifyValidConfig(CapitalRaiseInitializationParams calldata _preLiquidSaleInitParams) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_preLiquidSaleInitParams`|`CapitalRaiseInitializationParams`|The initialization parameters to validate.|


### _verifyCapitalRaisedNotCanceled

*Ensures the capital raise is not canceled.*


```solidity
function _verifyCapitalRaisedNotCanceled() internal view;
```

### _verifyCapitalRaiseIsCanceled

*Ensures the capital raise is canceled.*


```solidity
function _verifyCapitalRaiseIsCanceled() internal view;
```

### _verifyCapitalRaiseHasNotEnded

*Ensures the capital raise has not ended.*


```solidity
function _verifyCapitalRaiseHasNotEnded() internal view;
```

### _verifyCapitalRaiseHasEnded

*Ensures the capital raise has ended.*


```solidity
function _verifyCapitalRaiseHasEnded() internal view;
```

### _verifySignatureNotUsed

*Ensures a signature has not been used before.*


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
function _verifyCanWithdrawCapital() internal view virtual;
```

### _verifyRefundPeriodIsOver

*Ensures the refund period has ended.*


```solidity
function _verifyRefundPeriodIsOver() internal view;
```

### _verifyRefundPeriodIsNotOver

*Ensures the refund period is still active.*


```solidity
function _verifyRefundPeriodIsNotOver() internal view;
```

### _verifyHasNotRefunded

*Ensures the investor has not already refunded.*


```solidity
function _verifyHasNotRefunded(uint256 _positionId) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The ID of the investor's position.|


### _verifyCanPublishCapitalRaised

*Verifies conditions for publishing capital raised.*


```solidity
function _verifyCanPublishCapitalRaised() internal view;
```

### _verifyValidPosition

*Validates an investor's position using signature verification.*


```solidity
function _verifyValidPosition(
    bytes calldata _signature,
    uint256 _positionId,
    CapitalRaiseAction _actionType
)
    internal
    view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_signature`|`bytes`|The signature to verify.|
|`_positionId`|`uint256`|The ID of the investor's position.|
|`_actionType`|`CapitalRaiseAction`|The type of capital raise action being performed.|


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


