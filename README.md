![image](https://github.com/user-attachments/assets/167f704f-677f-4682-afbd-f64fedd93698)

# Legion Protocol Smart Contracts

This repository contains the smart contracts for Legion Token Sales Protocol, a platform connecting investors and contributors with high-potential crypto projects for compliant, incentivized investments pre- and post-Token Generation Event (TGE).

Detailed user documentation is available at [docs.legion.cc](https://legion-1.gitbook.io/legion).

## Quick Start

Get started with the Legion Protocol smart contracts by following these steps to set up, build and test the codebase.

```bash
# 1. Clone the repo
$ git clone https://github.com/legion-protocol/legion-protocol-contracts.git

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

Legion facilitates ERC20 token sales — Fixed Price, Sealed Bid Auction, and Pre-Liquid (Approved & Open Application), ERC20 capital raises and ERC20 token distribution — using the [EIP-1167 Minimal Proxy Standard](https://eips.ethereum.org/EIPS/eip-1167) Clone Pattern for deployment and Merkle Proofs + Signatures for eligibility verification.

### Key Actors

- **Investor**: Participates in sales by investing capital.
- **Project**: Raises capital and launches tokens.
- **Legion**: Facilitates token distribution and capital raising.

## Architecture

Legion’s smart contracts leverage a clone pattern for deploying sale and vesting contracts, with standard Merkle Proofs verifying conditions like investor eligibility. They integrate with Legion’s backend, which processes off-chain calculations and publishes sale results based on on-chain actions.

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
- **Bug Bounty**: Our bug bounty program rewards researchers for identifying vulnerabilities. Details, including eligibility and payout ranges, are in [SECURITY.md](SECURITY.md).
