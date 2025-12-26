// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionSealedVestingSaleFactory } from "../src/factories/LegionSealedVestingSaleFactory.sol";

contract LegionSealedVestingSaleFactoryScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        address legionBouncer = vm.envAddress("LEGION_BOUNCER");

        vm.startBroadcast(deployerPrivateKey);

        new LegionSealedVestingSaleFactory(legionBouncer);

        vm.stopBroadcast();
    }
}
