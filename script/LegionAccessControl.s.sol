// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {LegionAccessControl} from "../src/LegionAccessControl.sol";

contract LegionAccessControlScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        address legionDefaultAdmin = vm.envAddress("LEGION_DEFAULT_ADMIN");
        address legionDefaultBrodcaster = vm.envAddress("LEGION_DEFAULT_BROADCASTER");

        vm.startBroadcast(deployerPrivateKey);

        LegionAccessControl legionBouncer = new LegionAccessControl(legionDefaultAdmin, legionDefaultBrodcaster);

        vm.stopBroadcast();
    }
}
