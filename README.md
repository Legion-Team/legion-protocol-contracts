```
       ___       ___           ___                       ___           ___
      /\__\     /\  \         /\  \          ___        /\  \         /\__\
     /:/  /    /::\  \       /::\  \        /\  \      /::\  \       /::|  |
    /:/  /    /:/\:\  \     /:/\:\  \       \:\  \    /:/\:\  \     /:|:|  |
   /:/  /    /::\~\:\  \   /:/  \:\  \      /::\__\  /:/  \:\  \   /:/|:|  |__
  /:/__/    /:/\:\ \:\__\ /:/__/_\:\__\  __/:/\/__/ /:/__/ \:\__\ /:/ |:| /\__\
  \:\  \    \:\~\:\ \/__/ \:\  /\ \/__/ /\/:/  /    \:\  \ /:/  / \/__|:|/:/  /
   \:\  \    \:\ \:\__\    \:\ \:\__\   \::/__/      \:\  /:/  /      |:/:/  /
    \:\  \    \:\ \/__/     \:\/:/  /    \:\__\       \:\/:/  /       |::/  /
     \:\__\    \:\__\        \::/  /      \/__/        \::/  /        /:/  /
      \/__/     \/__/         \/__/                     \/__/         \/__/

```

# Legion Protocol Smart Contracts

This repository contains the smart contracts of the Legion Protocol.

