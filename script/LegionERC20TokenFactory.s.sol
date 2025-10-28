// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionERC20TokenFactory } from "../src/factories/LegionERC20TokenFactory.sol";

contract LegionERC20TokenFactoryScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new LegionERC20TokenFactory();

        vm.stopBroadcast();
    }
}
