// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionFixedPriceSaleFactory } from "../src/factories/LegionFixedPriceSaleFactory.sol";

contract LegionFixedPriceSaleFactoryScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        address legionBouncer = vm.envAddress("LEGION_BOUNCER");

        vm.startBroadcast(deployerPrivateKey);

        new LegionFixedPriceSaleFactory(legionBouncer);

        vm.stopBroadcast();
    }
}
