# ILegionPositionManager
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/position/ILegionPositionManager.sol)

**Author:**
Legion

Interface for the LegionPositionManager contract.


## Functions
### transferInvestorPosition

Transfers an investor position from one address to another.


```solidity
function transferInvestorPosition(address from, address to, uint256 positionId) external;
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
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address of the current owner.|
|`to`|`address`|The address of the new owner.|
|`positionId`|`uint256`|The ID of the position to transfer.|
|`signature`|`bytes`|The cryptographic signature authorizing the transfer.|


## Structs
### LegionPositionManagerConfig
*Struct to hold the configuration parameters for the Legion Position Manager.*


```solidity
struct LegionPositionManagerConfig {
    string name;
    string symbol;
    string baseURI;
    uint256 lastPositionId;
}
```

