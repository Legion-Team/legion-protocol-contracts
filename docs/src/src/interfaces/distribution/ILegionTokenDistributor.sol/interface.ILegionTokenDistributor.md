# ILegionTokenDistributor
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/distribution/ILegionTokenDistributor.sol)

**Author:**
Legion

Interface for the LegionTokenDistributor contract.


## Functions
### initialize

Initializes the token distributor with parameters.


```solidity
function initialize(TokenDistributorInitializationParams calldata tokenDistributorInitParams) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenDistributorInitParams`|`TokenDistributorInitializationParams`|The initialization parameters for the distributor.|


### supplyTokens

Supplies tokens for distribution after TGE.


```solidity
function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to supply.|
|`legionFee`|`uint256`|The fee amount for Legion.|
|`referrerFee`|`uint256`|The fee amount for referrer.|


### emergencyWithdraw

Performs an emergency withdrawal of tokens.


```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to receive tokens.|
|`token`|`address`|The address of the token to withdraw.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### claimTokenAllocation

Allows investors to claim their token allocation.


```solidity
function claimTokenAllocation(
    uint256 claimAmount,
    ILegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes calldata claimSignature,
    bytes calldata vestingSignature
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimAmount`|`uint256`|The amount of tokens to claim.|
|`investorVestingConfig`|`ILegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`claimSignature`|`bytes`|The signature verifying investment eligibility.|
|`vestingSignature`|`bytes`|The signature verifying vesting terms.|


### releaseVestedTokens

Releases vested tokens to the investor.


```solidity
function releaseVestedTokens() external;
```

### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external;
```

### pause

Pauses the distribution.


```solidity
function pause() external;
```

### unpause

Resumes the distribution.


```solidity
function unpause() external;
```

### distributorConfiguration

Retrieves the current distributor configuration.


```solidity
function distributorConfiguration() external view returns (TokenDistributorConfig memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`TokenDistributorConfig`|The complete distributor configuration struct.|


### investorPosition

Retrieves an investor's position details.


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

Retrieves an investor's vesting status.


```solidity
function investorVestingStatus(address investor)
    external
    view
    returns (ILegionVestingManager.LegionInvestorVestingStatus memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`ILegionVestingManager.LegionInvestorVestingStatus`|The complete vesting status struct.|


## Events
### EmergencyWithdraw
Emitted during an emergency withdrawal by Legion.


```solidity
event EmergencyWithdraw(address receiver, address token, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address receiving the withdrawn tokens.|
|`token`|`address`|The address of the token withdrawn.|
|`amount`|`uint256`|The amount of tokens withdrawn.|

### LegionAddressesSynced
Emitted when Legion addresses are successfully synced.


```solidity
event LegionAddressesSynced(
    address legionBouncer,
    address legionSigner,
    address legionFeeReceiver,
    address vestingFactory,
    address vestingController
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`legionBouncer`|`address`|The updated Legion bouncer address.|
|`legionSigner`|`address`|The updated Legion signer address.|
|`legionFeeReceiver`|`address`|The updated Legion fee receiver address.|
|`vestingFactory`|`address`|The updated vesting factory address.|
|`vestingController`|`address`|The updated vesting controller address.|

### TokenAllocationClaimed
Emitted when an investor successfully claims their token allocation.


```solidity
event TokenAllocationClaimed(uint256 amountToBeVested, uint256 amountOnClaim, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToBeVested`|`uint256`|The amount of tokens sent to vesting contract.|
|`amountOnClaim`|`uint256`|The amount of tokens distributed immediately.|
|`investor`|`address`|The address of the claiming investor.|

### TokensSuppliedForDistribution
Emitted when tokens are supplied for distribution by the project.


```solidity
event TokensSuppliedForDistribution(uint256 amount, uint256 legionFee, uint256 referrerFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens supplied.|
|`legionFee`|`uint256`|The fee amount collected by Legion.|
|`referrerFee`|`uint256`|The fee amount collected by the referrer.|

## Structs
### TokenDistributorInitializationParams
*Struct for initializing the Token Distributor.*


```solidity
struct TokenDistributorInitializationParams {
    uint16 legionFeeOnTokensSoldBps;
    uint16 referrerFeeOnTokensSoldBps;
    address referrerFeeReceiver;
    address askToken;
    address addressRegistry;
    address projectAdmin;
    uint256 totalAmountToDistribute;
}
```

### TokenDistributorConfig
*Struct for storing the configuration of the Token Distributor.*


```solidity
struct TokenDistributorConfig {
    uint16 legionFeeOnTokensSoldBps;
    uint16 referrerFeeOnTokensSoldBps;
    bool tokensSupplied;
    uint256 totalAmountToDistribute;
    uint256 totalAmountClaimed;
    address askToken;
    address projectAdmin;
    address legionBouncer;
    address legionFeeReceiver;
    address referrerFeeReceiver;
    address legionSigner;
    address addressRegistry;
}
```

### InvestorPosition
*Struct representing an investor's position in the distribution.*


```solidity
struct InvestorPosition {
    bool hasSettled;
    address vestingAddress;
}
```

