// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionAddressRegistry } from "../src/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/LegionBouncer.sol";

contract LegionAddressRegistryScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        address legionBouncer = vm.envAddress("LEGION_BOUNCER");
        address legionSigner = vm.envAddress("LEGION_SIGNER");
        address legionFeeReceiver = vm.envAddress("LEGION_FEE_RECEIVER");
        address legionVestingFactory = vm.envAddress("LEGION_VESTING_FACTORY");

        vm.startBroadcast(deployerPrivateKey);

        LegionAddressRegistry addressRegistry = new LegionAddressRegistry(legionBouncer);

        LegionBouncer(legionBouncer).functionCall(
            address(addressRegistry),
            abi.encodeWithSelector(
                LegionAddressRegistry.setLegionAddress.selector, bytes32("LEGION_BOUNCER"), legionBouncer
            )
        );

        LegionBouncer(legionBouncer).functionCall(
            address(addressRegistry),
            abi.encodeWithSelector(
                LegionAddressRegistry.setLegionAddress.selector, bytes32("LEGION_SIGNER"), legionSigner
            )
        );

        LegionBouncer(legionBouncer).functionCall(
            address(addressRegistry),
            abi.encodeWithSelector(
                LegionAddressRegistry.setLegionAddress.selector, bytes32("LEGION_FEE_RECEIVER"), legionFeeReceiver
            )
        );

        LegionBouncer(legionBouncer).functionCall(
            address(addressRegistry),
            abi.encodeWithSelector(
                LegionAddressRegistry.setLegionAddress.selector, bytes32("LEGION_VESTING_FACTORY"), legionVestingFactory
            )
        );

        vm.stopBroadcast();
    }
}
