// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {LegionAccessControl} from "../src/LegionAccessControl.sol";

contract LegionAccessControlScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address legionEOA = vm.envAddress("LEGION_EOA");
        address legionAwsBrodcaster = vm.envAddress("LEGION_AWS_BROADCASTER");
        vm.startBroadcast(deployerPrivateKey);

        LegionAccessControl legionAccessControl = new LegionAccessControl(legionEOA, legionAwsBrodcaster);

        vm.stopBroadcast();
    }
}
