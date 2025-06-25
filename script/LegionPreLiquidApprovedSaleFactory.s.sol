// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionPreLiquidApprovedSaleFactory } from "../src/factories/LegionPreLiquidApprovedSaleFactory.sol";

contract LegionPreLiquidApprovedSaleFactoryScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        address legionBouncer = vm.envAddress("LEGION_BOUNCER");

        vm.startBroadcast(deployerPrivateKey);

        new LegionPreLiquidApprovedSaleFactory(legionBouncer);

        vm.stopBroadcast();
    }
}
