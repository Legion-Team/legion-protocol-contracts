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

# Security Policy

## Reporting a Vulnerability

If you find a bug, please contact security@legion.cc. We will pay a fair bounty for any issue that puts user's funds at risk.

## Responsible Parties

In the event of an incident, the **Legion Tech Team** will be responsible for mitigating the issue.

## Handling Failed Remediations

If a remediation fails or a new bug is introduced, the following steps will be executed:

- Legion will pause the existing frontend to prevent user interaction with the protocol until it is safe.
- Legion will perform an `emergencyWithdraw` of the funds in all active sale contracts.
- Legion will implement the required changes and deploy a new instance of the contracts once they have been audited by a partner auditing company.

## Deployment Process

Legion's smart contract deployment is automated through **AWS**.

## Compensation Policy

Legion has no current obligation to refund funds resulting from unrecoverable security incidents related to smart contract vulnerabilities.

## Potential Vulnerabilities Awareness

To stay updated with the latest security threats, Legion's team is part of various security communities such as the [ETHSecurity Community](https://t.me/ETHSecurity) and follows sources like [rekt.news](https://rekt.news).

Legion also plans to list the protocol's smart contracts on bug bounty platforms such as [Immunefi](https://immunefi.com).

## External Parties Assistance

Depending on the identified issues, Legion will seek assistance from external parties such as stablecoin issuers (e.g., [Circle](https://www.circle.com/en/) and [Tether](https://tether.to/en/)) to potentially block lost funds, auditors from Legion's network, and the [Security Alliance](https://securityalliance.org/).

## Smart Contract Monitoring

Legion will use **OpenZeppelin Defender's** Monitor service to track any suspicious activity related to the protocol's smart contracts.

We will specifically monitor:

- Smart contract ownership changes
- Access control changes
- Suspicious account activity related to Legion's admin addresses

A Telegram channel created for this specific purpose will receive alerts from **OpenZeppelin Defender's** Monitor.

## Incident Response in Case of Blacklist

### Context

Certain token contracts, such as USDC, implement a blocklist that allows the owner to freeze funds in specific accounts. If any of the deployed sales or auction contracts are blocklisted from the bid token, legitimate investors' funds will be locked.

### Options

If this occurs, we have no options to resolve the issue single-handedly.

What we should do in this case is contact the stable coin issuer to learn why they blocked this address, explain the implications to them, and ask for an unblock since they are blocking more than a single individual.

### Plan

- Contact stable coin issuer to explore options.
- Inform the users, either before or after the stable coin issuer provides an answer. An announcement should be made, preferably in a private manner, to all affected investors, informing them that issuer has blocked our sale contract and that we are working to resolve the situation.
