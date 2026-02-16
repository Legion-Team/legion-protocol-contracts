# LegionAbstractSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/sales/LegionAbstractSale.sol)

**Inherits:**
[ILegionAbstractSale](/src/interfaces/sales/ILegionAbstractSale.sol/interface.ILegionAbstractSale.md), Initializable, Pausable, ERC20

**Author:**
Legion

Provides core functionality for token sales in the Legion Protocol.

*Abstract base contract that implements common sale operations including investments, refunds, token
distribution, and investor position tracking.*


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
*Mapping of investor addresses to their respective positions*


```solidity
mapping(address s_investorAddress => InvestorPosition s_investorPosition) internal s_investorPositions;
```


## Functions
### receive

Standard receive function to accept ETH payments for ops fees


```solidity
receive() external payable;
```

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

### constructor

Constructor for the LegionAbstractSale contract.

*Prevents the implementation contract from being initialized directly.*


```solidity
constructor();
```

### name

*Returns the name of the token.*


```solidity
function name() public pure override returns (string memory);
```

### symbol

*Returns the symbol of the token, usually a shorter version of the
name.*


```solidity
function symbol() public pure override returns (string memory);
```

### decimals

*Returns the number of decimals used to get its user representation.
For example, if `decimals` equals `2`, a balance of `505` tokens should
be displayed to a user as `5.05` (`505 / 10 ** 2`).
Tokens usually opt for a value of 18, imitating the relationship between
Ether and Wei. This is the default value returned by this function, unless
it's overridden.
NOTE: This information is only used for _display_ purposes: it in
no way affects any of the arithmetic of the contract, including
{IERC20-balanceOf} and {IERC20-transfer}.*


```solidity
function decimals() public view override returns (uint8);
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
    whenSaleEnded
    whenRefundPeriodIsOver
    whenSaleNotCanceled;
```

### withdrawExcessInvestedCapital

Withdraws excess invested capital back to the investor.


```solidity
function withdrawExcessInvestedCapital(
    uint256 amount,
    bytes calldata signature
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
|`signature`|`bytes`|The signature authorizing the withdrawal.|


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

### updateLegionOpsFee

Updates Legion's operations fee.


```solidity
function updateLegionOpsFee(uint256 newFee) external virtual onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFee`|`uint256`|The new fee amount in wei.|


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


### cancel

Cancels the ongoing sale.

*Allows cancellation before results are published; only callable by the project admin.*


```solidity
function cancel() public virtual onlyProject whenNotPaused whenSaleNotCanceled;
```

### claimReceiptTokens

Claims sale receipt tokens after investment.


```solidity
function claimReceiptTokens() external virtual whenNotPaused whenRefundPeriodIsOver whenSaleNotCanceled;
```

### toggleTransferReceiptTokens

Toggles the transferability of receipt tokens.


```solidity
function toggleTransferReceiptTokens() external virtual onlyLegion;
```

### _handleOpsFee

*Verifies that the correct ops fee is sent and transfers it to the Legion fee receiver.*


```solidity
function _handleOpsFee() internal virtual;
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

### _verifyCanClaimExcessCapital

*Verifies investor eligibility to claim excess capital using Merkle proof.*


```solidity
function _verifyCanClaimExcessCapital(
    address _investor,
    uint256 _amount,
    bytes calldata _signature
)
    internal
    view
    virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|
|`_amount`|`uint256`|The amount of excess capital to claim.|
|`_signature`|`bytes`|The signature authorizing the withdrawal.|


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


### _verifySaleHasEnded

*Verifies that the sale has ended.*


```solidity
function _verifySaleHasEnded() internal view virtual;
```

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

### _verifyInvestSignature

*Verifies that an investment signature is valid.*


```solidity
function _verifyInvestSignature(bytes calldata _signature, uint256 amount, uint256 deadline) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_signature`|`bytes`|The signature to verify.|
|`amount`|`uint256`||
|`deadline`|`uint256`||


### _verifyCanWithdrawCapital

*Verifies conditions for withdrawing capital.*


```solidity
function _verifyCanWithdrawCapital() internal view virtual;
```

### _verifyHasNotRefunded

*Verifies that the investor has not refunded.*


```solidity
function _verifyHasNotRefunded(address _investor) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|


### _verifyHasNotClaimedExcess

*Verifies that the investor has not claimed excess capital.*


```solidity
function _verifyHasNotClaimedExcess(address _investor) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|


### _verifyHasClaimedExcess

*Verifies that the investor has claimed excess capital.*


```solidity
function _verifyHasClaimedExcess(address _investor) internal view virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|


### _beforeTokenTransfer

*Overrides the ERC20 _beforeTokenTransfer hook to prevent transfers when paused.*


```solidity
function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address tokens are being transferred from.|
|`to`|`address`|The address tokens are being transferred to.|
|`amount`|`uint256`|The amount of tokens being transferred.|


