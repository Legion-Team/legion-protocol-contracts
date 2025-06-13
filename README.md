![image](https://github.com/user-attachments/assets/167f704f-677f-4682-afbd-f64fedd93698)

# Legion Protocol Smart Contracts

This repository contains the smart contracts for Legion Token Sales Protocol, a platform connecting investors and contributors with high-potential crypto projects for compliant, incentivized investments pre- and post-Token Generation Event (TGE).

Detailed user documentation is available at [docs.legion.cc](https://legion-1.gitbook.io/legion).

## Quick Start

Get started with the Legion Protocol smart contracts by following these steps to set up, build and test the codebase.

```bash
# 1. Clone the repo
$ git clone https://github.com/legion-protocol/legion-contracts.git

# 2. Install dependencies
$ forge install

# 3. Compile contracts
$ forge build

# 4. Run tests
$ forge test

# 5. Run coverage
$ forge coverage --no-match-coverage "(script|test|lib|mocks)"
```

Run static analysis with **Slither** and **Aderyn**.

```bash
# 1. Run Slither (requires Slither installed via `brew install slither-analyzer`)
$ slither .

# 2. Run Aderyn (requires Aderyn by Cyfrin, installed via `brew install cyfrin/tap/aderyn`)
$ aderyn .
```

## Background

Legion connects investors and contributors with promising crypto projects, enabling compliant and incentive-aligned investments before and after Token Generation Events (TGEs). Our platform supports both pre-TGE fundraising and token launches, streamlining capital raising and token distribution.

## Overview

Legion facilitates ERC20 token sales — Fixed Price, Sealed Bid Auction, and Pre-Liquid (Approved & Open Application) — using the [EIP-1167 Minimal Proxy Standard](https://eips.ethereum.org/EIPS/eip-1167) Clone Pattern for deployment and Merkle Proofs for eligibility verification.

### Key Actors

- **Investor**: Participates in sales by investing capital.
- **Project**: Raises capital and launches tokens.
- **Legion**: Facilitates token distribution and capital raising.

## Architecture

Legion’s smart contracts leverage a clone pattern for deploying sale and vesting contracts, with standard Merkle Proofs verifying conditions like investor eligibility. They integrate with Legion’s backend, which processes off-chain calculations and publishes sale results based on emitted events.

## System Limitations

Legion’s smart contracts are designed to work seamlessly with our backend for off-chain calculations, such as sale result processing, ensuring efficiency and compliance. While this introduces dependency, it enables complex operations not feasible on-chain alone.

## Known Risks

- **Centralization**: Admin actions rely on trusted parties.
- **Third-Party Software**: AWS dependency is monitored with redundancy plans to mitigate outages.
- **External Smart Contracts**: Interactions with ERC20 tokens (e.g., USDC) risk blacklisting; we audit these and maintain issuer communication.

## Access Control and Privileged Roles

- **Legion**: Managed via the `LegionBouncer` contract. The `BROADCASTER` role, granted to an AWS Broadcaster Wallet, executes privileged calls, while `DEFAULT_ADMIN` manages roles.
- **Projects**: Interact via Safe Multisig wallets for security.

## Security

We prioritize security in our smart contracts and operations.

- **Security Policy**: See [SECURITY.md](SECURITY.md) for vulnerability reporting guidelines and our incident response plan.
- **Bug Bounty**: Our bug bounty program rewards researchers for identifying vulnerabilities. Details, including eligibility and payout ranges, are in [BUG_BOUNTY.md](BUG_BOUNTY.md).

## Smart Contracts

Legion supports multiple sale types with shared lifecycle stages (e.g., Active Sale, Refund, Claim). Below are unique aspects of each contract:

### Fixed Price Sale

- **Purpose**: Post-TGE fixed-price token sales.
- **Contract**: `LegionFixedPriceSale`
- **Unique Stages**:
  - **Prefund Stage**: Investors invest capital to prefund the sale.
  - **Prefund Allocation Period**: Projects allocate based on reputation or other factors, facilitated by Legion’s backend.
  - **Active Sale Period**: Main sale phase for capital investments.
  - **Refund Period**: MiCA-compliant refund window; Legion publishes results, Projects supply tokens.
  - **Claim Period**: Investors claim tokens into vesting contracts.

### Sealed Bid Auction Sale

- **Purpose**: Post-TGE sealed bid auctions with ECIES encryption.
- **Contract**: `LegionSealedBidAuctionSale`
- **Unique Feature**: Investors encrypt bids with a Legion-published public key; private key revealed post-sale for verification.
- **Stages**:
  - **Active Sale Period**: Investors invest visible `bidToken` amounts with encrypted `askToken` bids.
  - **Refund Period**: MiCA-compliant refunds; Legion publishes results, Projects supply tokens.
  - **Claim Period**: Investors claim tokens into vesting contracts.

### Pre-Liquid Approved Sale

- **Purpose**: Pre-TGE sales for whitelisted SAFT signers.
- **Contract**: `LegionPreLiquidApprovedSale`
- **Unique Feature**: Asynchronous; Projects can withdraw capital pre-TGE, locking configuration post-withdrawal.
- **Stages**:
  - **Active Investment Period**: Whitelisted investors invest capital.
  - **Refund Period**: 14-day MiCA refund per investor.
  - **Capital Withdrawal**: Projects withdraw post-refunded capital.
  - **Claim Period**: Post-TGE token claiming after Legion publishes details.

### Pre-Liquid Open Application Sale

- **Purpose**: Pre-TGE sales with max deposit and Project acceptance.
- **Contract**: `LegionPreLiquidOpenApplicationSale`
- **Unique Feature**: Investors deposit max funds; Projects accept amounts, allowing excess withdrawal.
- **Stages**:
  - **Pre-Deposit Period**: Investors deposit max allocation.
  - **Acceptance Period**: Projects approve amounts; excess withdrawable immediately or post-refunded.
  - **Refund Period**: 14-day MiCA refund per investor.
  - **Capital Withdrawal**: Projects withdraw post-refunded capital.
  - **Claim Period**: Post-TGE token claiming.

### Factories

- **Fixed Price Sale Factory**: `LegionFixedPriceSaleFactory`
- **Pre-Liquid Sale V1 Factory**: `LegionPreLiquidApprovedSaleFactory`
- **Pre-Liquid Sale V2 Factory**: `LegionPreLiquidOpenApplicationSaleFactory`
- **Sealed Bid Auction Sale Factory**: `LegionSealedBidAuctionSaleFactory`

### Vesting Contracts

- **Linear Vesting**: `LegionLinearVesting`
  - Gradual token release over a duration.
- **Linear Epoch Vesting**: `LegionLinearEpochVesting`
  - Epoch-based token release.
- **Vesting Factory**: `LegionVestingFactory`

### Utilities

- **Address Registry**: `LegionAddressRegistry`
- **Legion Bouncer**: `LegionBouncer`
  - Controls Legion admin access with `DEFAULT_ADMIN` and `BROADCASTER` roles.
