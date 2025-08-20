# LegionPositionManager
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/position/LegionPositionManager.sol)

**Inherits:**
[ILegionPositionManager](/src/interfaces/position/ILegionPositionManager.sol/interface.ILegionPositionManager.md), [ERC5192](/src/lib/ERC5192.sol/abstract.ERC5192.md)

**Author:**
Legion

Manages investor positions during sales in the Legion Protocol using soulbound NFTs.

*Abstract contract that extends ERC5192 to create non-transferable position tokens representing investor
participation in sales.*


## State Variables
### s_positionManagerConfig
Legion Position Manager configuration.

*Struct containing the position manager configuration.*


```solidity
LegionPositionManagerConfig public s_positionManagerConfig;
```


### s_investorPositionIds
Mapping of investor addresses to their position IDs.

*Maps each investor to their unique position identifier.*


```solidity
mapping(address s_investorAddress => uint256 s_investorPositionId) internal s_investorPositionIds;
```


## Functions
### transferInvestorPosition

Transfers an investor position from one address to another.


```solidity
function transferInvestorPosition(address from, address to, uint256 positionId) external virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address of the current owner.|
|`to`|`address`|The address of the new owner.|
|`positionId`|`uint256`|The ID of the position to transfer.|


### transferInvestorPositionWithAuthorization

Transfers an investor position with cryptographic authorization.


```solidity
function transferInvestorPositionWithAuthorization(
    address from,
    address to,
    uint256 positionId,
    bytes calldata signature
)
    external
    virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address of the current owner.|
|`to`|`address`|The address of the new owner.|
|`positionId`|`uint256`|The ID of the position to transfer.|
|`signature`|`bytes`|The cryptographic signature authorizing the transfer.|


### name


```solidity
function name() public view override returns (string memory);
```

### symbol


```solidity
function symbol() public view override returns (string memory);
```

### tokenURI


```solidity
function tokenURI(uint256 id) public view override returns (string memory);
```

### _afterTokenTransfer


```solidity
function _afterTokenTransfer(address _from, address _to, uint256 _id) internal override;
```

### _transferInvestorPosition

*Internal function to transfer an investor position between addresses.*


```solidity
function _transferInvestorPosition(address _from, address _to, uint256 _positionId) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The address of the current owner.|
|`_to`|`address`|The address of the new owner.|
|`_positionId`|`uint256`|The ID of the position to transfer.|


### _createInvestorPosition

*Internal function to create a new investor position.*


```solidity
function _createInvestorPosition(address _investor) internal virtual returns (uint256 positionId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`positionId`|`uint256`|The ID of the newly created position.|


### _burnInvestorPosition

*Internal function to burn an investor position.*


```solidity
function _burnInvestorPosition(address _investor) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor whose position will be burned.|


### _getInvestorPositionId

*Internal function to get the position ID of an investor.*


```solidity
function _getInvestorPositionId(address _investor) internal view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_investor`|`address`|The address of the investor.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The ID of the investor's position.|


### _verifyPositionExists

*Verifies that an investor's position exists.*


```solidity
function _verifyPositionExists(uint256 _positionId) internal pure virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_positionId`|`uint256`|The ID of the investor's position.|


### _verifyTransferSignature

*Verifies that a transfer signature is valid and authorized.*


```solidity
function _verifyTransferSignature(
    address _from,
    address _to,
    uint256 _positionId,
    address _signer,
    bytes calldata _signature
)
    internal
    view
    virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The address of the current owner.|
|`_to`|`address`|The address of the new owner.|
|`_positionId`|`uint256`|The ID of the position being transferred.|
|`_signer`|`address`|The expected signer of the authorization.|
|`_signature`|`bytes`|The signature authorizing the transfer.|


