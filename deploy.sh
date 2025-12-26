source .env
forge script script/LegionBouncer.s.sol:LegionBouncerScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionVestingFactory.s.sol:LegionVestingFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionPreLiquidSaleFactory.s.sol:LegionPreLiquidOpenApplicationSaleFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionSealedBidSaleFactory.s.sol:LegionSealedBidSaleFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionSealedVestingSaleFactory.s.sol:LegionSealedVestingSaleFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionAddressRegistry.s.sol:LegionAddressRegistryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionReferrerFeeDistributor.s.sol:LegionReferrerFeeDistributor --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionTokenDistributorFactory.s.sol:LegionTokenDistributorFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
