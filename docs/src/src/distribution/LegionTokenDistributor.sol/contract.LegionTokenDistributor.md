# LegionTokenDistributor
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/distribution/LegionTokenDistributor.sol)

**Inherits:**
[ILegionTokenDistributor](/src/interfaces/distribution/ILegionTokenDistributor.sol/interface.ILegionTokenDistributor.md), [LegionVestingManager](/src/vesting/LegionVestingManager.sol/abstract.LegionVestingManager.md), Initializable, Pausable

**Author:**
Legion

Manages the distribution of ERC20 tokens sold through the Legion Protocol.

*Handles token allocation claims, vesting deployment, and emergency operations with signature verification.*


## State Variables
### s_tokenDistributorConfig
*Token distributor configuration*


```solidity
TokenDistributorConfig private s_tokenDistributorConfig;
```


### s_investorPositions
*Mapping of investor addresses to their positions.*


```solidity
mapping(address s_investorAddress => InvestorPosition s_investorPosition) private s_investorPositions;
```


## Functions
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

### constructor

Constructs the LegionTokenDistributor and disables initializers.

*Prevents the implementation contract from being initialized directly.*


```solidity
constructor();
```

### initialize

Initializes the token distributor with parameters.


```solidity
function initialize(TokenDistributorInitializationParams calldata tokenDistributorInitParams) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenDistributorInitParams`|`TokenDistributorInitializationParams`|The initialization parameters for the distributor.|


### supplyTokens

Supplies tokens for distribution after TGE.


```solidity
function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external onlyProject whenNotPaused;
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
function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion;
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
    LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
    bytes calldata claimSignature,
    bytes calldata vestingSignature
)
    external
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimAmount`|`uint256`|The amount of tokens to claim.|
|`investorVestingConfig`|`LegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration for the investor.|
|`claimSignature`|`bytes`|The signature verifying investment eligibility.|
|`vestingSignature`|`bytes`|The signature verifying vesting terms.|


### releaseVestedTokens

Releases vested tokens to the investor.


```solidity
function releaseVestedTokens() external whenNotPaused;
```

### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external onlyLegion;
```

### pause

Pauses the distribution.


```solidity
function pause() external onlyLegion;
```

### unpause

Resumes the distribution.


```solidity
function unpause() external onlyLegion;
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
    returns (LegionInvestorVestingStatus memory vestingStatus);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vestingStatus`|`LegionInvestorVestingStatus`|The complete vesting status struct.|


### _setTokenDistributorConfig

*Sets the distributor configuration during initialization*


```solidity
function _setTokenDistributorConfig(TokenDistributorInitializationParams calldata _tokenDistributorInitParams)
    private
    onlyInitializing;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenDistributorInitParams`|`TokenDistributorInitializationParams`|The initialization parameters to configure the distributor.|


### _syncLegionAddresses

*Synchronizes Legion addresses from the address registry.*


```solidity
function _syncLegionAddresses() private;
```

### _verifyValidVestingPosition

*Validates an investor's vesting position using signature verification.*


```solidity
function _verifyValidVestingPosition(
    bytes calldata _vestingSignature,
    LegionVestingManager.LegionInvestorVestingConfig calldata _investorVestingConfig
)
    private
    view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_vestingSignature`|`bytes`|The signature proving the vesting terms are authorized.|
|`_investorVestingConfig`|`LegionVestingManager.LegionInvestorVestingConfig`|The vesting configuration to verify.|


### _verifyValidConfig

*Validates the distributor configuration parameters during initialization.*


```solidity
function _verifyValidConfig(TokenDistributorInitializationParams calldata _tokenDistributorInitParams) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenDistributorInitParams`|`TokenDistributorInitializationParams`|The initialization parameters to validate.|


### _verifyCanSupplyTokens

*Verifies that tokens can be supplied for distribution.*


```solidity
function _verifyCanSupplyTokens(uint256 _amount) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount of tokens to be supplied.|


### _verifyCanClaimTokenAllocation

*Verifies that an investor can claim their token allocation.*


```solidity
function _verifyCanClaimTokenAllocation() internal view;
```

### _verifyValidPosition

*Validates an investor's position using signature verification.*


```solidity
function _verifyValidPosition(uint256 _claimAmount, bytes calldata _signature) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_claimAmount`|`uint256`|The amount of tokens the investor is claiming.|
|`_signature`|`bytes`|The signature to verify the claim authorization.|


