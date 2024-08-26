# Legion Protocol Smart Contracts

## Background

Legion is a groundbreaking platform that connects value-add network participants with the most promising crypto projects. Our platform facilitates compliant and incentive-aligned investments, both pre-Token Generation Event (TGE) and for token launches.

## Overview

The Legion protocol consists of smart contracts designed to facilitate different types of ERC20 token sales and manage related operations. The first supported types of sales are a traditional **Fixed Price Sale** and a **Sealed Bid Auction**. Below is an overview of all the key actors, along with a description of the functionality for each contract.

**Key Actors:**

- **Investor** - The user participating in a sale and pledging capital.
- **Project** - The project raising capital and launching a token.
- **Legion** - Our protocol, facilitating the token distribution and capital raising.

## Architecture

Legion uses a Clone Pattern utilizing the [EIP-1167 Minimal Proxy Standard](https://eips.ethereum.org/EIPS/eip-1167) for deploying sale and vesting schedule contracts. Standard **MerkleProof** is used for verification of different conditions, such as eligibility to distribute tokens to investors.

Legion's smart contracts work together with Legion's backend, responsible for publishing sale results after analyzing and indexing events emitted during the sale process.

## System Limitations

Legion Protocol smart contracts are designed to work tightly with Legion's backend. It is unfeasible for the smart contracts to work independently from the backend, as they rely heavily on calculations performed off-chain. Moreover, there are certain centralized aspects of the system, which are by design - A Legion admin is responsible for publishing results from sales and a sale cannot be settled without Legion.

On another note, as the system is heavily dependent on the actions of all actors - Legion and the Projects, certain precautions have been taken in case some of the actors don't act (e.g., publish results or supply tokens). In this case, if a sale "expires", users are able to claim back their funds, without requiring any action from Legion's side.

## Known Risks

- **Centralization** - Certain actions rely heavily on the admin access of the parties involved - Legion and the Projects, which requires trust. If by any chance, Legion's or the Project's access is compromised, this can cause problems across the whole system.
- **Third-Party software** - Legion relies heavily on AWS (Amazon Web Services) for managing the contracts' state. If there's a problem with AWS, this can reflect on active sales running through Legion.
- **External smart contracts** - Interacting with external ERC20 token smart contracts like USDC, could pose a risk of getting funds blacklisted, requiring additional steps from Legion to resolve this directly with the issuer.

## Access Control and Privileged Roles

- **Legion** - Legion's admin access and interactions are controlled through the `LegionAccessControl` contract. A `BROADCASTER` role is granted to the AWS Broadcaster Wallet, responsible for executing function calls requiring Legion's access privileges.
- **Projects** - Projects will be required to interact with Legion via a Safe Multisig wallet.

## Smart Contracts

### 1. LegionFixedPriceSale

The `LegionFixedPriceSale` contract is used to execute fixed price sales of ERC20 tokens after the Token Generation Event (TGE). It manages the entire lifecycle of the sale, including capital pledging, refunds, raised capital withdrawal, token distribution for vesting, and sale cancellation.

Every fixed price sale consists of 5 stages, explained below:

#### Fixed Price Sale Stages:

1. **Prefund Stage**: During the prefund stage, investors prefund the sale by pledging capital.
2. **Prefund Allocation Period**: Projects decide allocations for the investors who participated in the prefund, based on their reputation or other factors. This process is facilitated by Legion's backend and depending on the outcome, the prefund can be fully subscribed.
3. **Active Sale Period**: The actual sale stage where investors pledge capital.
4. **Refund Period**: This stage is required by the MiCA regulation, where users can receive a refund if they decide. After the refund period is over, Legion publishes the results from the sale. Projects provide the allocated tokens and withdraw the raised capital from the sale.
5. **Lockup Period**: This stage complies with Regulation S. The lockup period starts immediately after a sale ends. Once it is over, investors are allowed to withdraw their allocations into a vesting schedule contract.

#### Key Functions:

- `initialize`: Initializes the sale with configuration parameters.
- `pledgeCapital`: Allows investors to pledge capital during the prefund and active sale.
- `requestRefund`: Allows investors to request a refund within the refund stage.
- `withdrawCapital`: Enables the project admin to withdraw raised capital post-sale.
- `claimTokenAllocation`: Allows investors to claim their token allocation.
- `claimExcessCapital`: Allows investors to claim excess capital pledged to the sale.
- `releaseTokens`: Releases vested tokens to investors.
- `supplyTokens`: Allows the project admin to supply tokens for the sale.
- `publishSaleResults`: Publishes the results of the fixed price sale.
- `publishExcessCapitalResults`: Publishes the results for excess capital pledged to the sale.
- `cancelSale`: Allows the project admin to cancel the sale.
- `cancelExpiredSale`: Cancels the sale if it has expired.
- `claimBackCapitalIfCanceled`: Allows investors to claim back their capital if the sale is canceled.

### 2. LegionSealedBidAuction

The `LegionSealedBidAuction` contract is used to execute sealed bid auctions of ERC20 tokens after the Token Generation Event (TGE). It manages the entire lifecycle of the sale, including capital pledging, refunds, raised capital withdrawal, token distribution for vesting, and sale cancellation.

`LegionSealedBidAuction` uses ECIES encryption. At the beginning of every sealed bid auction, Legion publishes an EC public key. The public key is used by investors to encrypt the `amountOut` of the `askToken` they want to purchase. The amount of the `bidToken` is visible to everyone, as it is transferred to the contract at the time of pledging capital.

After the sealed bid auction concludes and results are published by Legion, the private key is released to the public. From this point on, everyone is able to decrypt their bids and verify if they are correct.

Every sealed bid auction consists of three stages, explained below:

#### Sealed Bid Auction Stages:

1. **Active Sale Period**: The actual sale stage where investors pledge capital.
2. **Refund Period**: This stage is required by the MiCA regulation, where users can receive a refund if they decide. After the refund period is over, Legion publishes the results from the sale. Projects provide the allocated tokens and withdraw the raised capital from the sale.
3. **Lockup Period**: This stage complies with Regulation S. The lockup period starts immediately after a sale ends. Once it is over, investors are allowed to withdraw their allocations into a vesting schedule contract.

#### Key Functions:

- `initialize`: Initializes the sale with configuration parameters.
- `pledgeCapital`: Allows investors to pledge capital during the prefund and active sale.
- `requestRefund`: Allows investors to request a refund within the refund stage.
- `withdrawCapital`: Enables the project admin to withdraw raised capital post-sale.
- `claimTokenAllocation`: Allows investors to claim their token allocation.
- `claimExcessCapital`: Allows investors to claim excess capital pledged to the sale.
- `releaseTokens`: Releases vested tokens to investors.
- `supplyTokens`: Allows the project admin to supply tokens for the sale.
- `publishSaleResults`: Publishes the results of the fixed price sale.
- `publishExcessCapitalResults`: Publishes the results for excess capital pledged to the sale.
- `cancelSale`: Allows the project admin to cancel the sale.
- `cancelExpiredSale`: Cancels the sale if it has expired.
- `claimBackCapitalIfCanceled`: Allows investors to claim back their capital if the sale is canceled.

### 3. LegionSaleFactory

The `LegionSaleFactory` contract is a factory responsible for deploying proxy instances of the Legion sale contracts. It creates new sales by cloning the existing templates and initializing them with specific configurations.

#### Key Functions:

- `createFixedPriceSale`: Deploys a new instance of `LegionFixedPriceSale`.
- `createSealedBidAuction`: Deploys a new instance of `LegionSealedBidAuction`.

### 4. LegionLinearVesting

The `LegionLinearVesting` contract handles the linear vesting of tokens for investors. It releases vested tokens over a specified duration, ensuring that tokens are distributed gradually according to a predefined schedule.

#### Key Functions:

- `initialize`: Initializes the vesting contract with the beneficiary, start timestamp, and vesting duration.

### 5. LegionVestingFactory

The `LegionVestingFactory` contract is a factory for deploying proxy instances of Legion vesting contracts. It allows for the creation of new vesting schedule contracts.

#### Key Functions:

- `createLinearVesting`: Creates a new instance of `LegionLinearVesting`.

### 6. LegionAddressRegistry

The `LegionAddressRegistry` contract maintains a registry of key addresses used in the Legion protocol. It allows for the storage and retrieval of addresses associated with unique identifiers, ensuring that all critical addresses are managed and accessible in a centralized registry.

#### Key Functions:

- `setLegionAddress`: Sets an address in the registry.
- `getLegionAddress`: Retrieves an address from the registry.

### 7. LegionAccessControl

The `LegionAccessControl` contract serves as a single point of interaction between Legion and the other contracts in the protocol that require Legion admin access. Two roles are defined: `DEFAULT_ADMIN` and `BROADCASTER`. The `DEFAULT_ADMIN` can grant and revoke `BROADCASTER` roles, whereas the `BROADCASTER` role is only able to perform `functionCall` calls to external contracts.

#### Key Functions:

- `functionCall`: Calls an external contract with specified data. Only callable by the `BROADCASTER` role.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
