# LegionSealedVestingSale
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/bb72c57782fae97ef9d644762c4c3ac28e3a2e85/src/sales/LegionSealedVestingSale.sol)

**Inherits:**
[LegionAbstractSale](/src/sales/LegionAbstractSale.sol/abstract.LegionAbstractSale.md), [ILegionSealedVestingSale](/src/interfaces/sales/ILegionSealedVestingSale.sol/interface.ILegionSealedVestingSale.md)

**Author:**
Legion

Executes pre-liquid sales of ERC20 tokens before Token Generation Event (TGE).

*Inherits from LegionAbstractSale and implements ILegionSealedVestingSale for open application
pre-liquid sale management.*


## State Variables
### s_preLiquidSaleConfig
*Struct containing the pre-liquid sale configuration*


```solidity
PreLiquidSaleConfiguration private s_preLiquidSaleConfig;
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

Initializes the pre-liquid sale contract with parameters.


```solidity
function initialize(
    LegionSaleInitializationParams calldata saleInitParams,
    PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
)
    external
    initializer;
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
|`sealedVestingOption`|`bytes`|The encrypted vesting option from the investor.|
|`signature`|`bytes`|The Legion signature for investor verification.|


### updateSealedVestingOption

Allows an investor to update their sealed vesting option.


```solidity
function updateSealedVestingOption(bytes calldata newSealedVestingOption)
    external
    whenNotPaused
    whenSaleNotEnded
    whenSaleNotCanceled;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newSealedVestingOption`|`bytes`|The new encrypted vesting option from the investor|


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
    whenSaleEnded
    whenRefundPeriodIsOver;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capitalRaised`|`uint256`|The total capital raised by the project.|


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

Publishes sale results including token allocation details.


```solidity
function reveal(
    uint256 sealedVestingOptionPrivateKey,
    uint256 fixedSalt
)
    external
    onlyLegion
    whenNotPaused
    whenSaleNotCanceled
    whenSaleEnded
    whenRefundPeriodIsOver
    whenCancelLocked;
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


### _verifyCanPublishCapitalRaised

*Verifies conditions for publishing capital raised.*


```solidity
function _verifyCanPublishCapitalRaised() private view;
```

### _verifyValidParams

*Verifies the validity of sealed vesting sale initialization parameters.*


```solidity
function _verifyValidParams(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_preLiquidSaleInitParams`|`PreLiquidSaleInitializationParams`|The auction-specific parameters to validate.|


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

