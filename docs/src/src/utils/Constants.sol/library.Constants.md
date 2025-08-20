# Constants
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/utils/Constants.sol)

**Author:**
Legion

Stores constants shared across the Legion Protocol.

*Provides immutable values for time periods, denominators, and unique identifiers used throughout the protocol.*


## State Variables
### MAX_VESTING_DURATION_SECONDS
*Maximum duration allowed for token vesting, set to 520 weeks (10 years).*


```solidity
uint64 internal constant MAX_VESTING_DURATION_SECONDS = 520 weeks;
```


### MAX_EPOCH_DURATION_SECONDS
*Maximum duration allowed for an epoch, set to 52 weeks (1 year).*


```solidity
uint64 internal constant MAX_EPOCH_DURATION_SECONDS = 52 weeks;
```


### MAX_VESTING_LOCKUP_SECONDS
*Maximum duration allowed for lockup periods, set to 520 weeks (10 years).*


```solidity
uint64 internal constant MAX_VESTING_LOCKUP_SECONDS = 520 weeks;
```


### TOKEN_ALLOCATION_RATE_DENOMINATOR
*Denominator for token allocation rate calculations (1e18 for 18 decimal precision).*


```solidity
uint64 internal constant TOKEN_ALLOCATION_RATE_DENOMINATOR = 1e18;
```


### BASIS_POINTS_DENOMINATOR
*Denominator for basis points calculations (10,000 where 1% = 100 bps).*


```solidity
uint16 internal constant BASIS_POINTS_DENOMINATOR = 1e4;
```


### LEGION_BOUNCER_ID
*Unique identifier for the Legion Bouncer in the Address Registry.*


```solidity
bytes32 internal constant LEGION_BOUNCER_ID = bytes32("LEGION_BOUNCER");
```


### LEGION_FEE_RECEIVER_ID
*Unique identifier for the Legion Fee Receiver in the Address Registry.*


```solidity
bytes32 internal constant LEGION_FEE_RECEIVER_ID = bytes32("LEGION_FEE_RECEIVER");
```


### LEGION_SIGNER_ID
*Unique identifier for the Legion Signer in the Address Registry.*


```solidity
bytes32 internal constant LEGION_SIGNER_ID = bytes32("LEGION_SIGNER");
```


### LEGION_VESTING_FACTORY_ID
*Unique identifier for the Legion Vesting Factory in the Address Registry.*


```solidity
bytes32 internal constant LEGION_VESTING_FACTORY_ID = bytes32("LEGION_VESTING_FACTORY");
```


### LEGION_VESTING_CONTROLLER_ID
*Unique identifier for the Legion Vesting Controller in the Address Registry.*


```solidity
bytes32 internal constant LEGION_VESTING_CONTROLLER_ID = bytes32("LEGION_VESTING_CONTROLLER");
```