Detailed documentation is available at [docs.legion.cc](https://legion-1.gitbook.io/legion).

## Background

Legion is a groundbreaking platform that connects value-added network participants with the most promising crypto projects. Our platform facilitates compliant and incentive-aligned investments, both pre-Token Generation Event (TGE) and for token launches.

## Overview

The Legion protocol consists of smart contracts designed to facilitate different types of ERC20 token sales and manage related operations. The first supported types of sales are a traditional **Fixed Price Sale**, **Sealed Bid Auction Sale**, and a **Pre-Liquid Token Sale**. Below is an overview of all the key actors, along with a description of the functionality for each contract.

**Key Actors:**

- **Investor** - The user participating in a sale and pledging capital.
- **Project** - The project raising capital and launching a token.
- **Legion** - Our protocol, facilitating the token distribution and capital raising.

## Architecture

Legion uses a Clone Pattern utilizing the [EIP-1167 Minimal Proxy Standard](https://eips.ethereum.org/EIPS/eip-1167) for deploying sale and vesting schedule contracts. Standard **Merkle Proof** is used for verification of different conditions, such as eligibility to distribute tokens to investors.

Legion's smart contracts work together with Legion's backend, which is responsible for publishing sale results after analyzing and indexing events emitted during the sale process.

## System Limitations

Legion Protocol smart contracts are designed to work tightly with Legion's backend. It is unfeasible for the smart contracts to work independently from the backend, as they rely heavily on calculations performed off-chain. Moreover, there are certain centralized aspects of the system, which are by design - a Legion admin is responsible for publishing results from sales, and a sale cannot be settled without Legion.

On another note, as the system is heavily dependent on the actions of all actors - Legion and the Projects, certain precautions have been taken in case some of the actors don't act (e.g., publish results or supply tokens). In this case, if a sale "expires", users are able to claim back their funds, without requiring any action from Legion's side.

## Known Risks

- **Centralization** - Certain actions rely heavily on the admin access of the parties involved - Legion and the Projects, which requires trust. If by any chance, Legion's or the Project's access is compromised, this can cause problems across the whole system.
- **Third-Party software** - Legion relies heavily on AWS (Amazon Web Services) for managing the contracts' state. If there's a problem with AWS, this can reflect on active sales running through Legion.
- **External smart contracts** - Interacting with external ERC20 token smart contracts like USDC could pose a risk of getting funds blacklisted, requiring additional steps from Legion to resolve this directly with the issuer.

## Access Control and Privileged Roles

- **Legion** - Legion's admin access and interactions are controlled through the `LegionBouncer` contract. A `BROADCASTER` role is granted to the AWS Broadcaster Wallet, responsible for executing function calls requiring Legion's access privileges.
- **Projects** - Projects will be required to interact with Legion via a Safe Multisig wallet.

## Smart Contracts

### Fixed Price Sale

The `LegionFixedPriceSale` contract is used to execute fixed price sales of ERC20 tokens after the Token Generation Event (TGE). It manages the entire lifecycle of the sale, including capital pledging, refunds, raised capital withdrawal, token distribution for vesting, and sale cancellation.

Every fixed price sale consists of 5 stages, explained below:

#### Fixed Price Sale Stages:

1. **Prefund Stage**: During the prefund stage, investors prefund the sale by pledging capital.
2. **Prefund Allocation Period**: Projects decide allocations for the investors who participated in the prefund, based on their reputation or other factors. This process is facilitated by Legion's backend and, depending on the outcome, the prefund can be fully subscribed.
3. **Active Sale Period**: The actual sale stage where investors pledge capital.
4. **Refund Period**: This stage is required by the MiCA regulation, where users can receive a refund if they decide. After the refund period is over, Legion publishes the results from the sale. Projects provide the allocated tokens and withdraw the raised capital from the sale.
5. **Lockup Period**: This stage complies with Regulation S. The lockup period starts immediately after a sale ends. Once it is over, investors are allowed to withdraw their allocations into a vesting schedule contract.

#### Key Functions:

- `initialize`: Initializes the sale with configuration parameters.
- `invest`: Allows investors to pledge capital during the prefund and active sale.
- `refund`: Allows investors to request a refund within the refund stage.
- `withdrawRaisedCapital`: Enables the project admin to withdraw raised capital post-sale.
- `claimTokenAllocation`: Allows investors to claim their token allocation.
- `withdrawExcessInvestedCapital`: Allows investors to claim excess capital pledged to the sale.
- `releaseVestedTokens`: Releases vested tokens to investors.
- `supplyTokens`: Allows the project admin to supply tokens for the sale.
- `publishSaleResults`: Publishes the results of the fixed price sale.
- `setAcceptedCapital`: Publishes the results for excess capital pledged to the sale.
- `cancelSale`: Allows the project admin to cancel the sale.
- `cancelExpiredSale`: Cancels the sale if it has expired.
- `withdrawInvestedCapitalIfCanceled`: Allows investors to claim back their capital if the sale is canceled.

### Sealed Bid Auction Sale

The `LegionSealedBidAuctionSale` contract is used to execute sealed bid auctions of ERC20 tokens after the Token Generation Event (TGE). It manages the entire lifecycle of the sale, including capital pledging, refunds, raised capital withdrawal, token distribution for vesting, and sale cancellation.

`LegionSealedBidAuctionSale` uses ECIES encryption. At the beginning of every sealed bid auction, Legion publishes an EC public key. The public key is used by investors to encrypt the amount of the `askToken` they want to purchase. The amount of the `bidToken` is visible to everyone, as it is transferred to the contract at the time of pledging capital.

After the sealed bid auction concludes and results are published by Legion, the private key is released to the public. From this point on, everyone is able to decrypt their bids and verify if they are correct.

Every sealed bid auction consists of three stages, explained below:

#### Sealed Bid Auction Stages:

1. **Active Sale Period**: The actual sale stage where investors pledge capital.
2. **Refund Period**: This stage is required by the MiCA regulation, where users can receive a refund if they decide. After the refund period is over, Legion publishes the results from the sale. Projects provide the allocated tokens and withdraw the raised capital from the sale.
3. **Lockup Period**: This stage complies with Regulation S. The lockup period starts immediately after a sale ends. Once it is over, investors are allowed to withdraw their allocations into a vesting schedule contract.

#### Key Functions:

- `initialize`: Initializes the sale with configuration parameters.
- `invest`: Allows investors to pledge capital during the active sale.
- `refund`: Allows investors to request a refund within the refund stage.
- `withdrawRaisedCapital`: Enables the project admin to withdraw raised capital post-sale.
- `claimTokenAllocation`: Allows investors to claim their token allocation.
- `withdrawExcessInvestedCapital`: Allows investors to claim excess capital pledged to the sale.
- `releaseVestedTokens`: Releases vested tokens to investors.
- `supplyTokens`: Allows the project admin to supply tokens for the sale.
- `publishSaleResults`: Publishes the results of the sealed bid auction.
- `setAcceptedCapital`: Publishes the results for excess capital pledged to the sale.
- `cancelSale`: Allows the project admin to cancel the sale.
- `cancelExpiredSale`: Cancels the sale if it has expired.
- `withdrawInvestedCapitalIfCanceled`: Allows investors to claim back their capital if the sale is canceled.

### Pre-Liquid Token Sale

The `LegionPreLiquidSaleV2` contract is used to execute pre-liquid sales of ERC20 tokens **before** the Token Generation Event (TGE). It manages the entire lifecycle of the sale, including investing, refunds, raised capital withdrawal, token distribution for vesting, and sale cancellation.

The main difference with the other types of sales Legion offers is that the pre-liquid sale commences before the token actually exists and is deployed (Pre-TGE). Only whitelisted users are allowed to invest in the sale, once they have signed a legally binding SAFT (Simple Agreement for Future Tokens). Once TGE occurs, Legion publishes the data on-chain, and projects supply the tokens for distribution.

As there is a certain time gap between the period when capital is raised and the TGE, projects are allowed to withdraw capital before they supply the tokens, as they might need early access to it. However, once any raised capital is withdrawn, no changes are allowed to the `saftMerkleRoot` and `vestingTerms`.

In comparison to other sale contracts, the `LegionPreLiquidSaleV2` is more asynchronous; however, its stages can be described as follows:

1. **Active Investment Period**: The stage where whitelisted users invest capital and investments are accepted.
2. **Refund Period**: This stage is required by the MiCA regulation, where users can receive a refund if they decide. In the case of a pre-liquid sale, the refund period is counted individually for each investor.
3. **Capital Withdrawal**: Once a refund period for an investor is over, projects are allowed to withdraw the raised capital from this investor.
4. **Token Claims**: After the TGE details are published by Legion and tokens are supplied by the project, investors are allowed to claim their tokens into the vesting contract deployed for them.

#### Key Functions:

- `initialize`: Initializes the sale with configuration parameters.
- `invest`: Allows whitelisted users (SAFT signers) to invest in the pre-liquid sale.
- `refund`: Allows investors to receive a full refund within 14 days since their investment (MiCA).
- `publishTgeDetails`: Publishes the TGE details, called by Legion.
- `supplyTokens`: Allows the project admin to supply tokens for the sale.
- `updateSAFTMerkleRoot`: Allows Legion to update the SAFT Merkle root.
- `updateVestingTerms`: Allows the project admin to update the vesting terms for the pre-liquid sale.
- `withdrawRaisedCapital`: Allows the project admin to withdraw raised capital.
- `claimTokenAllocation`: Allows investors to claim their token allocation, after TGE and tokens are supplied by the project.
- `cancelSale`: Allows the project admin to cancel the sale.
- `withdrawInvestedCapitalIfCanceled`: Allows investors to withdraw back their capital if the sale is canceled.
- `withdrawExcessInvestedCapital`: Allows investors to withdraw excess capital in case they've provided more than the amount according to the SAFT has been lowered.
- `endSale`: Allows the project admin to pause/unpause accepting investments to the sale.

### Sale Factory

The `LegionSaleFactory` contract is a factory responsible for deploying proxy instances of the Legion sale contracts. It creates new sales by cloning the existing templates and initializing them with specific configurations.

#### Key Functions:

- `createFixedPriceSale`: Deploys a new instance of `LegionFixedPriceSale`.
- `createSealedBidAuction`: Deploys a new instance of `LegionSealedBidAuctionSale`.
- `createPreLiquidSaleV2`: Deploys a new instance of `LegionPreLiquidSaleV2`.

### Linear Vesting

The `LegionLinearVesting` contract handles the linear vesting of tokens for investors. It releases vested tokens over a specified duration, ensuring that tokens are distributed gradually according to a predefined schedule.

#### Key Functions:

- `initialize`: Initializes the vesting contract with the beneficiary, start timestamp, and vesting duration.

### Vesting Factory

The `LegionVestingFactory` contract is a factory for deploying proxy instances of Legion vesting contracts. It allows for the creation of new vesting schedule contracts.

#### Key Functions:

- `createLinearVesting`: Creates a new instance of `LegionLinearVesting`.

### Address Registry

The `LegionAddressRegistry` contract maintains a registry of key addresses used in the Legion protocol. It allows for the storage and retrieval of addresses associated with unique identifiers, ensuring that all critical addresses are managed and accessible in a centralized registry.

#### Key Functions:

- `setLegionAddress`: Sets an address in the registry.
- `getLegionAddress`: Retrieves an address from the registry.

### 8. Legion Bouncer

The `LegionBouncer` contract serves as a single point of interaction between Legion and the other contracts in the protocol that require Legion admin access. Two roles are defined: `DEFAULT_ADMIN` and `BROADCASTER`. The `DEFAULT_ADMIN` can grant and revoke `BROADCASTER` roles, whereas the `BROADCASTER` role is only able to perform `functionCall` operations to external contracts.

#### Key Functions:

- `functionCall`: Calls an external contract with specified data. Only callable by the `BROADCASTER` role.
