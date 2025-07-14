// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { LegionReferrerFeeDistributor } from "../src/distribution/LegionReferrerFeeDistributor.sol";
import { ILegionReferrerFeeDistributor } from "../src/interfaces/distribution/ILegionReferrerFeeDistributor.sol";

contract LegionReferrerFeeDistributorScript is Script {
    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address token = vm.envAddress("REFERRER_FEE_TOKEN");
        address addressRegistry = vm.envAddress("ADDRESS_REGISTRY");

        vm.startBroadcast(deployerPrivateKey);

        ILegionReferrerFeeDistributor.ReferrerFeeDistributorInitializationParams memory _initParams =
        ILegionReferrerFeeDistributor.ReferrerFeeDistributorInitializationParams({
            token: token,
            addressRegistry: addressRegistry
        });

        new LegionReferrerFeeDistributor(_initParams);

        vm.stopBroadcast();
    }
}
