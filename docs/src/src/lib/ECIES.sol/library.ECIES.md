# ECIES
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/lib/ECIES.sol)

**Author:**
Oighty

This library implements a simplified version of the Elliptic Curve Integrated Encryption Scheme (ECIES) using the alt_bn128 curve.

*The alt_bn128 curve is used since there are precompiled contracts for point addition, calar multiplication, and pairing that make it gas efficient.
XOR encryption is used with the derived symmetric key, which is not as secure as modern encryption algorithms, but is simple and cheap to implement.
We use keccak256 as the key derivation function, which, as a hash-based key derivation function, is susceptible to dictionary attacks, but is sufficient for our purposes.
As a result of the relative weakness of the symmetric encryption and key derivation function, we rely on the security of the elliptic curve to hide the shared secret.
Recent advances in attacks on the alt_bn128 curve have reduced the expected security of the curve to ~98 bits.
Therefore, this implementation should not be used to secure value directly. It can be used to secure data which, if compromised, would not be catastrophic.
Inspired by:
- https://cryptobook.nakov.com/asymmetric-key-ciphers/ecies-public-key-encryption
- https://billatnapier.medium.com/how-do-i-implement-symmetric-key-encryption-in-ethereum-14afffff6e42
- https://github.com/PhilippSchindler/EthDKG/blob/master/contracts/ETHDKG.sol
This library assumes the curve used is y^2 = x^3 + 3, which has generator point (1, 2).*


## State Variables
### GROUP_ORDER

```solidity
uint256 public constant GROUP_ORDER =
    21_888_242_871_839_275_222_246_405_745_257_275_088_548_364_400_416_034_343_698_204_186_575_808_495_617;
```


### FIELD_MODULUS

```solidity
uint256 public constant FIELD_MODULUS =
    21_888_242_871_839_275_222_246_405_745_257_275_088_696_311_157_297_823_662_689_037_894_645_226_208_583;
```


## Functions
### deriveSymmetricKey

We use a hash function to derive a symmetric key from the shared secret and a provided salt.

*This is not as secure as modern key derivation functions, since hash-based keys are susceptible to dictionary attacks.
However, it is simple and cheap to implement, and is sufficient for our purposes.
The salt prevents duplication even if a shared secret is reused.*


```solidity
function deriveSymmetricKey(uint256 sharedSecret_, uint256 s1_) public pure returns (uint256);
```

### recoverSharedSecret

Recover the shared secret as the x-coordinate of the EC point computed as the multiplication of the ciphertext public key and the private key.


```solidity
function recoverSharedSecret(Point memory ciphertextPubKey_, uint256 privateKey_) public view returns (uint256);
```

### decrypt

Decrypt a message using the provided ciphertext, ciphertext public key, and private key from the recipient.

*We use XOR encryption. The security of the algorithm relies on the security of the elliptic curve to hide the shared secret.*


```solidity
function decrypt(uint256 ciphertext_, Point memory ciphertextPubKey_, uint256 privateKey_, uint256 salt_)
    public
    view
    returns (uint256 message_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ciphertext_`|`uint256`|- The encrypted message.|
|`ciphertextPubKey_`|`Point`|- The ciphertext public key provided by the sender.|
|`privateKey_`|`uint256`|- The private key of the recipient.|
|`salt_`|`uint256`|- A salt used to derive the symmetric key from the shared secret. Ensures that the symmetric key is unique even if the shared secret is reused.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`message_`|`uint256`|- The decrypted message.|


### encrypt

Encrypt a message using the provided recipient public key and the sender private key. Note: sending the private key to an RPC can leak it. This should be used locally.


```solidity
function encrypt(uint256 message_, Point memory recipientPubKey_, uint256 privateKey_, uint256 salt_)
    public
    view
    returns (uint256 ciphertext_, Point memory messagePubKey_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`message_`|`uint256`|- The message to encrypt.|
|`recipientPubKey_`|`Point`|- The public key of the recipient.|
|`privateKey_`|`uint256`|- The private key to use to encrypt the message.|
|`salt_`|`uint256`|- A salt used to derive the symmetric key from the shared secret. Ensures that the symmetric key is unique even if the shared secret is reused.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ciphertext_`|`uint256`|- The encrypted message.|
|`messagePubKey_`|`Point`|- The public key of the message that the receipient can use to decrypt it.|


### calcPubKey

Calculate the point on the generator curve that corresponds to the provided private key. This is used as the public key.


```solidity
function calcPubKey(Point memory generator_, uint256 privateKey_) public view returns (Point memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`generator_`|`Point`|- The point on the the alt_bn128 curve. to use as the generator.|
|`privateKey_`|`uint256`|- The private key to calculate the public key for.|


### _ecMul


```solidity
function _ecMul(Point memory p, uint256 scalar) private view returns (Point memory p2);
```

### isOnBn128

Checks whether a point is on the alt_bn128 curve.


```solidity
function isOnBn128(Point memory p) public pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`p`|`Point`|- The point to check (consists of x and y coordinates).|


### isValid

Checks whether a point is valid. We consider a point valid if it is on the curve and not the generator point or the point at infinity.


```solidity
function isValid(Point memory p) public pure returns (bool);
```

### _fieldmul


```solidity
function _fieldmul(uint256 a, uint256 b) private pure returns (uint256 c);
```

### _fieldadd


```solidity
function _fieldadd(uint256 a, uint256 b) private pure returns (uint256 c);
```

