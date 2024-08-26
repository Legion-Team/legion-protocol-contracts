# Incident Response Plan

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
