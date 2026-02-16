# ILegionSealedVestingSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/interfaces/sales/ILegionSealedVestingSale.sol)

**Inherits:**
[ILegionAbstractSale](/src/interfaces/sales/ILegionAbstractSale.sol/interface.ILegionAbstractSale.md)

**Author:**
Legion

Interface for the LegionSealedVestingSale contract.


## Functions
### initialize

Initializes the pre-liquid sale contract with parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The pre-liquid sale initialization parameters.|


### invest

Allows an investor to invest capital in the pre-liquid sale.


```solidity
function invest(
    uint256 amount,
    uint256 deadline,
    bytes calldata sealedVestingOption,
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
|`sealedVestingOption`|`bytes`|The encrypted vesting option from the investor.|
|`signature`|`bytes`|The Legion signature for investor verification.|


### updateSealedVestingOption

Allows an investor to update their sealed vesting option.


```solidity
function updateSealedVestingOption(bytes calldata newSealedVestingOption) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newSealedVestingOption`|`bytes`|The new encrypted vesting option from the investor|


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


### initializeReveal

Locks sale cancellation to initialize publishing of results.


```solidity
function initializeReveal() external;
```

### reveal

Publishes sale results including token allocation details.


```solidity
function reveal(uint256 sealedVestingOptionPrivateKey, uint256 fixedSalt) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sealedVestingOptionPrivateKey`|`uint256`|The private key to decrypt sealed vesting options.|
|`fixedSalt`|`uint256`|The fixed salt used for sealing vesting options.|


### preLiquidSaleConfiguration

Returns the current pre-liquid sale configuration.


```solidity
function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`PreLiquidSaleConfiguration`|The complete pre-liquid sale configuration struct.|


### decryptSealedVestingOption

Decrypts a sealed vesting option using the published private key.


```solidity
function decryptSealedVestingOption(uint256 encryptedVestingOption, address investor) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`encryptedVestingOption`|`uint256`|The encrypted vesting option from the investor.|
|`investor`|`address`|The address of the investor who made the investment.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The decrypted vesting option.|


## Events
### CapitalInvested
Emitted when capital is successfully invested in the pre-liquid sale.


```solidity
event CapitalInvested(uint256 amount, uint256 encryptedVestingOption, address investor);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of capital invested (in bid tokens).|
|`encryptedVestingOption`|`uint256`|The encrypted vesting option from the investor.|
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
event Revealed(uint256 sealedVestingOptionPrivateKey, uint256 fixedSalt);
```

### SealedVestingOptionUpdated
Emitted when an investor updates their sealed vesting option.


```solidity
event SealedVestingOptionUpdated(address investor, uint256 encryptedVestingOption);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`investor`|`address`|The address of the investor.|
|`encryptedVestingOption`|`uint256`|The new encrypted vesting option from the investor.|

### SaleEnded
Emitted when the sale is ended by Legion or project.


```solidity
event SaleEnded();
```

## Structs
### PreLiquidSaleInitializationParams
*Struct defining initialization parameters for the pre-liquid sealed vesting sale*


```solidity
struct PreLiquidSaleInitializationParams {
    Point publicKey;
}
```

### PreLiquidSaleConfiguration
*Struct defining the configuration for the pre-liquid sealed vesting sale*


```solidity
struct PreLiquidSaleConfiguration {
    uint64 refundPeriodSeconds;
    bool cancelLocked;
    Point publicKey;
    uint256 privateKey;
    uint256 fixedSalt;
}
```

### EncryptedVestingOption
*Struct representing an encrypted vesting option's components*


```solidity
struct EncryptedVestingOption {
    uint256 encryptedVestingDurationSeconds;
    Point publicKey;
}
```

