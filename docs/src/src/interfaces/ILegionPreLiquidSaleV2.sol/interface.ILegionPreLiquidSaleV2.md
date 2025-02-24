# ILegionPreLiquidSaleV2
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/1a165deeea33dfd2b1dca142bf23d06b547c39a3/src/interfaces/ILegionPreLiquidSaleV2.sol)

**Inherits:**
[ILegionSale](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md)


## Functions
### initialize

Initializes the contract with correct parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    LegionVestingInitializationParams calldata vestingInitParams
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`vestingInitParams`|`LegionVestingInitializationParams`|The vesting initialization parameters.|


### invest

Invest capital to the fixed price sale.


```solidity
function invest(uint256 amount, bytes memory signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`signature`|`bytes`|The Legion signature for verification.|


### publishSaleResults

Publish sale results, once the sale has concluded.

*Can be called only by the Legion admin address.*


```solidity
function publishSaleResults(
    bytes32 claimMerkleRoot,
    uint256 tokensAllocated,
    address askToken,
    uint256 vestingStartTime
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The merkle root to verify token claims.|
|`tokensAllocated`|`uint256`|The total amount of tokens allocated for distribution among investors.|
|`askToken`|`address`|The address of the token distributed to investors.|
|`vestingStartTime`|`uint256`|The Unix timestamp (seconds) of the block when the vesting starts.|


### publishCapitalRaised

Publish the total capital raised by the project.


```solidity
function publishCapitalRaised(uint256 capitalRaised, bytes32 acceptedMerkleRoot) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|
|`acceptedMerkleRoot`|`bytes32`|The merkle root to verify accepted capital.|


### endSale

End sale by Legion or the Project and set the refund end time.


```solidity
function endSale() external;
```

### preLiquidSaleConfiguration

Returns the pre-liquid sale configuration.


```solidity
function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
```

## Events
### CapitalInvested
This event is emitted when capital is successfully invested.


```solidity
event CapitalInvested(uint256 amount, address investor, uint256 investTimestamp);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`investor`|`address`|The address of the investor.|
|`investTimestamp`|`uint256`|The Unix timestamp (seconds) of the block when capital has been invested.|

### SaleResultsPublished
This event is emitted when sale results are successfully published by the Legion admin.


```solidity
event SaleResultsPublished(
    bytes32 claimMerkleRoot, uint256 tokensAllocated, address tokenAddress, uint256 vestingStartTime
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The merkle root to verify token claims.|
|`tokensAllocated`|`uint256`|The amount of tokens allocated from the sale.|
|`tokenAddress`|`address`|The address of the token distributed to investors.|
|`vestingStartTime`|`uint256`|The Unix timestamp (seconds) of the block when the vesting starts.|

### CapitalRaisedPublished
This event is emitted when the capital raised is successfully published by the Legion admin.


```solidity
event CapitalRaisedPublished(uint256 capitalRaised, bytes32 acceptedMerkleRoot);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|
|`acceptedMerkleRoot`|`bytes32`|The merkle root to verify accepted capital.|

### SaleEnded
This event is emitted when the sale has been ended.


```solidity
event SaleEnded(uint256 endTime);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`endTime`|`uint256`|The unix timestamp (seconds) of the block when the sale has been ended.|

## Structs
### PreLiquidSaleConfiguration
A struct describing the pre-liquid sale configuration.


```solidity
struct PreLiquidSaleConfiguration {
    uint256 refundPeriodSeconds;
    uint256 lockupPeriodSeconds;
    bool hasEnded;
}
```

