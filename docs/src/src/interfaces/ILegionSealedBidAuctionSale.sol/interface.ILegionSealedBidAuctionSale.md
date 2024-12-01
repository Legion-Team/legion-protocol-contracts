# ILegionSealedBidAuctionSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/interfaces/ILegionSealedBidAuctionSale.sol)

**Inherits:**
[ILegionSale](/src/interfaces/ILegionSale.sol/interface.ILegionSale.md)


## Functions
### initialize

Initialized the contract with correct parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams,
    LegionVestingInitializationParams calldata vestingInitParams
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters.|
|`vestingInitParams`|`LegionVestingInitializationParams`|The vesting initialization parameters.|


### invest

Pledge capital to the sealed bid auction.


```solidity
function invest(uint256 amount, bytes calldata sealedBid, bytes memory signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital pledged.|
|`sealedBid`|`bytes`|The encoded sealed bid data.|
|`signature`|`bytes`|The Legion signature for verification.|


### initializePublishSaleResults

Initializes the process of publishing of sale results, by locking sale cancelation.


```solidity
function initializePublishSaleResults() external;
```

### publishSaleResults

Publish merkle root for distribution of tokens, once the sale has concluded.

*Can be called only by the Legion admin address.*


```solidity
function publishSaleResults(
    bytes32 merkleRoot,
    uint256 tokensAllocated,
    uint256 capitalRaised,
    uint256 sealedBidPrivateKey
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The merkle root to verify against.|
|`tokensAllocated`|`uint256`|The total amount of tokens allocated for distribution among investors.|
|`capitalRaised`|`uint256`|The total capital raised from the auction|
|`sealedBidPrivateKey`|`uint256`|the private key used to decrypt sealed bids|


### decryptSealedBid

Decrypts the sealed bid, once the private key has been published by Legion.

*Can be called only of the private key has been published.*


```solidity
function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`encryptedAmountOut`|`uint256`|The encrypted bid amount|
|`salt`|`uint256`|The salt used in the encryption process|


### sealedBidAuctionSaleConfiguration

Returns the seale bid auction sale configuration.


```solidity
function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory);
```

## Events
### CapitalInvested
This event is emitted when capital is successfully pledged.


```solidity
event CapitalInvested(
    uint256 amount, uint256 encryptedAmountOut, uint256 salt, address investor, uint256 pledgeTimestamp
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital pledged.|
|`encryptedAmountOut`|`uint256`|The encrpyped amount out.|
|`salt`|`uint256`|The unique salt used in the encryption process.|
|`investor`|`address`|The address of the investor.|
|`pledgeTimestamp`|`uint256`|The unix timestamp (seconds) of the block when capital has been pledged.|

### PublishSaleResultsInitialized
This event is emitted when publishing the sale results has been initialized.


```solidity
event PublishSaleResultsInitialized();
```

### SaleResultsPublished
This event is emitted when sale results are successfully published by the Legion admin.


```solidity
event SaleResultsPublished(
    bytes32 merkleRoot, uint256 tokensAllocated, uint256 capitalRaised, uint256 sealedBidPrivateKey
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`merkleRoot`|`bytes32`|The claim merkle root published.|
|`tokensAllocated`|`uint256`|The amount of tokens allocated from the sale.|
|`capitalRaised`|`uint256`|The capital raised from the sale.|
|`sealedBidPrivateKey`|`uint256`|The private key used to decrypt sealed bids.|

## Structs
### SealedBidAuctionSaleInitializationParams
A struct describing the sealed bid auction sale initialization params


```solidity
struct SealedBidAuctionSaleInitializationParams {
    Point publicKey;
}
```

### SealedBidAuctionSaleConfiguration
A struct describing the sealed bid auction sale configuration


```solidity
struct SealedBidAuctionSaleConfiguration {
    Point publicKey;
    uint256 privateKey;
    bool cancelLocked;
}
```

### EncryptedBid
A struct describing the encrypted bid


```solidity
struct EncryptedBid {
    uint256 encryptedAmountOut;
    Point publicKey;
}
```

