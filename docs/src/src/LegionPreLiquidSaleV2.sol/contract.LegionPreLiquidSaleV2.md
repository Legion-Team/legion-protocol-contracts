# LegionPreLiquidSaleV2
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/a0becaf0413338ea78e3b0a0ce4527f7e1695849/src/LegionPreLiquidSaleV2.sol)

**Inherits:**
[LegionSale](/src/LegionSale.sol/abstract.LegionSale.md), [ILegionPreLiquidSaleV2](/src/interfaces/ILegionPreLiquidSaleV2.sol/interface.ILegionPreLiquidSaleV2.md)

**Author:**
Legion

A contract used to execute pre-liquid sales of ERC20 tokens before TGE


## State Variables
### preLiquidSaleConfig
*A struct describing the pre-liquid sale configuration*


```solidity
PreLiquidSaleConfiguration private preLiquidSaleConfig;
```


## Functions
### initialize

Initializes the contract with correct parameters.


```solidity
function initialize(LegionSaleInitializationParams calldata saleInitParams) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|


### invest

Set the refund period duration in seconds

Invest capital to the pre-liquid sale.


```solidity
function invest(uint256 amount, bytes memory signature) external whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`signature`|`bytes`|The Legion signature for verification.|


### endSale

End sale by Legion or the Project and set the refund end time.


```solidity
function endSale() external onlyLegionOrProject whenNotPaused;
```

### publishCapitalRaised

Publish the total capital raised by the project.


```solidity
function publishCapitalRaised(uint256 capitalRaised, bytes32 acceptedMerkleRoot) external onlyLegion whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|
|`acceptedMerkleRoot`|`bytes32`|The Merkle root to verify accepted capital.|


### publishSaleResults

Publish sale results, once the sale has concluded.

*Can be called only by the Legion admin address.*


```solidity
function publishSaleResults(
    bytes32 claimMerkleRoot,
    uint256 tokensAllocated,
    address askToken
)
    external
    onlyLegion
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The Merkle root to verify token claims.|
|`tokensAllocated`|`uint256`|The total amount of tokens allocated for distribution among investors.|
|`askToken`|`address`|The address of the token distributed to investors.|


### withdrawRaisedCapital

Set the address of the token distributed to investors

Withdraw raised capital from the sale contract.

*Can be called only by the Project admin address.*


```solidity
function withdrawRaisedCapital() external override(ILegionSale, LegionSale) onlyProject whenNotPaused;
```

### cancelSale

Cancels an ongoing sale.

*Can be called only by the Project admin address.*


```solidity
function cancelSale() public override(ILegionSale, LegionSale) onlyProject whenNotPaused;
```

### preLiquidSaleConfiguration

Verify that no tokens have been supplied to the sale by the Project
Cache the amount of funds to be returned to the sale
In case there's capital to return, transfer the funds back to the contract
Set the totalCapitalWithdrawn to zero
Transfer the allocated amount of tokens for distribution

Returns the pre-liquid sale configuration.


```solidity
function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
```

### _verifySaleHasNotEnded

Verify that the sale has not ended.


```solidity
function _verifySaleHasNotEnded() internal view override;
```

### _verifySaleHasEnded

Verify that the sale has ended.


```solidity
function _verifySaleHasEnded() internal view;
```

### _verifyCanPublishCapitalRaised

Verify that capital raised can be published.


```solidity
function _verifyCanPublishCapitalRaised() internal view;
```

### _verifyCanWithdrawCapital

Verify that the project can withdraw capital.


```solidity
function _verifyCanWithdrawCapital() internal view override;
```

### _verifyRefundPeriodIsOver

Verify that the refund period is over.


```solidity
function _verifyRefundPeriodIsOver() internal view override;
```

### _verifyRefundPeriodIsNotOver

Verify that the refund period is not over.


```solidity
function _verifyRefundPeriodIsNotOver() internal view override;
```

