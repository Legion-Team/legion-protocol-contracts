# Incident Response in Case of Blacklist

## Context

Certain token contracts, such as USDC, implement a blocklist that allows the owner to freeze funds in specific accounts. If any of the deployed sales or auction contracts are blocklisted from the bid token, legitimate investors' funds will be locked.

## Options

If this occurs, we have no options to resolve the issue single-handedly.

What we should do in this case is contact the stable coin issuer to learn why they blocked this address, explain the implications to them, and ask for an unblock since they are blocking more than a single individual.

## Plan

- Contact stable coin issuer to explore options.
- Inform the users, either before or after the stable coin issuer provides an answer. An announcement should be made, preferably in a private manner, to all affected investors, informing them that issuer has blocked our sale contract and that we are working to resolve the situation.
