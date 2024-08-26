// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {LegionSaleFactory} from "../src/LegionSaleFactory.sol";

contract LegionSaleFactoryScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address legionAdmin = vm.envAddress("LEGION_ADMIN");
        vm.startBroadcast(deployerPrivateKey);

        LegionSaleFactory legionSaleFactory = new LegionSaleFactory(legionAdmin);

        vm.stopBroadcast();
    }
}
