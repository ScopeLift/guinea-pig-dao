<div align="center">
	<img width="150" src="images/guinea-pig-dao-astro-logo.png" alt="Guinea Pig Logo">
	<h1>Guinea Pig DAO</h1>
	<strong>A fake DAO with real contracts, created for testing cutting edge technology and tooling.</strong>
</div>


## About

Guinea Pig DAO is a "fake" DAO with "real" smart contracts. It's deployed on Ethereum mainnet and uses the same family of governance contracts as many large DAOs. Specifically, Guinea Pig DAO uses the Open Zeppelin implementation of the Compound-style "Governor" contracts, and includes ScopeLift's [Flexible Voting](https://flexiblevoting.com) extension.

Guinea Pig DAO's raison d'être is to serve as a testbed for cutting edge DAO contracts and tooling. Testing DAO tech and tooling in a realistic scenario can be difficult. Local network and testnet deployments can only go so far. Yet real DAOs have proposal thresholds with real economic costs and long voting periods that make iterative testing challenging. Real DAOs also have real funds at stake and can't afford to take haphazard risks.

With real contracts on Ethereum mainnet, Guinea Pig DAO allows for testing in a realistic environment, including integrations with other onchain infrastructure. At the same time, Guinea Pig DAO has short delays and nothing at stake economically.

## Development

This repository uses [Foundry](https://github.com/foundry-rs/foundry). Be sure to have it [installed](https://book.getfoundry.sh/getting-started/installation). After cloning the repo, run `forge install` to install dependencies, `forge build` to compile the contracts, and `forge test` to execute the tests.

It's also recommend to install [scopelint](https://github.com/ScopeLift/scopelint), which is used in CI.
You can run this locally with `scopelint fmt` and `scopelint check`.
Note that these are supersets of `forge fmt` and `forge fmt --check`, so you do not need to run those forge commands when using scopelint.

## License

The code in this repository is available under the [MIT](LICENSE.txt) license, unless otherwise indicated.

Copyright © 2024 ScopeLift