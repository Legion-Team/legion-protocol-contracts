// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";

contract LegionVestingFactoryScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new LegionVestingFactory();

        vm.stopBroadcast();
    }
}
