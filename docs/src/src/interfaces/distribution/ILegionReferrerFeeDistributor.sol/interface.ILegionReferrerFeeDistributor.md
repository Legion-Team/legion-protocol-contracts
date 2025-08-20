# ILegionReferrerFeeDistributor
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/distribution/ILegionReferrerFeeDistributor.sol)

**Author:**
Legion

Interface for the LegionReferrerFeeDistributor contract.


## Functions
### setMerkleRoot

Sets the Merkle root for the referrer fee distribution.

*Can only be called by the Legion bouncer.*


```solidity
function setMerkleRoot(bytes32 merkleRoot) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The new Merkle root to be set.|


### claim

Claims referrer fees based on the provided Merkle proof.


```solidity
function claim(uint256 amount, bytes32[] calldata merkleProof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The total aggregated amount of referrer fees to claim.|
|`merkleProof`|`bytes32[]`|The Merkle proof to verify the claim.|


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


### syncLegionAddresses

Synchronizes Legion addresses from the address registry.


```solidity
function syncLegionAddresses() external;
```

### pause

Pauses all fee distribution operations.


```solidity
function pause() external;
```

### unpause

Unpauses all fee distribution operations.


```solidity
function unpause() external;
```

### referrerFeeDistributorConfiguration

Returns the current configuration of the Referrer Fee Distributor.


```solidity
function referrerFeeDistributorConfiguration() external view returns (ReferrerFeeDistributorConfig memory);
```

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
event LegionAddressesSynced(address legionBouncer);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`legionBouncer`|`address`|The updated Legion bouncer address.|

### MerkleRootSet
Emitted when the Merkle root is set for referrer fee distribution.


```solidity
event MerkleRootSet(bytes32 merkleRoot);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The Merkle root set for the referrer fee distribution.|

### ReferrerFeeClaimed
Emitted when referrer fees are claimed.


```solidity
event ReferrerFeeClaimed(address referrer, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`referrer`|`address`|The address of the referrer claiming the fees.|
|`amount`|`uint256`|The total amount of referrer fees claimed.|

## Structs
### ReferrerFeeDistributorInitializationParams
*Struct for initializing the Referrer Fee Distributor.*


```solidity
struct ReferrerFeeDistributorInitializationParams {
    address token;
    address addressRegistry;
}
```

### ReferrerFeeDistributorConfig
*Struct containing the configuration for the Referrer Fee Distributor.*


```solidity
struct ReferrerFeeDistributorConfig {
    address addressRegistry;
    address legionBouncer;
    address token;
    uint256 totalReferrerFeesDistributed;
    bytes32 merkleRoot;
}
```

