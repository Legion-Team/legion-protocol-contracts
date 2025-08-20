# IERC5192
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/lib/IERC5192.sol)


## Functions
### locked

Returns the locking status of an Soulbound Token

*SBTs assigned to zero address are considered invalid, and queries
about them do throw.*


```solidity
function locked(uint256 tokenId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The identifier for an SBT.|


## Events
### Locked
Emitted when the locking status is changed to locked.

*If a token is minted and the status is locked, this event should be emitted.*


```solidity
event Locked(uint256 tokenId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The identifier for a token.|

### Unlocked
Emitted when the locking status is changed to unlocked.

*If a token is minted and the status is unlocked, this event should be emitted.*


```solidity
event Unlocked(uint256 tokenId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The identifier for a token.|

