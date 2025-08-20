# ERC5192
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/lib/ERC5192.sol)

**Inherits:**
[IERC5192](/src/interfaces/lib/IERC5192.sol/interface.IERC5192.md), ERC721

**Author:**
Legion

Implements Soulbound Tokens (SBTs) according to the ERC-5192 standard.

*Abstract contract that extends ERC721 with locking functionality to create non-transferable tokens.*


## State Variables
### _locked
*Mapping from token ID to locked status.*


```solidity
mapping(uint256 => bool) internal _locked;
```


## Functions
### locked

Returns the locking status of a Soulbound Token.

*SBTs assigned to the zero address are considered invalid, and queries about them will revert.*


```solidity
function locked(uint256 tokenId) external view virtual override returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The identifier for an SBT.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the token is locked, false otherwise.|


### _updateLockedStatus

*Updates the locked status of a token and emits the appropriate event.*


```solidity
function _updateLockedStatus(uint256 tokenId, bool status) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The identifier for a token.|
|`status`|`bool`|The new locked status of the token.|


### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool result);
```

### name


```solidity
function name() public view virtual override returns (string memory);
```

### symbol


```solidity
function symbol() public view virtual override returns (string memory);
```

### tokenURI


```solidity
function tokenURI(uint256 id) public view virtual override returns (string memory);
```

### _mint

*Mints `tokenId` and transfers it to `to`.
WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
Requirements:
- `tokenId` must not exist.
- `to` cannot be the zero address.
Emits a {Transfer} event.*


```solidity
function _mint(address to, uint256 id) internal virtual override;
```

### _mintAndSetExtraDataUnchecked

*Mints token `id` to `to`, and updates the extra data for token `id` to `value`.
Does NOT check if token `id` already exists (assumes `id` is auto-incrementing).
Requirements:
- `to` cannot be the zero address.
Emits a {Transfer} event.*


```solidity
function _mintAndSetExtraDataUnchecked(address to, uint256 id, uint96 value) internal virtual override;
```

### _burn

*Destroys `tokenId`.
The approval is cleared when the token is burned.
This is an internal function that does not check if the sender is authorized to operate on the token.
Requirements:
- `tokenId` must exist.
Emits a {Transfer} event.*


```solidity
function _burn(uint256 id) internal virtual override;
```

### _beforeTokenTransfer

*Hook that is called before any token transfers, including minting and burning.*


```solidity
function _beforeTokenTransfer(address from, address to, uint256 id) internal virtual override;
```

### _afterTokenTransfer

*Hook that is called after any token transfers, including minting and burning.*


```solidity
function _afterTokenTransfer(address from, address to, uint256 id) internal virtual override;
```

## Errors
### ERC5192__LockedToken
*Thrown when attempting to transfer a locked token.*


```solidity
error ERC5192__LockedToken(uint256 tokenId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The identifier for the token that cannot be transferred.|

### ERC5192__TransferToSelf
*Thrown when attempting to transfer a token to itself.*


```solidity
error ERC5192__TransferToSelf(uint256 tokenId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The identifier for the token that cannot be transferred to itself.|

