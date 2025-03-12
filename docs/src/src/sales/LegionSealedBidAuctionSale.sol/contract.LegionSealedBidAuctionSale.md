# LegionSealedBidAuctionSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/sales/LegionSealedBidAuctionSale.sol)

**Inherits:**
[LegionSale](/src/sales/LegionSale.sol/abstract.LegionSale.md), [ILegionSealedBidAuctionSale](/src/interfaces/sales/ILegionSealedBidAuctionSale.sol/interface.ILegionSealedBidAuctionSale.md)

**Author:**
Legion

A contract used to execute sealed bid auctions of ERC20 tokens after TGE


## State Variables
### sealedBidAuctionSaleConfig
*A struct describing the sealed bid auction sale configuration.*


```solidity
SealedBidAuctionSaleConfiguration private sealedBidAuctionSaleConfig;
```


## Functions
### initialize

Initializes the contract with correct parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams
)
    external
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters.|


### invest

Invest capital to the sealed bid auction.


```solidity
function invest(uint256 amount, bytes calldata sealedBid, bytes memory signature) external whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested.|
|`sealedBid`|`bytes`|The encoded sealed bid data.|
|`signature`|`bytes`|The Legion signature for verification.|


### initializePublishSaleResults

Initializes the process of publishing of sale results, by locking sale cancelation.


```solidity
function initializePublishSaleResults() external onlyLegion;
```

### publishSaleResults

Publish sale results, once the sale has concluded.

*Can be called only by the Legion admin address.*


```solidity
function publishSaleResults(
    bytes32 claimMerkleRoot,
    bytes32 acceptedMerkleRoot,
    uint256 tokensAllocated,
    uint256 capitalRaised,
    uint256 sealedBidPrivateKey
)
    external
    onlyLegion;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimMerkleRoot`|`bytes32`|The merkle root to verify token claims.|
|`acceptedMerkleRoot`|`bytes32`|The merkle root to verify accepted capital.|
|`tokensAllocated`|`uint256`|The total amount of tokens allocated for distribution among investors.|
|`capitalRaised`|`uint256`|The total capital raised from the auction.|
|`sealedBidPrivateKey`|`uint256`|the private key used to decrypt sealed bids.|


### cancelSale

Cancels an ongoing sale.

*Can be called only by the Project admin address.*


```solidity
function cancelSale() public override(ILegionSale, LegionSale) onlyProject whenNotPaused;
```

### decryptSealedBid

Decrypts the sealed bid, once the private key has been published by Legion.

*Can be called only if the private key has been published.*


```solidity
function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`encryptedAmountOut`|`uint256`|The encrypted bid amount|
|`salt`|`uint256`|The salt used in the encryption process|


### sealedBidAuctionSaleConfiguration

Returns the sealed bid auction sale configuration.


```solidity
function sealedBidAuctionSaleConfiguration() external view returns (SealedBidAuctionSaleConfiguration memory);
```

### _verifyValidParams

Verify if the sale initialization parameters are valid.


```solidity
function _verifyValidParams(SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams)
    private
    pure;
```

### _verifyValidPublicKey

Verify if the public key used to encrypt the bid is valid


```solidity
function _verifyValidPublicKey(Point memory _publicKey) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_publicKey`|`Point`|The public key used to encrypt bids|


### _verifyValidPrivateKey

Verify if the provided private key is valid.


```solidity
function _verifyValidPrivateKey(uint256 _privateKey) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_privateKey`|`uint256`|The private key used to decrypt bids.|


### _verifyPrivateKeyIsPublished

Verify that the private key has been published by Legion.


```solidity
function _verifyPrivateKeyIsPublished() private view;
```

### _verifyValidSalt

Verify that the salt used to encrypt the bid is valid


```solidity
function _verifyValidSalt(uint256 _salt) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_salt`|`uint256`|The salt used for bid encryption|


### _verifyCancelNotLocked

Verify that canceling is not locked


```solidity
function _verifyCancelNotLocked() private view;
```

### _verifyCancelLocked

Verify that canceling is locked


```solidity
function _verifyCancelLocked() private view;
```

