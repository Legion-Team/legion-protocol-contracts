// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console2, Vm} from "forge-std/Test.sol";

import {ECIES, Point} from "../src/lib/ECIES.sol";

import {ILegionBaseSale} from "../src/interfaces/ILegionBaseSale.sol";
import {ILegionFixedPriceSale} from "../src/interfaces/ILegionFixedPriceSale.sol";
import {ILegionPreLiquidSale} from "../src/interfaces/ILegionPreLiquidSale.sol";
import {ILegionSealedBidAuction} from "../src/interfaces/ILegionSealedBidAuction.sol";
import {ILegionSaleFactory} from "../src/interfaces/ILegionSaleFactory.sol";
import {LegionAddressRegistry} from "../src/LegionAddressRegistry.sol";
import {LegionFixedPriceSale} from "../src/LegionFixedPriceSale.sol";
import {LegionPreLiquidSale} from "../src/LegionPreLiquidSale.sol";
import {LegionSealedBidAuction} from "../src/LegionSealedBidAuction.sol";
import {LegionSaleFactory} from "../src/LegionSaleFactory.sol";
import {LegionVestingFactory} from "../src/LegionVestingFactory.sol";
import {MockToken} from "../src/mocks/MockToken.sol";

contract LegionSaleFactoryTest is Test {
    ILegionFixedPriceSale.FixedPriceSaleConfig fixedPriceSaleConfig;
    ILegionPreLiquidSale.PreLiquidSaleConfig preLiquidSaleConfig;
    ILegionSealedBidAuction.SealedBidAuctionConfig sealedBidAuctionConfig;

    LegionAddressRegistry legionAddressRegistry;
    LegionSaleFactory legionSaleFactory;
    LegionVestingFactory legionVestingFactory;

    MockToken bidToken;
    MockToken askToken;

    address legionFixedPriceSaleInstance;
    address legionPreLiquidSaleInstance;
    address legionSealedBidAuctionInstance;

    address legionBouncer = address(0x01);
    address projectAdmin = address(0x02);
    address nonOwner = address(0x03);
    address legionFeeReceiver = address(0x04);

    uint256 legionSignerPK = 1234;

    uint256 constant PREFUND_PERIOD_SECONDS = 3600;
    uint256 constant PREFUND_ALLOCATION_PERIOD_SECONDS = 3600;
    uint256 constant SALE_PERIOD_SECONDS = 3600;
    uint256 constant REFUND_PERIOD_SECONDS = 1209600;
    uint256 constant LOCKUP_PERIOD_SECONDS = 3456000;
    uint256 constant VESTING_DURATION_SECONDS = 31536000;
    uint256 constant VESTING_CLIFF_DURATION_SECONDS = 3600;
    uint256 constant LEGION_FEE_CAPITAL_RAISED_BPS = 250;
    uint256 constant LEGION_FEE_TOKENS_SOLD_BPS = 250;
    uint256 constant MINIMUM_PLEDGE_AMOUNT = 1 * 1e18;
    uint256 constant TOKEN_PRICE = 1 * 1e18;

    uint256 constant TOKEN_ALLOCATION_TGE_BPS = 0;
    bytes32 constant SAFT_MERKLE_ROOT = 0xb1f74233838c8077babb1c1e9ca12a76f0ec395a7a2e2501aea9c95f06a6e368;

    Point public PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), 69);

    function setUp() public {
        legionSaleFactory = new LegionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC");
        askToken = new MockToken("LFG Coin", "LFG");
        prepareLegionAddressRegistry();
    }

    /**
     * @dev Helper method to set the fixed price sale configuration
     */
    function setFixedPriceSaleConfig(ILegionFixedPriceSale.FixedPriceSaleConfig memory _fixedPriceSaleConfig) public {
        fixedPriceSaleConfig = ILegionFixedPriceSale.FixedPriceSaleConfig({
            prefundPeriodSeconds: _fixedPriceSaleConfig.prefundPeriodSeconds,
            prefundAllocationPeriodSeconds: _fixedPriceSaleConfig.prefundAllocationPeriodSeconds,
            salePeriodSeconds: _fixedPriceSaleConfig.salePeriodSeconds,
            refundPeriodSeconds: _fixedPriceSaleConfig.refundPeriodSeconds,
            lockupPeriodSeconds: _fixedPriceSaleConfig.lockupPeriodSeconds,
            vestingDurationSeconds: _fixedPriceSaleConfig.vestingDurationSeconds,
            vestingCliffDurationSeconds: _fixedPriceSaleConfig.vestingCliffDurationSeconds,
            legionFeeOnCapitalRaisedBps: _fixedPriceSaleConfig.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _fixedPriceSaleConfig.legionFeeOnTokensSoldBps,
            minimumPledgeAmount: _fixedPriceSaleConfig.minimumPledgeAmount,
            tokenPrice: _fixedPriceSaleConfig.tokenPrice,
            bidToken: _fixedPriceSaleConfig.bidToken,
            askToken: _fixedPriceSaleConfig.askToken,
            projectAdmin: _fixedPriceSaleConfig.projectAdmin,
            addressRegistry: _fixedPriceSaleConfig.addressRegistry
        });
    }

    /**
     * @dev Helper method to set the pre-liquid sale configuration
     */
    function setPreLiquidSaleConfig(ILegionPreLiquidSale.PreLiquidSaleConfig memory _preLiquidSaleConfig) public {
        preLiquidSaleConfig = ILegionPreLiquidSale.PreLiquidSaleConfig({
            refundPeriodSeconds: _preLiquidSaleConfig.refundPeriodSeconds,
            vestingDurationSeconds: _preLiquidSaleConfig.vestingDurationSeconds,
            vestingCliffDurationSeconds: _preLiquidSaleConfig.vestingCliffDurationSeconds,
            tokenAllocationOnTGEBps: _preLiquidSaleConfig.tokenAllocationOnTGEBps,
            legionFeeOnCapitalRaisedBps: _preLiquidSaleConfig.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _preLiquidSaleConfig.legionFeeOnTokensSoldBps,
            saftMerkleRoot: _preLiquidSaleConfig.saftMerkleRoot,
            bidToken: _preLiquidSaleConfig.bidToken,
            projectAdmin: _preLiquidSaleConfig.projectAdmin,
            addressRegistry: _preLiquidSaleConfig.addressRegistry
        });
    }

    /**
     * @dev Helper method to set the sealed bid auction configuration
     */
    function setSealedBidAuctionConfig(ILegionSealedBidAuction.SealedBidAuctionConfig memory _sealedBidAuctionConfig)
        public
    {
        sealedBidAuctionConfig = ILegionSealedBidAuction.SealedBidAuctionConfig({
            salePeriodSeconds: _sealedBidAuctionConfig.salePeriodSeconds,
            refundPeriodSeconds: _sealedBidAuctionConfig.refundPeriodSeconds,
            lockupPeriodSeconds: _sealedBidAuctionConfig.lockupPeriodSeconds,
            vestingDurationSeconds: _sealedBidAuctionConfig.vestingDurationSeconds,
            vestingCliffDurationSeconds: _sealedBidAuctionConfig.vestingCliffDurationSeconds,
            legionFeeOnCapitalRaisedBps: _sealedBidAuctionConfig.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _sealedBidAuctionConfig.legionFeeOnTokensSoldBps,
            minimumPledgeAmount: _sealedBidAuctionConfig.minimumPledgeAmount,
            publicKey: _sealedBidAuctionConfig.publicKey,
            bidToken: _sealedBidAuctionConfig.bidToken,
            askToken: _sealedBidAuctionConfig.askToken,
            projectAdmin: _sealedBidAuctionConfig.projectAdmin,
            addressRegistry: _sealedBidAuctionConfig.addressRegistry
        });
    }

    /**
     * @dev Helper method to create a pre-liquid sale
     */
    function prepareCreateLegionPreLiquidSale() public {
        setPreLiquidSaleConfig(
            ILegionPreLiquidSale.PreLiquidSaleConfig({
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGEBps: TOKEN_ALLOCATION_TGE_BPS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                saftMerkleRoot: SAFT_MERKLE_ROOT,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionPreLiquidSaleInstance = legionSaleFactory.createPreLiquidSale(preLiquidSaleConfig);
    }

    /**
     * @dev Helper method to create a fixed price sale
     */
    function prepareCreateLegionFixedPriceSale() public {
        setFixedPriceSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionFixedPriceSaleInstance = legionSaleFactory.createFixedPriceSale(fixedPriceSaleConfig);
    }

    /**
     * @dev Helper method to create a sealed bid auction
     */
    function prepareCreateLegionSealedBidAuction() public {
        setSealedBidAuctionConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(sealedBidAuctionConfig);
    }

    /**
     * @dev Helper method to prepare LegionAddressRegistry
     */
    function prepareLegionAddressRegistry() public {
        vm.startPrank(legionBouncer);

        legionAddressRegistry.setLegionAddress(bytes32("LEGION_BOUNCER"), legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_SIGNER"), vm.addr(legionSignerPK));
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), legionFeeReceiver);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_VESTING_FACTORY"), address(legionVestingFactory));

        vm.stopPrank();
    }

    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @dev Test Case: Verify that the factory contract initializes correctly with the correct owner.
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public {
        // Assert
        assertEq(legionSaleFactory.owner(), legionBouncer);
    }

    /**
     * @dev Test Case: Successfully create a new LegionFixedPriceSale instance by the owner (Legion).
     */
    function test_createFixedPriceSale_successullyCreatesFixedPriceSale() public {
        // Arrange & Act
        prepareCreateLegionFixedPriceSale();

        // Assert
        assertNotEq(legionFixedPriceSaleInstance, address(0));
    }

    /**
     * @dev Test Case: Attempt to create a new LegionFixedPriceSale instance by a non-owner account
     */
    function test_createFixedPriceSale_revertsIfNotCalledByOwner() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createFixedPriceSale(fixedPriceSaleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createFixedPriceSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setFixedPriceSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(0),
                askToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(fixedPriceSaleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero value configurations
     */
    function test_createFixedPriceSale_revertsWithZeroValueProvided() public {
        // Arrange
        setFixedPriceSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: 0,
                prefundAllocationPeriodSeconds: 0,
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                vestingDurationSeconds: 0,
                vestingCliffDurationSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                minimumPledgeAmount: 0,
                tokenPrice: 0,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(fixedPriceSaleConfig);
    }

    /**
     * @dev Test Case: Ensure that LegionFixedPriceSale instance is initialized with the supplied configuration.
     */
    function test_createFixedPriceSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionFixedPriceSale();
        ILegionFixedPriceSale.FixedPriceSaleConfig memory fixedPriceSaleConfiguration =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).saleConfiguration();

        // Assert
        assertEq(fixedPriceSaleConfiguration.prefundPeriodSeconds, PREFUND_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfiguration.prefundAllocationPeriodSeconds, PREFUND_ALLOCATION_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfiguration.salePeriodSeconds, SALE_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfiguration.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfiguration.lockupPeriodSeconds, LOCKUP_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfiguration.vestingDurationSeconds, VESTING_DURATION_SECONDS);
        assertEq(fixedPriceSaleConfiguration.vestingCliffDurationSeconds, VESTING_CLIFF_DURATION_SECONDS);
        assertEq(fixedPriceSaleConfiguration.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(fixedPriceSaleConfiguration.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);
        assertEq(fixedPriceSaleConfiguration.tokenPrice, TOKEN_PRICE);
        assertEq(fixedPriceSaleConfiguration.bidToken, address(bidToken));
        assertEq(fixedPriceSaleConfiguration.askToken, address(askToken));
        assertEq(fixedPriceSaleConfiguration.projectAdmin, projectAdmin);
        assertEq(fixedPriceSaleConfiguration.addressRegistry, address(legionAddressRegistry));
    }

    /**
     * @dev Test Case: Successfully create a new LegionPreLiquidSale instance by the owner (Legion).
     */
    function test_createPreLiquidSale_successullyCreatesPreLiquidSale() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        // Assert
        assertNotEq(legionPreLiquidSaleInstance, address(0));
    }

    /**
     * @dev Test Case: Attempt to create a new LegionPreLiquidSale instance by a non-owner account
     */
    function test_createPreLiquidSale_revertsIfNotCalledByOwner() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createPreLiquidSale(preLiquidSaleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setPreLiquidSaleConfig(
            ILegionPreLiquidSale.PreLiquidSaleConfig({
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGEBps: TOKEN_ALLOCATION_TGE_BPS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                saftMerkleRoot: SAFT_MERKLE_ROOT,
                bidToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSale(preLiquidSaleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero value configurations
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setPreLiquidSaleConfig(
            ILegionPreLiquidSale.PreLiquidSaleConfig({
                refundPeriodSeconds: 0,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGEBps: TOKEN_ALLOCATION_TGE_BPS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                saftMerkleRoot: 0,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSale(preLiquidSaleConfig);
    }

    /**
     * @dev Test Case: Ensure that LegionPreLiquidSale instance is initialized with the supplied configuration.
     */
    function test_createPreLiquidSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();
        ILegionPreLiquidSale.PreLiquidSaleConfig memory saleConfig =
            LegionPreLiquidSale(payable(legionPreLiquidSaleInstance)).saleConfig();
        ILegionPreLiquidSale.PreLiquidSaleStatus memory saleStatus =
            LegionPreLiquidSale(payable(legionPreLiquidSaleInstance)).saleStatus();

        // Assert
        assertEq(saleConfig.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(saleConfig.vestingDurationSeconds, VESTING_DURATION_SECONDS);
        assertEq(saleConfig.vestingCliffDurationSeconds, VESTING_CLIFF_DURATION_SECONDS);
        assertEq(saleConfig.tokenAllocationOnTGEBps, TOKEN_ALLOCATION_TGE_BPS);
        assertEq(saleConfig.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(saleConfig.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);
        assertEq(saleConfig.saftMerkleRoot, SAFT_MERKLE_ROOT);
        assertEq(saleConfig.bidToken, address(bidToken));
        assertEq(saleConfig.projectAdmin, projectAdmin);
        assertEq(saleConfig.addressRegistry, address(legionAddressRegistry));

        assertEq(saleStatus.askToken, address(0));
        assertEq(saleStatus.vestingStartTime, 0);
        assertEq(saleStatus.askTokenTotalSupply, 0);
        assertEq(saleStatus.totalCapitalInvested, 0);
        assertEq(saleStatus.totalTokensAllocated, 0);
        assertEq(saleStatus.totalCapitalWithdrawn, 0);
        assertEq(saleStatus.isCanceled, false);
    }

    /**
     * @dev Test Case: Successfully create a new LegionSealedBidAuction instance by the owner (Legion).
     */
    function test_createSealedBidAuction_successullyCreatesSealedBidAuction() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();

        // Assert
        assertNotEq(legionSealedBidAuctionInstance, address(0));
    }

    /**
     * @dev Test Case: Attempt to create a new LegionSealedBidAuction instance by a non-owner account
     */
    function test_createSealedBidAuction_revertsIfNotCalledByOwner() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createSealedBidAuction(sealedBidAuctionConfig);
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createSealedBidAuction_revertsWithZeroAddressProvided() public {
        // Arrange
        setSealedBidAuctionConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(0),
                askToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(sealedBidAuctionConfig);
    }

    /**
     * @dev Test Case: Initialize with zero value configurations
     */
    function test_createSealedBidAuction_revertsWithZeroValueProvided() public {
        // Arrange
        setSealedBidAuctionConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                vestingDurationSeconds: 0,
                vestingCliffDurationSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                minimumPledgeAmount: 0,
                publicKey: Point(0, 0),
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(sealedBidAuctionConfig);
    }

    /**
     * @dev Test Case: Ensure that LegionSealedBidAuction instance is initialized with the supplied configuration.
     */
    function test_createSealedBidAuction_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();
        ILegionSealedBidAuction.SealedBidAuctionConfig memory sealedBidAuctionConfiguration =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).saleConfiguration();

        // Assert
        assertEq(sealedBidAuctionConfiguration.salePeriodSeconds, SALE_PERIOD_SECONDS);
        assertEq(sealedBidAuctionConfiguration.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(sealedBidAuctionConfiguration.lockupPeriodSeconds, LOCKUP_PERIOD_SECONDS);
        assertEq(sealedBidAuctionConfiguration.vestingDurationSeconds, VESTING_DURATION_SECONDS);
        assertEq(sealedBidAuctionConfiguration.vestingCliffDurationSeconds, VESTING_CLIFF_DURATION_SECONDS);
        assertEq(sealedBidAuctionConfiguration.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(sealedBidAuctionConfiguration.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);

        assertEq(sealedBidAuctionConfiguration.bidToken, address(bidToken));
        assertEq(sealedBidAuctionConfiguration.askToken, address(askToken));
        assertEq(sealedBidAuctionConfiguration.projectAdmin, projectAdmin);
        assertEq(sealedBidAuctionConfiguration.addressRegistry, address(legionAddressRegistry));
    }
}
