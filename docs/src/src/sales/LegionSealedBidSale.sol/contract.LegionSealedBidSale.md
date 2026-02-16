# LegionSealedBidSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/sales/LegionSealedBidSale.sol)

**Inherits:**
[LegionAbstractSale](/src/sales/LegionAbstractSale.sol/abstract.LegionAbstractSale.md), [ILegionSealedBidSale](/src/interfaces/sales/ILegionSealedBidSale.sol/interface.ILegionSealedBidSale.md)

**Author:**
Legion

Executes sealed bid sales of ERC20 tokens after Token Generation Event (TGE).

*Inherits from LegionAbstractSale and implements ILegionSealedBidSale with ECIES encryption features for
bid privacy.*


## State Variables
### s_sealedBidSaleConfig
*Struct containing the sealed bid sale configuration*


```solidity
SealedBidSaleConfiguration private s_sealedBidSaleConfig;
```


## Functions
### whenCancelLocked

Restricts interaction to when the sale cancellation is locked.

*Reverts if canceling is not locked.*


```solidity
modifier whenCancelLocked();
```

### whenCancelNotLocked

Restricts interaction to when the sale cancellation is not locked.

*Reverts if canceling is locked.*


```solidity
modifier whenCancelNotLocked();
```

### initialize

Initializes the sealed bid sale contract with parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    SealedBidSaleInitializationParams calldata sealedBidSaleInitParams
)
    external
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidSaleInitParams`|`SealedBidSaleInitializationParams`|The sealed bid sale-specific parameters.|


### invest

Allows an investor to invest in the sealed bid sale.


```solidity
function invest(
    uint256 amount,
    uint256 deadline,
    bytes calldata sealedBid,
    bytes calldata signature
)
    external
    payable
    whenNotPaused
    whenSaleNotEnded
    whenSaleNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital to invest.|
|`deadline`|`uint256`|The deadline for the investment.|
|`sealedBid`|`bytes`|The encoded sealed bid data (encrypted amount out, salt, public key).|
|`signature`|`bytes`|The Legion signature for investor verification.|


### initializeReveal

Locks sale cancellation to initialize publishing of results.


```solidity
function initializeReveal()
    external
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenCancelNotLocked
    whenRefundPeriodIsOver;
```

### reveal

Publishes sale results including token allocation and capital raised.


```solidity
function reveal(
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
|`sealedBidPrivateKey`|`uint256`|The private key to decrypt sealed bids.|
|`fixedSalt`|`uint256`|The fixed salt used for sealing bids.|


### end

Ends the sale and sets the refund period.


```solidity
function end() external onlyLegionOrProject whenNotPaused whenSaleNotCanceled whenSaleNotEnded;
```

### publishRaisedCapital

Publishes the total capital raised.


```solidity
function publishRaisedCapital(uint256 capitalRaised)
    external
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenRefundPeriodIsOver;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|


### sealedBidSaleConfiguration

Returns the current sealed bid sale configuration.

*Provides read-only access to the sale configuration.*


```solidity
function sealedBidSaleConfiguration() external view returns (SealedBidSaleConfiguration memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SealedBidSaleConfiguration`|The complete sealed bid sale configuration struct.|


### cancel

Cancels the ongoing sale.

*Allows cancellation before results are published; only callable by the project admin.*


```solidity
function cancel()
    public
    override(ILegionAbstractSale, LegionAbstractSale)
    onlyProject
    whenNotPaused
    whenSaleNotCanceled
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


### _verifyCanPublishCapitalRaised

*Verifies conditions for publishing capital raised.*


```solidity
function _verifyCanPublishCapitalRaised() private view;
```

### _verifyValidParams

*Verifies the validity of sealed vesting sale initialization parameters.*


```solidity
function _verifyValidParams(SealedBidSaleInitializationParams calldata _sealedBidSaleInitParams) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_sealedBidSaleInitParams`|`SealedBidSaleInitializationParams`|The auction-specific parameters to validate.|


### _verifyValidPublicKey

*Verifies the validity of the public key used in a sealed vesting option.*


```solidity
function _verifyValidPublicKey(Point memory _publicKey) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_publicKey`|`Point`|The public key provided in the sealed vesting option.|


### _verifyValidPrivateKey

*Verifies the validity of the private key for decrypting sealed vesting options.*


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

