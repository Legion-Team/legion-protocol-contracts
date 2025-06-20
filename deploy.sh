source .env
forge script script/LegionBouncer.s.sol:LegionBouncerScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionVestingFactory.s.sol:LegionVestingFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionFixedPriceSaleFactory.s.sol:LegionFixedPriceSaleFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionPreLiquidApprovedSaleFactory.s.sol:LegionPreLiquidApprovedSaleFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionPreLiquidOpenApplicationSaleFactory.s.sol:LegionPreLiquidOpenApplicationSaleFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionSealedBidAuctionSaleFactory.s.sol:LegionSealedBidAuctionSaleFactoryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/LegionAddressRegistry.s.sol:LegionAddressRegistryScript --rpc-url $RPC_URL --broadcast --verify -vvvv
