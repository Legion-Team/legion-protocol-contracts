# ILegionPreLiquidSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/interfaces/sales/ILegionPreLiquidSale.sol)

**Inherits:**
[ILegionAbstractSale](/src/interfaces/sales/ILegionAbstractSale.sol/interface.ILegionAbstractSale.md)

**Author:**
Legion

Interface for the LegionPreLiquidSale contract.


## Functions
### initialize

Initializes the pre-liquid sale contract with parameters.


```solidity
function initialize(LegionSaleInitializationParams calldata saleInitParams) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|


### invest

Allows an investor to invest capital in the pre-liquid sale.


```solidity
function invest(uint256 amount, uint256 deadline, bytes calldata signature) external payable;
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
function end() external;
```

### publishRaisedCapital

Publishes the total capital raised.


```solidity
function publishRaisedCapital(uint256 capitalRaised) external;
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


## Events
### CapitalInvested
Emitted when capital is successfully invested in the pre-liquid sale.


```solidity
event CapitalInvested(uint256 amount, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested (in bid tokens).|
|`investor`|`address`|The address of the investor.|

### CapitalRaisedPublished
Emitted when the total capital raised is published by the Legion admin.


```solidity
event CapitalRaisedPublished(uint256 capitalRaised);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|

### SaleEnded
Emitted when the sale is ended by Legion or project.


```solidity
event SaleEnded();
```

## Structs
### PreLiquidSaleConfiguration
*Struct defining the configuration for the pre-liquid sale*


```solidity
struct PreLiquidSaleConfiguration {
    uint64 refundPeriodSeconds;
}
```

