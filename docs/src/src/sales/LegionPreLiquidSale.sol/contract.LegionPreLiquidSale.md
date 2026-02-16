# LegionPreLiquidSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/sales/LegionPreLiquidSale.sol)

**Inherits:**
[LegionAbstractSale](/src/sales/LegionAbstractSale.sol/abstract.LegionAbstractSale.md), [ILegionPreLiquidSale](/src/interfaces/sales/ILegionPreLiquidSale.sol/interface.ILegionPreLiquidSale.md)

**Author:**
Legion

Executes pre-liquid sales of ERC20 tokens before Token Generation Event (TGE).

*Inherits from LegionAbstractSale and implements ILegionPreLiquidSale for open application
pre-liquid sale management.*


## State Variables
### s_preLiquidSaleConfig
*Struct containing the pre-liquid sale configuration*


```solidity
PreLiquidSaleConfiguration private s_preLiquidSaleConfig;
```


## Functions
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
function invest(
    uint256 amount,
    uint256 deadline,
    bytes calldata signature
)
    external
    payable
    whenNotPaused
    whenSaleNotEnded
    whenSaleNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
|`deadline`|`uint256`|The deadline for the investment.|
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


### preLiquidSaleConfiguration

Returns the current pre-liquid sale configuration.


```solidity
function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`PreLiquidSaleConfiguration`|The complete pre-liquid sale configuration struct.|


### _verifyCanPublishCapitalRaised

*Verifies conditions for publishing capital raised.*


```solidity
function _verifyCanPublishCapitalRaised() private view;
```

