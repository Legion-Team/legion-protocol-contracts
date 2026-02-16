# ILegionSealedBidSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/interfaces/sales/ILegionSealedBidSale.sol)

**Inherits:**
[ILegionAbstractSale](/src/interfaces/sales/ILegionAbstractSale.sol/interface.ILegionAbstractSale.md)

**Author:**
Legion

Interface for the LegionSealedBidSale contract.


## Functions
### initialize

Initializes the sealed bid sale contract with parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    SealedBidSaleInitializationParams calldata sealedBidSaleInitParams
)
    external;
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
    payable;
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
function initializeReveal() external;
```

### reveal

Publishes sale results including token allocation and capital raised.


```solidity
function reveal(uint256 sealedBidPrivateKey, uint256 fixedSalt) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sealedBidPrivateKey`|`uint256`|The private key to decrypt sealed bids.|
|`fixedSalt`|`uint256`|The fixed salt used for sealing bids.|


### end

Ends the sale and sets the refund period.


```solidity
function end() external;
```

### publishRaisedCapital

Publishes the total capital raised.


```solidity
function publishRaisedCapital(uint256 capitalRaised) external;
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
Emitted when capital is successfully invested in the sealed bid sale.


```solidity
event CapitalInvested(uint256 amount, uint256 encryptedAmountOut, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested (in bid tokens).|
|`encryptedAmountOut`|`uint256`|The encrypted bid amount of tokens from the investor.|
|`investor`|`address`|The address of the investor.|

### CapitalRaisedPublished
Emitted when the total capital raised is published by the Legion admin.


```solidity
event CapitalRaisedPublished(uint256 capitalRaised);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|

### RevealInitialized
Emitted when the sealed bid reveal process is initialized.


```solidity
event RevealInitialized();
```

### Revealed
Emitted when sealed bids are revealed by the Legion admin.


```solidity
event Revealed(uint256 sealedBidPrivateKey, uint256 fixedSalt);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sealedBidPrivateKey`|`uint256`|The private key used to decrypt sealed bids.|
|`fixedSalt`|`uint256`|The fixed salt used for sealing bids.|

### SaleEnded
Emitted when the sale is ended by Legion or project.


```solidity
event SaleEnded();
```

## Structs
### SealedBidSaleInitializationParams
*Struct defining initialization parameters for the sealed bid sale*


```solidity
struct SealedBidSaleInitializationParams {
    Point publicKey;
}
```

### SealedBidSaleConfiguration
*Struct containing the runtime configuration of the sealed bid sale*


```solidity
struct SealedBidSaleConfiguration {
    uint64 refundPeriodSeconds;
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

