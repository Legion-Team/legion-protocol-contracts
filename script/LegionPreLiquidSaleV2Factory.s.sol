// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionPreLiquidSaleV2Factory } from "../src/factories/LegionPreLiquidSaleV2Factory.sol";

contract LegionPreLiquidSaleV2FactoryScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        address legionBouncer = vm.envAddress("LEGION_BOUNCER");

        vm.startBroadcast(deployerPrivateKey);

        new LegionPreLiquidSaleV2Factory(legionBouncer);

        vm.stopBroadcast();
    }
}
