# LegionSealedBidAuctionSale
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/LegionSealedBidAuctionSale.sol)

**Inherits:**
[LegionSale](/src/LegionSale.sol/abstract.LegionSale.md), [ILegionSealedBidAuctionSale](/src/interfaces/ILegionSealedBidAuctionSale.sol/interface.ILegionSealedBidAuctionSale.md)

**Author:**
Legion.

A contract used to execute seale bid auctions of ERC20 tokens after TGE.


## State Variables
### sealedBidAuctionSaleConfig
*A struct describing the sealed bid auction sale configuration.*


```solidity
SealedBidAuctionSaleConfiguration private sealedBidAuctionSaleConfig;
```


## Functions
### initialize

See [ILegionSealedBidAuctionSale-initialize](/src/interfaces/ILegionFixedPriceSale.sol/interface.ILegionFixedPriceSale.md#initialize).


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams,
    LegionVestingInitializationParams calldata vestingInitParams
) external initializer;
```

### invest

See [ILegionSealedBidAuctionSale-invest](/src/interfaces/ILegionFixedPriceSale.sol/interface.ILegionFixedPriceSale.md#invest).


```solidity
function invest(uint256 amount, bytes calldata sealedBid, bytes memory signature) external whenNotPaused;
```

### initializePublishSaleResults

See [ILegionSealedBidAuctionSale-initializePublishSaleResults](/src/interfaces/ILegionSealedBidAuctionSale.sol/interface.ILegionSealedBidAuctionSale.md#initializepublishsaleresults).


```solidity
function initializePublishSaleResults() external onlyLegion;
```

### publishSaleResults

See [ILegionSealedBidAuctionSale-publishSaleResults](/src/interfaces/ILegionFixedPriceSale.sol/interface.ILegionFixedPriceSale.md#publishsaleresults).


```solidity
function publishSaleResults(
    bytes32 merkleRoot,
    uint256 tokensAllocated,
    uint256 capitalRaised,
    uint256 sealedBidPrivateKey
) external onlyLegion;
```

### cancelSale

See [ILegionSale-cancelSale](/src/LegionSale.sol/abstract.LegionSale.md#cancelsale).


```solidity
function cancelSale() public override(ILegionSale, LegionSale) onlyProject whenNotPaused;
```

### decryptSealedBid

See {ILegionSealedBidAuctionSale-decryptBid}.


```solidity
function decryptSealedBid(uint256 encryptedAmountOut, uint256 salt) public view returns (uint256);
```

### sealedBidAuctionSaleConfiguration

See [ILegionSealedBidAuctionSale-sealedBidAuctionSaleConfiguration](/src/interfaces/ILegionSealedBidAuctionSale.sol/interface.ILegionSealedBidAuctionSale.md#sealedbidauctionsaleconfiguration).


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

Verify if the public key used to encrpyt the bid is valid.


```solidity
function _verifyValidPublicKey(Point memory _publicKey) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_publicKey`|`Point`|The public key used to encrypt bids.|


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

Verify that the salt used to encrypt the bid is valid.


```solidity
function _verifyValidSalt(uint256 _salt) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_salt`|`uint256`|The salt used for bid encryption|


### _verifyCancelNotLocked

Verify that canceling the is not locked.


```solidity
function _verifyCancelNotLocked() private view;
```

### _verifyCancelLocked

Verify that canceling is locked.


```solidity
function _verifyCancelLocked() private view;
```

