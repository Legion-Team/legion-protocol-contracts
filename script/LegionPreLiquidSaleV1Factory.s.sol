// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionPreLiquidSaleV1Factory } from "../src/factories/LegionPreLiquidSaleV1Factory.sol";

contract LegionPreLiquidSaleV1FactoryScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        address legionBouncer = vm.envAddress("LEGION_BOUNCER");

        vm.startBroadcast(deployerPrivateKey);

        new LegionPreLiquidSaleV1Factory(legionBouncer);

        vm.stopBroadcast();
    }
}
