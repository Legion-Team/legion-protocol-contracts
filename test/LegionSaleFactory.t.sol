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
import {LegionFixedPriceSale} from "../src/LegionFixedPriceSale.sol";
import {LegionPreLiquidSale} from "../src/LegionPreLiquidSale.sol";
import {LegionSealedBidAuction} from "../src/LegionSealedBidAuction.sol";
import {LegionSaleFactory} from "../src/LegionSaleFactory.sol";
import {LegionVestingFactory} from "../src/LegionVestingFactory.sol";
import {MockToken} from "../src/mocks/MockToken.sol";

contract LegionSaleFactoryTest is Test {
    ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig public fixedPriceSalePeriodAndFeeConfig;
    ILegionFixedPriceSale.FixedPriceSaleAddressConfig public fixedPriceSaleAddressConfig;

    ILegionPreLiquidSale.PreLiquidSaleConfig public preLiquidSaleConfig;

    ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig public sealedBidAuctionPeriodAndFeeConfig;
    ILegionSealedBidAuction.SealedBidAuctionAddressConfig public sealedBidAuctionAddressConfig;

    LegionSaleFactory public legionSaleFactory;
    LegionVestingFactory public legionVestingFactory;

    MockToken public bidToken;
    MockToken public askToken;

    address public legionFixedPriceSaleInstance;
    address public legionPreLiquidSaleInstance;
    address public legionSealedBidAuctionInstance;

    address legionAdmin = address(0x01);
    address projectAdmin = address(0x02);
    address nonOwner = address(0x03);

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
        legionSaleFactory = new LegionSaleFactory(legionAdmin);
        legionVestingFactory = new LegionVestingFactory();
        bidToken = new MockToken("USD Coin", "USDC");
        askToken = new MockToken("LFG Coin", "LFG");
    }

    /**
     * @dev Helper method to set the fixed price sale configuration
     */
    function setFixedPriceSaleConfig(
        ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig memory _fixedPriceSalePeriodAndFeeConfig,
        ILegionFixedPriceSale.FixedPriceSaleAddressConfig memory _fixedPriceSaleAddressConfig
    ) public {
        fixedPriceSalePeriodAndFeeConfig = ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig({
            prefundPeriodSeconds: _fixedPriceSalePeriodAndFeeConfig.prefundPeriodSeconds,
            prefundAllocationPeriodSeconds: _fixedPriceSalePeriodAndFeeConfig.prefundAllocationPeriodSeconds,
            salePeriodSeconds: _fixedPriceSalePeriodAndFeeConfig.salePeriodSeconds,
            refundPeriodSeconds: _fixedPriceSalePeriodAndFeeConfig.refundPeriodSeconds,
            lockupPeriodSeconds: _fixedPriceSalePeriodAndFeeConfig.lockupPeriodSeconds,
            vestingDurationSeconds: _fixedPriceSalePeriodAndFeeConfig.vestingDurationSeconds,
            vestingCliffDurationSeconds: _fixedPriceSalePeriodAndFeeConfig.vestingCliffDurationSeconds,
            legionFeeOnCapitalRaisedBps: _fixedPriceSalePeriodAndFeeConfig.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _fixedPriceSalePeriodAndFeeConfig.legionFeeOnTokensSoldBps,
            minimumPledgeAmount: _fixedPriceSalePeriodAndFeeConfig.minimumPledgeAmount,
            tokenPrice: _fixedPriceSalePeriodAndFeeConfig.tokenPrice
        });

        fixedPriceSaleAddressConfig = ILegionFixedPriceSale.FixedPriceSaleAddressConfig({
            bidToken: _fixedPriceSaleAddressConfig.bidToken,
            askToken: _fixedPriceSaleAddressConfig.askToken,
            projectAdmin: _fixedPriceSaleAddressConfig.projectAdmin,
            legionAdmin: _fixedPriceSaleAddressConfig.legionAdmin,
            legionSigner: _fixedPriceSaleAddressConfig.legionSigner,
            vestingFactory: _fixedPriceSaleAddressConfig.vestingFactory
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
            legionAdmin: _preLiquidSaleConfig.legionAdmin,
            vestingFactory: _preLiquidSaleConfig.vestingFactory
        });
    }

    /**
     * @dev Helper method to set the sealed bid auction configuration
     */
    function setSealedBidAuctionConfig(
        ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig memory _sealedBidAuctionPeriodAndFeeConfig,
        ILegionSealedBidAuction.SealedBidAuctionAddressConfig memory _sealedBidAuctionAddressConfig
    ) public {
        sealedBidAuctionPeriodAndFeeConfig = ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig({
            salePeriodSeconds: _sealedBidAuctionPeriodAndFeeConfig.salePeriodSeconds,
            refundPeriodSeconds: _sealedBidAuctionPeriodAndFeeConfig.refundPeriodSeconds,
            lockupPeriodSeconds: _sealedBidAuctionPeriodAndFeeConfig.lockupPeriodSeconds,
            vestingDurationSeconds: _sealedBidAuctionPeriodAndFeeConfig.vestingDurationSeconds,
            vestingCliffDurationSeconds: _sealedBidAuctionPeriodAndFeeConfig.vestingCliffDurationSeconds,
            legionFeeOnCapitalRaisedBps: _sealedBidAuctionPeriodAndFeeConfig.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _sealedBidAuctionPeriodAndFeeConfig.legionFeeOnTokensSoldBps,
            minimumPledgeAmount: _sealedBidAuctionPeriodAndFeeConfig.minimumPledgeAmount,
            publicKey: _sealedBidAuctionPeriodAndFeeConfig.publicKey
        });

        sealedBidAuctionAddressConfig = ILegionSealedBidAuction.SealedBidAuctionAddressConfig({
            bidToken: _sealedBidAuctionAddressConfig.bidToken,
            askToken: _sealedBidAuctionAddressConfig.askToken,
            projectAdmin: _sealedBidAuctionAddressConfig.projectAdmin,
            legionAdmin: _sealedBidAuctionAddressConfig.legionAdmin,
            legionSigner: _sealedBidAuctionAddressConfig.legionSigner,
            vestingFactory: _sealedBidAuctionAddressConfig.vestingFactory
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
                legionAdmin: legionAdmin,
                vestingFactory: address(legionVestingFactory)
            })
        );
        vm.prank(legionAdmin);
        legionPreLiquidSaleInstance = legionSaleFactory.createPreLiquidSale(preLiquidSaleConfig);
    }

    /**
     * @dev Helper method to create a fixed price sale
     */
    function prepareCreateLegionFixedPriceSale() public {
        setFixedPriceSaleConfig(
            ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig({
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
                tokenPrice: TOKEN_PRICE
            }),
            ILegionFixedPriceSale.FixedPriceSaleAddressConfig({
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                legionAdmin: legionAdmin,
                legionSigner: vm.addr(legionSignerPK),
                vestingFactory: address(legionVestingFactory)
            })
        );
        vm.prank(legionAdmin);
        legionFixedPriceSaleInstance =
            legionSaleFactory.createFixedPriceSale(fixedPriceSalePeriodAndFeeConfig, fixedPriceSaleAddressConfig);
    }

    /**
     * @dev Helper method to create a sealed bid auction
     */
    function prepareCreateLegionSealedBidAuction() public {
        setSealedBidAuctionConfig(
            ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY
            }),
            ILegionSealedBidAuction.SealedBidAuctionAddressConfig({
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                legionAdmin: legionAdmin,
                legionSigner: vm.addr(legionSignerPK),
                vestingFactory: address(legionVestingFactory)
            })
        );
        vm.prank(legionAdmin);
        legionSealedBidAuctionInstance =
            legionSaleFactory.createSealedBidAuction(sealedBidAuctionPeriodAndFeeConfig, sealedBidAuctionAddressConfig);
    }

    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @dev Test Case: Verify that the factory contract initializes correctly with the correct owner.
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public {
        // Assert
        assertEq(legionSaleFactory.owner(), legionAdmin);
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
        legionSaleFactory.createFixedPriceSale(fixedPriceSalePeriodAndFeeConfig, fixedPriceSaleAddressConfig);
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createFixedPriceSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setFixedPriceSaleConfig(
            ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig({
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
                tokenPrice: TOKEN_PRICE
            }),
            ILegionFixedPriceSale.FixedPriceSaleAddressConfig({
                bidToken: address(0),
                askToken: address(0),
                projectAdmin: address(0),
                legionAdmin: address(0),
                legionSigner: address(0),
                vestingFactory: address(0)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionAdmin);
        legionSaleFactory.createFixedPriceSale(fixedPriceSalePeriodAndFeeConfig, fixedPriceSaleAddressConfig);
    }

    /**
     * @dev Test Case: Initialize with zero value configurations
     */
    function test_createFixedPriceSale_revertsWithZeroValueProvided() public {
        // Arrange
        setFixedPriceSaleConfig(
            ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig({
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
                tokenPrice: 0
            }),
            ILegionFixedPriceSale.FixedPriceSaleAddressConfig({
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                legionAdmin: legionAdmin,
                legionSigner: vm.addr(legionSignerPK),
                vestingFactory: address(legionVestingFactory)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroValueProvided.selector));

        // Act
        vm.prank(legionAdmin);
        legionSaleFactory.createFixedPriceSale(fixedPriceSalePeriodAndFeeConfig, fixedPriceSaleAddressConfig);
    }

    /**
     * @dev Test Case: Ensure that LegionFixedPriceSale instance is initialized with the supplied configuration.
     */
    function test_createFixedPriceSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionFixedPriceSale();
        ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig memory periodAndFeeconfig =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).salePeriodAndFeeConfiguration();

        ILegionFixedPriceSale.FixedPriceSaleAddressConfig memory addressConfig =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).saleAddressConfiguration();

        // Assert
        assertEq(periodAndFeeconfig.prefundPeriodSeconds, PREFUND_PERIOD_SECONDS);
        assertEq(periodAndFeeconfig.prefundAllocationPeriodSeconds, PREFUND_ALLOCATION_PERIOD_SECONDS);
        assertEq(periodAndFeeconfig.salePeriodSeconds, SALE_PERIOD_SECONDS);
        assertEq(periodAndFeeconfig.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(periodAndFeeconfig.lockupPeriodSeconds, LOCKUP_PERIOD_SECONDS);
        assertEq(periodAndFeeconfig.vestingDurationSeconds, VESTING_DURATION_SECONDS);
        assertEq(periodAndFeeconfig.vestingCliffDurationSeconds, VESTING_CLIFF_DURATION_SECONDS);
        assertEq(periodAndFeeconfig.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(periodAndFeeconfig.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);
        assertEq(periodAndFeeconfig.tokenPrice, TOKEN_PRICE);

        assertEq(addressConfig.bidToken, address(bidToken));
        assertEq(addressConfig.askToken, address(askToken));
        assertEq(addressConfig.projectAdmin, projectAdmin);
        assertEq(addressConfig.legionAdmin, legionAdmin);
        assertEq(addressConfig.legionSigner, vm.addr(legionSignerPK));
        assertEq(addressConfig.vestingFactory, address(legionVestingFactory));
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
                legionAdmin: address(0),
                vestingFactory: address(0)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionAdmin);
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
                legionAdmin: legionAdmin,
                vestingFactory: address(legionVestingFactory)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.ZeroValueProvided.selector));

        // Act
        vm.prank(legionAdmin);
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
        assertEq(saleConfig.legionAdmin, legionAdmin);
        assertEq(saleConfig.vestingFactory, address(legionVestingFactory));

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
        legionSaleFactory.createSealedBidAuction(sealedBidAuctionPeriodAndFeeConfig, sealedBidAuctionAddressConfig);
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createSealedBidAuction_revertsWithZeroAddressProvided() public {
        // Arrange
        setSealedBidAuctionConfig(
            ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY
            }),
            ILegionSealedBidAuction.SealedBidAuctionAddressConfig({
                bidToken: address(0),
                askToken: address(0),
                projectAdmin: address(0),
                legionAdmin: address(0),
                legionSigner: address(0),
                vestingFactory: address(0)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionAdmin);
        legionSaleFactory.createSealedBidAuction(sealedBidAuctionPeriodAndFeeConfig, sealedBidAuctionAddressConfig);
    }

    /**
     * @dev Test Case: Initialize with zero value configurations
     */
    function test_createSealedBidAuction_revertsWithZeroValueProvided() public {
        // Arrange
        setSealedBidAuctionConfig(
            ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig({
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                vestingDurationSeconds: 0,
                vestingCliffDurationSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                minimumPledgeAmount: 0,
                publicKey: Point(0, 0)
            }),
            ILegionSealedBidAuction.SealedBidAuctionAddressConfig({
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                legionAdmin: legionAdmin,
                legionSigner: vm.addr(legionSignerPK),
                vestingFactory: address(legionVestingFactory)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroValueProvided.selector));

        // Act
        vm.prank(legionAdmin);
        legionSaleFactory.createSealedBidAuction(sealedBidAuctionPeriodAndFeeConfig, sealedBidAuctionAddressConfig);
    }

    /**
     * @dev Test Case: Ensure that LegionSealedBidAuction instance is initialized with the supplied configuration.
     */
    function test_createSealedBidAuction_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();
        ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig memory periodAndFeeconfig =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).salePeriodAndFeeConfiguration();

        ILegionSealedBidAuction.SealedBidAuctionAddressConfig memory addressConfig =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).saleAddressConfiguration();

        // Assert
        assertEq(periodAndFeeconfig.salePeriodSeconds, SALE_PERIOD_SECONDS);
        assertEq(periodAndFeeconfig.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(periodAndFeeconfig.lockupPeriodSeconds, LOCKUP_PERIOD_SECONDS);
        assertEq(periodAndFeeconfig.vestingDurationSeconds, VESTING_DURATION_SECONDS);
        assertEq(periodAndFeeconfig.vestingCliffDurationSeconds, VESTING_CLIFF_DURATION_SECONDS);
        assertEq(periodAndFeeconfig.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(periodAndFeeconfig.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);

        assertEq(addressConfig.bidToken, address(bidToken));
        assertEq(addressConfig.askToken, address(askToken));
        assertEq(addressConfig.projectAdmin, projectAdmin);
        assertEq(addressConfig.legionAdmin, legionAdmin);
        assertEq(addressConfig.legionSigner, vm.addr(legionSignerPK));
        assertEq(addressConfig.vestingFactory, address(legionVestingFactory));
    }
}
