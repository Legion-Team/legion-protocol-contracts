source .env
forge script script/LegionAccessControl.s.sol:LegionAccessControlScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionVestingFactory.s.sol:LegionVestingFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionSaleFactory.s.sol:LegionSaleFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionAddressRegistry.s.sol:LegionAddressRegistryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
