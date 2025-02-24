# MockToken
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/1a165deeea33dfd2b1dca142bf23d06b547c39a3/src/mocks/MockToken.sol)

**Inherits:**
ERC20


## State Variables
### _name

```solidity
string private _name;
```


### _symbol

```solidity
string private _symbol;
```


### _decimals

```solidity
uint8 private _decimals;
```


## Functions
### constructor


```solidity
constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals);
```

### name


```solidity
function name() public view override returns (string memory);
```

### symbol


```solidity
function symbol() public view override returns (string memory);
```

### decimals


```solidity
function decimals() public view override returns (uint8);
```

### mint


```solidity
function mint(address to, uint256 amount) public;
```

