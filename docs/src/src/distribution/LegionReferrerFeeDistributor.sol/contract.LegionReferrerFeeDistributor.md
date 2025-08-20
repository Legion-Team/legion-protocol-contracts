# LegionReferrerFeeDistributor
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/distribution/LegionReferrerFeeDistributor.sol)

**Inherits:**
[ILegionReferrerFeeDistributor](/src/interfaces/distribution/ILegionReferrerFeeDistributor.sol/interface.ILegionReferrerFeeDistributor.md), Pausable

**Author:**
Legion

Manages the distribution of referrer fees in the Legion Protocol.

*This contract is responsible for distributing fees to referrers based on their referrals.*


## State Variables
### s_feeDistributorConfig
*Configuration for the Referrer Fee Distributor.*


```solidity
ReferrerFeeDistributorConfig private s_feeDistributorConfig;
```


### s_claimedAmounts
Mapping of referrer addresses to their respective claimed amounts.


```solidity
mapping(address s_referrer => uint256 s_claimedAmount) public s_claimedAmounts;
```


## Functions
### onlyLegion

Restricts function access to the Legion bouncer only.

*Reverts if the caller is not the configured Legion bouncer.*


```solidity
modifier onlyLegion();
```

### constructor

Initializes the contract with initialization parameters.


```solidity
constructor(ReferrerFeeDistributorInitializationParams memory feeDistributorInitParams);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeDistributorInitParams`|`ReferrerFeeDistributorInitializationParams`|The initialization parameters for the fee distributor.|


### setMerkleRoot

Sets the Merkle root for the referrer fee distribution.

*Can only be called by the Legion bouncer.*


```solidity
function setMerkleRoot(bytes32 merkleRoot) external onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The new Merkle root to be set.|


### claim

Claims referrer fees based on the provided Merkle proof.


```solidity
function claim(uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The total aggregated amount of referrer fees to claim.|
|`merkleProof`|`bytes32[]`|The Merkle proof to verify the claim.|


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


### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external onlyLegion;
```

### pause

Pauses all fee distribution operations.


```solidity
function pause() external onlyLegion;
```

### unpause

Unpauses all fee distribution operations.


```solidity
function unpause() external onlyLegion;
```

### referrerFeeDistributorConfiguration

Returns the current configuration of the Referrer Fee Distributor.


```solidity
function referrerFeeDistributorConfiguration() external view returns (ReferrerFeeDistributorConfig memory);
```

### _setFeeDistributorConfig

*Sets the distributor configuration during initialization*


```solidity
function _setFeeDistributorConfig(ReferrerFeeDistributorInitializationParams memory _feeDistributorInitParams)
    private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_feeDistributorInitParams`|`ReferrerFeeDistributorInitializationParams`|The initialization parameters to configure the distributor.|


### _syncLegionAddresses

*Synchronizes Legion addresses from the address registry.*


```solidity
function _syncLegionAddresses() private;
```

### _verifyValidConfig

*Validates the fee distributor configuration parameters during initialization.*


```solidity
function _verifyValidConfig(ReferrerFeeDistributorInitializationParams memory _feeDistributorInitParams) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_feeDistributorInitParams`|`ReferrerFeeDistributorInitializationParams`|The initialization parameters to validate.|


