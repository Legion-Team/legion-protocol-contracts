# LegionPreLiquidOpenApplicationSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/sales/LegionPreLiquidOpenApplicationSale.sol)

**Inherits:**
[LegionAbstractSale](/src/sales/LegionAbstractSale.sol/abstract.LegionAbstractSale.md), [ILegionPreLiquidOpenApplicationSale](/src/interfaces/sales/ILegionPreLiquidOpenApplicationSale.sol/interface.ILegionPreLiquidOpenApplicationSale.md)

**Author:**
Legion

Executes pre-liquid sales of ERC20 tokens before Token Generation Event (TGE).

*Inherits from LegionAbstractSale and implements ILegionPreLiquidOpenApplicationSale for open application
pre-liquid sale management.*


## State Variables
### s_preLiquidSaleConfig
*Struct containing the pre-liquid sale configuration*


```solidity
PreLiquidSaleConfiguration private s_preLiquidSaleConfig;
```


## Functions
### whenSaleEnded

Restricts interaction to when the sale has ended.

*Reverts if the sale has not ended.*


```solidity
modifier whenSaleEnded();
```

### initialize

Initializes the pre-liquid sale contract with parameters.


```solidity
function initialize(LegionSaleInitializationParams calldata saleInitParams) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|


### invest

Allows an investor to invest capital in the pre-liquid sale.


```solidity
function invest(uint256 amount, bytes calldata signature) external whenNotPaused whenSaleNotEnded whenSaleNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
|`signature`|`bytes`|The Legion signature for investor verification.|


### end

Ends the sale and sets the refund period.


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
    whenSaleNotCanceled
    whenSaleEnded
    whenRefundPeriodIsOver;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|


### publishSaleResults

Publishes sale results including token allocation details.


```solidity
function publishSaleResults(
    bytes32 claimMerkleRoot,
    uint256 tokensAllocated,
    address askToken
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
|`claimMerkleRoot`|`bytes32`|The Merkle root for verifying token claims.|
|`tokensAllocated`|`uint256`|The total tokens allocated for investors.|
|`askToken`|`address`|The address of the token to be distributed.|


### withdrawRaisedCapital

Withdraws raised capital to the project admin.


```solidity
function withdrawRaisedCapital()
    external
    override(ILegionAbstractSale, LegionAbstractSale)
    onlyProject
    whenNotPaused
    whenSaleEnded
    whenRefundPeriodIsOver
    whenSaleNotCanceled;
```

### preLiquidSaleConfiguration

Returns the current pre-liquid sale configuration.


```solidity
function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`PreLiquidSaleConfiguration`|The complete pre-liquid sale configuration struct.|


### cancel

Cancels the ongoing sale.

*Allows cancellation before results are published; only callable by the project admin.*


```solidity
function cancel()
    public
    override(ILegionAbstractSale, LegionAbstractSale)
    onlyProject
    whenNotPaused
    whenSaleNotCanceled
    whenTokensNotSupplied;
```

### _verifySaleHasNotEnded

*Verifies that the sale has not ended.*


```solidity
function _verifySaleHasNotEnded() internal view override;
```

### _verifyRefundPeriodIsOver

*Verifies that the refund period has ended.*


```solidity
function _verifyRefundPeriodIsOver() internal view override;
```

### _verifyRefundPeriodIsNotOver

*Verifies that the refund period is still active.*


```solidity
function _verifyRefundPeriodIsNotOver() internal view override;
```

### _verifyCanWithdrawCapital

*Verifies conditions for withdrawing capital.*


```solidity
function _verifyCanWithdrawCapital() internal view override;
```

### _verifySaleHasEnded

*Verifies that the sale has ended.*


```solidity
function _verifySaleHasEnded() private view;
```

### _verifyCanPublishCapitalRaised

*Verifies conditions for publishing capital raised.*


```solidity
function _verifyCanPublishCapitalRaised() private view;
```

