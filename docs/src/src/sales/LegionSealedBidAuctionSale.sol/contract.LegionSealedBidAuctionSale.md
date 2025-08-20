# LegionSealedBidAuctionSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/sales/LegionSealedBidAuctionSale.sol)

**Inherits:**
[LegionAbstractSale](/src/sales/LegionAbstractSale.sol/abstract.LegionAbstractSale.md), [ILegionSealedBidAuctionSale](/src/interfaces/sales/ILegionSealedBidAuctionSale.sol/interface.ILegionSealedBidAuctionSale.md)

**Author:**
Legion

Executes sealed bid auctions of ERC20 tokens after Token Generation Event (TGE).

*Inherits from LegionAbstractSale and implements ILegionSealedBidAuctionSale with ECIES encryption features for
bid privacy.*


## State Variables
### s_sealedBidAuctionSaleConfig
*Struct containing the sealed bid auction sale configuration*


```solidity
SealedBidAuctionSaleConfiguration private s_sealedBidAuctionSaleConfig;
```


## Functions
### whenCancelLocked

Restricts interaction to when the sale cancelation is locked.

*Reverts if canceling is not locked.*


```solidity
modifier whenCancelLocked();
```

### whenCancelNotLocked

Restricts interaction to when the sale cancelation is not locked.

*Reverts if canceling is locked.*


```solidity
modifier whenCancelNotLocked();
```

### initialize

Initializes the sealed bid auction sale contract with parameters.


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
|`sealedBidAuctionSaleInitParams`|`SealedBidAuctionSaleInitializationParams`|The sealed bid auction-specific parameters.|


### invest

Allows an investor to invest in the sealed bid auction.


```solidity
function invest(
    uint256 amount,
    bytes calldata sealedBid,
    bytes calldata signature
)
    external
    whenNotPaused
    whenSaleNotEnded
    whenSaleNotCanceled;
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
function initializePublishSaleResults()
    external
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenCancelNotLocked
    whenRefundPeriodIsOver;
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
    external
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenRefundPeriodIsOver
    whenCancelLocked;
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


### cancel

Cancels the ongoing sale.

*Allows cancellation before results are published; only callable by the project admin.*


```solidity
function cancel()
    public
    override(ILegionAbstractSale, LegionAbstractSale)
    onlyProject
    whenNotPaused
    whenCancelNotLocked;
```

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


### _verifyValidParams

*Verifies the validity of sealed bid auction initialization parameters.*


```solidity
function _verifyValidParams(SealedBidAuctionSaleInitializationParams calldata _sealedBidAuctionSaleInitParams)
    private
    pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_sealedBidAuctionSaleInitParams`|`SealedBidAuctionSaleInitializationParams`|The auction-specific parameters to validate.|


### _verifyValidPublicKey

*Verifies the validity of the public key used in a sealed bid.*


```solidity
function _verifyValidPublicKey(Point memory _publicKey) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_publicKey`|`Point`|The public key provided in the sealed bid.|


### _verifyValidPrivateKey

*Verifies the validity of the private key for decrypting bids.*


```solidity
function _verifyValidPrivateKey(uint256 _privateKey) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_privateKey`|`uint256`|The private key provided for decryption.|


### _verifyPrivateKeyIsPublished

*Verifies that the private key has been published.*


```solidity
function _verifyPrivateKeyIsPublished() private view;
```

### _verifyCancelNotLocked

*Verifies that cancellation is not locked.*


```solidity
function _verifyCancelNotLocked() private view;
```

### _verifyCancelLocked

*Verifies that cancellation is locked.*


```solidity
function _verifyCancelLocked() private view;
```

