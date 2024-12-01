# LegionFixedPriceSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionFixedPriceSale.sol)

**Inherits:**
[LegionSale](/src/LegionSale.sol/abstract.LegionSale.md), [ILegionFixedPriceSale](/src/interfaces/ILegionFixedPriceSale.sol/interface.ILegionFixedPriceSale.md)

**Author:**
Legion.

A contract used to execute fixed price sales of ERC20 tokens after TGE.


## State Variables
### fixedPriceSaleConfig
*A struct describing the fixed price sale configuration.*


```solidity
FixedPriceSaleConfiguration private fixedPriceSaleConfig;
```


## Functions
### initialize

See [ILegionFixedPriceSale-initialize](/src/LegionPreLiquidSale.sol/contract.LegionPreLiquidSale.md#initialize).


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams,
    LegionVestingInitializationParams calldata vestingInitParams
) external initializer;
```

### invest

See [ILegionFixedPriceSale-invest](/src/LegionPreLiquidSale.sol/contract.LegionPreLiquidSale.md#invest).


```solidity
function invest(uint256 amount, bytes memory signature) external whenNotPaused;
```

### publishSaleResults

See [ILegionFixedPriceSale-publishSaleResults](/src/LegionSealedBidAuctionSale.sol/contract.LegionSealedBidAuctionSale.md#publishsaleresults).


```solidity
function publishSaleResults(bytes32 merkleRoot, uint256 tokensAllocated, uint8 askTokenDecimals) external onlyLegion;
```

### fixedPriceSaleConfiguration

See [ILegionFixedPriceSale-fixedPriceSaleConfiguration](/src/interfaces/ILegionFixedPriceSale.sol/interface.ILegionFixedPriceSale.md#fixedpricesaleconfiguration).


```solidity
function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory);
```

### _isPrefund

Verify if prefund period is active (before sale startTime).


```solidity
function _isPrefund() private view returns (bool);
```

### _verifyNotPrefundAllocationPeriod

Verify if prefund allocation period is active (after prefundEndTime and before sale startTime).


```solidity
function _verifyNotPrefundAllocationPeriod() private view;
```

### _verifyValidParams

Verify if the sale initialization parameters are valid.


```solidity
function _verifyValidParams(FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams) private pure;
```

