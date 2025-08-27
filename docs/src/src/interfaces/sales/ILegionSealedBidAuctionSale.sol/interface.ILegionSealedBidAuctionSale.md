# ILegionSealedBidAuctionSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/sales/ILegionSealedBidAuctionSale.sol)

**Inherits:**
[ILegionAbstractSale](/src/interfaces/sales/ILegionAbstractSale.sol/interface.ILegionAbstractSale.md)

**Author:**
Legion

Interface for the LegionSealedBidAuctionSale contract.


## Functions
### initialize

Initializes the sealed bid auction sale contract with parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`SealedBidAuctionSaleInitializationParams`|The sealed bid auction-specific parameters.|


### invest

Allows an investor to invest in the sealed bid auction.


```solidity
function invest(uint256 amount, bytes calldata sealedBid, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
|`sealedBid`|`bytes`|The encoded sealed bid data (encrypted amount out, salt, public key).|
|`signature`|`bytes`|The Legion signature for investor verification.|


### initializePublishSaleResults

Locks sale cancellation to initialize publishing of results.


```solidity
function initializePublishSaleResults() external;
```

### publishSaleResults

Publishes auction results including token allocation and capital raised.


```solidity
function publishSaleResults(
    bytes32 claimMerkleRoot,
    bytes32 acceptedMerkleRoot,
    uint256 tokensAllocated,
    uint256 capitalRaised,
    uint256 sealedBidPrivateKey,
    uint256 fixedSalt
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The Merkle root for verifying token claims.|
|`acceptedMerkleRoot`|`bytes32`|The Merkle root for verifying accepted capital.|
|`tokensAllocated`|`uint256`|The total tokens allocated for investors.|
|`capitalRaised`|`uint256`|The total capital raised from the auction.|
|`sealedBidPrivateKey`|`uint256`|The private key to decrypt sealed bids.|
|`fixedSalt`|`uint256`|The fixed salt used for sealing bids.|


### sealedBidAuctionSaleConfiguration

Returns the current sealed bid auction sale configuration.

*Provides read-only access to the auction configuration.*


```solidity
function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SealedBidAuctionSaleConfiguration`|The complete sealed bid auction sale configuration struct.|


### decryptSealedBid

Decrypts a sealed bid using the published private key.


```solidity
function decryptSealedBid(uint256 encryptedAmountOut, address investor) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`encryptedAmountOut`|`uint256`|The encrypted bid amount from the investor.|
|`investor`|`address`|The address of the investor who made the bid.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The decrypted bid amount.|


## Events
### CapitalInvested
Emitted when capital is successfully invested in the sealed bid auction.


```solidity
event CapitalInvested(uint256 amount, uint256 encryptedAmountOut, address investor, uint256 positionId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested (in bid tokens).|
|`encryptedAmountOut`|`uint256`|The encrypted bid amount of tokens from the investor.|
|`investor`|`address`|The address of the investor.|
|`positionId`|`uint256`|The unique identifier for the investment position.|

### PublishSaleResultsInitialized
Emitted when the process of publishing sale results is initialized.


```solidity
event PublishSaleResultsInitialized();
```

### SaleResultsPublished
Emitted when sale results are published by the Legion admin.


```solidity
event SaleResultsPublished(
    bytes32 claimMerkleRoot,
    bytes32 acceptedMerkleRoot,
    uint256 tokensAllocated,
    uint256 capitalRaised,
    uint256 sealedBidPrivateKey,
    uint256 fixedSalt
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The Merkle root for verifying token claims.|
|`acceptedMerkleRoot`|`bytes32`|The Merkle root for verifying accepted capital.|
|`tokensAllocated`|`uint256`|The total tokens allocated from the sale.|
|`capitalRaised`|`uint256`|The total capital raised from the auction.|
|`sealedBidPrivateKey`|`uint256`|The private key used to decrypt sealed bids.|
|`fixedSalt`|`uint256`|The fixed salt used for sealing bids.|

## Structs
### SealedBidAuctionSaleInitializationParams
*Struct defining initialization parameters for the sealed bid auction sale*


```solidity
struct SealedBidAuctionSaleInitializationParams {
    Point publicKey;
}
```

### SealedBidAuctionSaleConfiguration
*Struct containing the runtime configuration of the sealed bid auction sale*


```solidity
struct SealedBidAuctionSaleConfiguration {
    bool cancelLocked;
    Point publicKey;
    uint256 privateKey;
    uint256 fixedSalt;
}
```

### EncryptedBid
*Struct representing an encrypted bid's components*


```solidity
struct EncryptedBid {
    uint256 encryptedAmountOut;
    Point publicKey;
}
```

