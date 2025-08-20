# ILegionPreLiquidOpenApplicationSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/sales/ILegionPreLiquidOpenApplicationSale.sol)

**Inherits:**
[ILegionAbstractSale](/src/interfaces/sales/ILegionAbstractSale.sol/interface.ILegionAbstractSale.md)

**Author:**
Legion

Interface for the LegionPreLiquidOpenApplicationSale contract.


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
function invest(uint256 amount, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
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


### publishSaleResults

Publishes sale results including token allocation details.


```solidity
function publishSaleResults(bytes32 claimMerkleRoot, uint256 tokensAllocated, address askToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The Merkle root for verifying token claims.|
|`tokensAllocated`|`uint256`|The total tokens allocated for investors.|
|`askToken`|`address`|The address of the token to be distributed.|


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
event CapitalInvested(uint256 amount, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested (in bid tokens).|
|`investor`|`address`|The address of the investor.|
|`positionId`|`uint256`|The unique identifier for the investment position.|

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

### SaleResultsPublished
Emitted when sale results are published by the Legion admin.


```solidity
event SaleResultsPublished(bytes32 claimMerkleRoot, uint256 tokensAllocated, address tokenAddress);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The Merkle root for verifying token claims.|
|`tokensAllocated`|`uint256`|The total amount of tokens allocated from the sale.|
|`tokenAddress`|`address`|The address of the token distributed to investors.|

## Structs
### PreLiquidSaleConfiguration
*Struct defining the configuration for the pre-liquid sale*


```solidity
struct PreLiquidSaleConfiguration {
    uint64 refundPeriodSeconds;
    bool hasEnded;
}
```

