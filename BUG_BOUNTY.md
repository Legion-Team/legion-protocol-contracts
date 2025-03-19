![image](https://github.com/user-attachments/assets/167f704f-677f-4682-afbd-f64fedd93698)

# Protecting the Legion Protocol

For us at Legion, the integrity of our Token Sales Protocol is non-negotiable. We’ve invested countless hours into designing and validating this system to ensure it’s both robust and reliable. That said, we know security isn’t a one-and-done deal — it’s an evolving battlefield. If you detect a vulnerability, we’d appreciate it if you’d check out the info below and let us know what you’ve found.

## Legion Bug Bounty Program

### What It’s All About

Kicking off on March 1, 2025, our Bug Bounty Program covers the [Legion-Team/legion-protocol-contracts](https://github.com/Legion-Team/legion-protocol-contracts) repository. It’s our way of thanking those who responsibly pinpoint and help us tackle major weaknesses in the protocol.

We’re zeroing in on the nastiest bugs — think critical or high-severity threats — with rewards topping out at $75,000. Ready to dig in? Let’s do this.

### How We Pay Out

Rewards hinge on how serious the issue is, and we’ll judge that at our discretion. For catastrophic bugs that could tank user funds, you’re looking at up to $75,000. Smaller catches get a fair but flexible payout based on impact.

### Reporting Process

Send your discoveries exclusively to [security@legion.cc](mailto:security@legion.cc) — Markdown text only, no files, please.

Keep it under wraps: don’t broadcast the flaw anywhere until we’ve been alerted, patched it, and given the go-ahead to share. You’ve got 24 hours from finding it to drop us a line.

Thorough reports increase your chances of a reward — and maybe a bigger one. Include:

- The conditions that set off the bug.
- Step-by-step instructions or a demo to replicate it.
- The potential damage if someone exploited it.
- Working Proof of Concept/Code (PoC) using Foundry.

Nail a unique, high-stakes bug that leads to a fix, and stay quiet until we’re clear? You can choose a public nod for your efforts.

### Who’s Eligible

To score a bounty, here’s what you need to do:

- Find a new, unreported vulnerability that puts ERC-20 tokens in Legion at risk—not in external setups — and fits this program’s scope.
- Confirm it’s not already flagged in our [audits](https://github.com/Legion-Team/legion-protocol-contracts/tree/master/audits).
- Be the first to report it to [security@legion.cc](mailto:security@legion.cc) following our guidelines. If others report the same thing close behind, we’ll split the reward as we see fit.
- Provide sufficient detail for us to confirm and resolve it.
- Keep it legal — no coercion or sketchy tactics.
- Don’t abuse the bug beyond proving it (e.g., no leaks or profiteering).
- Avoid disrupting users, data, or the protocol’s flow.
- Report one issue per submission, unless chaining them reveals a broader threat.
- Have no current or past ties to Legion as a contractor or an employee.

### Eligible Targets

The program hones in on vulnerabilities that could siphon off or indefinitely lock assets within our smart contracts. That’s the main event.

Here’s what’s *off the table*:

- Code outside the `master` branch.
- Anything in [tests](./tests), [script](./script), [src/mocks](./src/mocks), [src/lib](./src/lib), [src/utils](./src/utils), or [src/interfaces](./src/interfaces) folders.
- Bugs already reported by others.
- Known issues tied to third-party contracts built on top of Legion.
- Problems in external systems or contracts interacting with us.
- Testnet deployments — no points for sandbox wins.

And these don’t count either:

- Breakdowns in outside services.
- Compromised private keys.
- Phishing schemes or fake sites.
- DDoS onslaughts.
- Social manipulation tricks.
- UI bugs (like misleading clicks).
- Spam floods.
- Automated tool outputs (e.g., CI/CD scans).



