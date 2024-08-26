// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console2, Vm} from "forge-std/Test.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ILegionPreLiquidSale} from "../src/interfaces/ILegionPreLiquidSale.sol";
import {ILegionSaleFactory} from "../src/interfaces/ILegionSaleFactory.sol";
import {LegionAccessControl} from "../src/LegionAccessControl.sol";
import {LegionPreLiquidSale} from "../src/LegionPreLiquidSale.sol";
import {LegionSaleFactory} from "../src/LegionSaleFactory.sol";
import {LegionVestingFactory} from "../src/LegionVestingFactory.sol";
import {MockToken} from "../src/mocks/MockToken.sol";

contract LegionPreLiquidSaleTest is Test {
    ILegionPreLiquidSale.PreLiquidSaleConfig public preLiquidSaleConfig;

    LegionPreLiquidSale public preLiquidSaleTemplate;
    LegionSaleFactory public legionSaleFactory;
    LegionVestingFactory public legionVestingFactory;

    MockToken public bidToken;
    MockToken public askToken;

    address public legionPreLiquidSaleInstance;
    address awsBroadcaster = address(0x10);
    address legionEOA = address(0x01);
    address legionAdmin = address(new LegionAccessControl(legionEOA, awsBroadcaster));
    address projectAdmin = address(0x02);

    address investor1 = address(0x03);
    address investor2 = address(0x04);
    address investor3 = address(0x05);
    address investor4 = address(0x06);
    address investor5 = address(0x07);

    address nonLegionAdmin = address(0x08);
    address nonProjectAdmin = address(0x09);

    address nonOwner = address(0x03);

    uint256 constant REFUND_PERIOD_SECONDS = 1209600;
    uint256 constant VESTING_DURATION_SECONDS = 31536000;
    uint256 constant VESTING_CLIFF_DURATION_SECONDS = 3600;
    uint256 constant TOKEN_ALLOCATION_TGE_BPS = 1000;
    uint256 constant LEGION_FEE_CAPITAL_RAISED_BPS = 250;
    uint256 constant LEGION_FEE_TOKENS_SOLD_BPS = 250;
    bytes32 constant SAFT_MERKLE_ROOT = 0xb1f74233838c8077babb1c1e9ca12a76f0ec395a7a2e2501aea9c95f06a6e368;
    bytes32 constant SAFT_MERKLE_ROOT_UPDATED = 0xb4345742554431ccf97adcdb0c09485d9d7103483a40e50ff40cc76e7257e240;

    uint256 constant TWO_WEEKS = 1209600;

    address[] investedAddresses = [investor1];
    address[] investedAddresses2 = [investor2];

    function setUp() public {
        preLiquidSaleTemplate = new LegionPreLiquidSale();
        legionSaleFactory = new LegionSaleFactory(legionAdmin);
        legionVestingFactory = new LegionVestingFactory();
        bidToken = new MockToken("USD Coin", "USDC");
        askToken = new MockToken("LFG Coin", "LFG");
    }

    /**
     * @dev Helper method to set the pre-liquid sale configuration
     */
    function setSaleConfig(ILegionPreLiquidSale.PreLiquidSaleConfig memory _preLiquidSaleConfig) public {
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
     * @dev Helper method to create a pre-liquid sale
     */
    function prepareCreateLegionPreLiquidSale() public {
        setSaleConfig(
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
     * @dev Helper method to mint tokens to investors and approve the sale instance contract
     */
    function prepareMintAndApproveTokens() public {
        vm.startPrank(legionAdmin);

        MockToken(bidToken).mint(investor1, 100000 * 1e18);
        MockToken(bidToken).mint(investor2, 100000 * 1e18);
        MockToken(bidToken).mint(investor3, 100000 * 1e18);
        MockToken(bidToken).mint(investor4, 100000 * 1e18);

        vm.stopPrank();

        vm.prank(investor1);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 100000 * 1e18);

        vm.prank(investor2);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 100000 * 1e18);

        vm.prank(investor3);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 100000 * 1e18);

        vm.prank(investor4);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 100000 * 1e18);

        vm.startPrank(projectAdmin);

        MockToken(askToken).mint(projectAdmin, 1000000 * 1e18);
        MockToken(bidToken).mint(projectAdmin, 1000000 * 1e18);

        MockToken(askToken).approve(legionPreLiquidSaleInstance, 1000000 * 1e18);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 1000000 * 1e18);

        vm.stopPrank();
    }

    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @dev Test Case: Successfully initialize the contract with valid parameters.
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
     * @dev Test Case: Attempt to re-initialize the contract
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert();

        // Act
        LegionPreLiquidSale(payable(legionPreLiquidSaleInstance)).initialize(preLiquidSaleConfig);
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionPreLiquidSale` implementation contract
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        setSaleConfig(
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

        address preLiquidSaleImplementation = legionSaleFactory.preLiquidSaleTemplate();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSale(payable(preLiquidSaleImplementation)).initialize(preLiquidSaleConfig);
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionPreLiquidSale` template contract
     */
    function test_initialize_revertInitializeTemplate() public {
        // Arrange
        setSaleConfig(
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSale(preLiquidSaleTemplate).initialize(preLiquidSaleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleConfig(
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
        setSaleConfig(
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
     * @dev Test Case: Initialize with invalid period configurations
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfig() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSale.PreLiquidSaleConfig({
                refundPeriodSeconds: REFUND_PERIOD_SECONDS + 1,
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionAdmin);
        legionSaleFactory.createPreLiquidSale(preLiquidSaleConfig);
    }

    /* ========== INVEST TESTS ========== */

    /**
     * @dev Test Case: Successfully invest capital.
     */
    function test_invest_successfullyEmitsCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.CapitalInvested(
            10000 * 1e18, investor1, 50, 0x0000000000000000000000000000000000000000000000000000000000000003, 1
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );
    }

    /**
     * @dev Test Case: Attempt to invest after the sale has been canceled
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );
    }

    /**
     * @dev Test Case: Attempt to invest more than the allowed amount
     */
    function test_invest_revertsIfInvestingMoreThanAllowed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotAllowedToInvestCapital.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            11000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );
    }

    /**
     * @dev Test Case: Attempt to invest by an investor, not part of the SAFT whitelist.
     */
    function test_invest_revertsIfInvestorNotInSAFTWhitelist() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotAllowedToInvestCapital.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );
    }

    /**
     * @dev Test Case: Attempt to invest if `investmentAccepted` is set to false
     */
    function test_invest_revertsIfNotAcceptingInvestment() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).toggleInvestmentAccepted();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.InvestmentNotAccepted.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );
    }

    /* ========== REFUND TESTS ========== */

    /**
     * @dev Test Case: Successfully get a refund before the refund period is over.
     */
    function test_refund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(1 + 1 days);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.CapitalRefunded(10000 * 1e18, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @dev Test Case: Attempt to get a refund when the sale has been canceled.
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @dev Test Case: Attempt to get a refund when the refund period is over.
     */
    function test_refund_revertsIfRefundPeriodForInvestorIsOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.RefundPeriodIsOver.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @dev Test Case: Attempt to get a refund if there is nothing to refund.
     */
    function test_refund_revertsIfInvestorHasNoCapitalToRefund() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 3600);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).refund();

        vm.warp(block.timestamp + 7200);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.InvalidRefundAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).refund();
    }

    /* ========== CANCEL SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully cancel a sale by the Project, when there's no capital to return.
     */
    function test_cancelSale_successfullyEmitsSaleCanceledWithNoCapitalToReturn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(1 + 1 days);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @dev Test Case: Successfully cancel a sale by the Project, when there's capital to return.
     */
    function test_cancelSale_successfullyEmitsSaleCanceledWithCapitalToReturn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 2 days);

        vm.prank(projectAdmin);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 10000 * 1e18);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel a sale if it has already been canceled.
     */
    function test_cancelSale_revertsIfSaleIsAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(1 + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel a sale by a non-admin.
     */
    function test_cancelSale_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(1 + 1 days);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotCalledByProjectAdmin.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();
    }

    /* ========== PUBLISH TGE DETAILS TESTS ========== */

    /**
     * @dev Test Case: Successfully publish TGE details by Legion.
     */
    function test_publishTgeDetails_successfullyEmitsTgeDetailsPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.TgeDetailsPublished(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        // Act
        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );
    }

    /**
     * @dev Test Case: Attempt to publish TGE details when the sale is canceled.
     */
    function test_publishTgeDetails_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );
    }

    /**
     * @dev Test Case: Attempt to publish TGE details by a Non-Legion admin.
     */
    function test_publishTgeDetails_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotCalledByLegionAdmin.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );
    }

    /**
     * @dev Test Case: Attempt to publish TGE details with invalid totalSupply.
     */
    function test_publishTgeDetails_revertsIfInvalidTotalSupplyProvided() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.InvalidTotalSupply.selector));

        // Act
        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 100000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );
    }

    /* ========== SUPPLY ASK TOKENS TESTS ========== */

    /**
     * @dev Test Case: Successfully supply tokens for distribution by the Project admin.
     */
    function test_supplyAskTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.TokensSuppliedForDistribution(20000 * 1e18, 500 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if the sale is canceled.
     */
    function test_supplyAskTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if tokens have already been supplied.
     */
    function test_supplyAskTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if tokens are not allocated by Legion.
     */
    function test_supplyAskTokens_revertsIfTokensNotAllocated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply incorrect amount of tokens.
     */
    function test_supplyAskTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.InvalidTokenAmountSupplied.selector, 19000 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(19000 * 1e18, 500 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply incorrect amount of tokens.
     */
    function test_supplyAskTokens_revertsIfIncorrectLegionFeeAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 499 * 1e18);
    }

    /* ========== EMERGENCY WITHDRAW TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw funds through emergencyWithdraw method.
     */
    function test_emergencyWithdraw_successfullyWithdrawByLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.EmergencyWithdraw(legionAdmin, address(bidToken), 1000 * 1e18);

        // Act
        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).emergencyWithdraw(legionAdmin, address(bidToken), 1000 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to withdraw by address other than the Legion admin.
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(block.timestamp + 1);

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotCalledByLegionAdmin.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).emergencyWithdraw(
            projectAdmin, address(bidToken), 1000 * 1e18
        );
    }

    /* ========== WITHDRAW RAISED CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw capital from the sale by the Project.
     */
    function test_withdrawRaisedCapital_successfullyEmitsCapitalWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.CapitalWithdrawn(10000 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);
    }

    /**
     * @dev Test Case: Attempt to withdraw from a position from which capital has already been withdrawn.
     */
    function test_withdrawRaisedCapital_revertsIfPositionHasAlreadyBeenWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.CapitalAlreadyWithdrawn.selector, investor1));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);
    }

    /**
     * @dev Test Case: Attempt to withdraw from a position which has not invested capital.
     */
    function test_withdrawRaisedCapital_revertsIfPositionHasNotInvestedCapital() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.CapitalNotInvested.selector, investor2));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses2);
    }

    /**
     * @dev Test Case: Attempt to withdraw capital from the sale by a non-project admin.
     */
    function test_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotCalledByProjectAdmin.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);
    }

    /**
     * @dev Test Case: Attempt to withdraw capital from the sale if the sale is canceled.
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);
    }

    /**
     * @dev Test Case: Attempt to withdraw capital from investor if the refund period is not over.
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodForInvestorIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);
    }

    /* ========== WITHDRAW CAPITAL IF SALE IS CANCELED TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw capital by investor, after the sale has been canceled.
     */
    function test_withdrawCapitalIfSaleIsCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.CapitalRefundedAfterCancel(10000 * 1e18, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawCapitalIfSaleIsCanceled();
    }

    /**
     * @dev Test Case: Attempt to withdraw capital if the sale is not canceled.
     */
    function test_withdrawCapitalIfSaleIsCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawCapitalIfSaleIsCanceled();
    }

    /**
     * @dev Test Case: Attempt to withdraw by investor, with no capital invested.
     */
    function test_withdrawCapitalIfSaleIsCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.InvalidClaimAmount.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawCapitalIfSaleIsCanceled();
    }

    /* ========== UPDATE SAFT MERKLE ROOT TESTS ========== */

    /**
     * @dev Test Case: Successfully update SAFT merkle root by Project admin.
     */
    function test_updateSAFTMerkleRoot_successfullyEmitsSAFTMerkleRootUpdated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.SAFTMerkleRootUpdated(SAFT_MERKLE_ROOT_UPDATED);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateSAFTMerkleRoot(SAFT_MERKLE_ROOT_UPDATED);
    }

    /**
     * @dev Test Case: Attempt to update SAFT merkle root by non project admin.
     */
    function test_updateSAFTMerkleRoot_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(block.timestamp + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotCalledByProjectAdmin.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateSAFTMerkleRoot(SAFT_MERKLE_ROOT_UPDATED);
    }

    /**
     * @dev Test Case: Attempt to update SAFT merkle root when the sale is canceled.
     */
    function test_updateSAFTMerkleRoot_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateSAFTMerkleRoot(SAFT_MERKLE_ROOT_UPDATED);
    }

    /**
     * @dev Test Case: Attempt to update SAFT merkle root when the project has withdrawn capital.
     */
    function test_updateSAFTMerkleRoot_revertsIfCapitalHasBeenWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.ProjectHasWithdrawnCapital.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateSAFTMerkleRoot(SAFT_MERKLE_ROOT_UPDATED);
    }

    /* ========== WITHDRAW EXCESS CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw excess capital after SAFT has been updated.
     */
    function test_withdrawExcessCapital_successfullyEmitsExcessCapitalWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateSAFTMerkleRoot(SAFT_MERKLE_ROOT_UPDATED);

        bytes32[] memory saftInvestProofInvestor1Updated = new bytes32[](2);

        saftInvestProofInvestor1Updated[0] = bytes32(0xaf325546cc30a71479fc43db2eac83f81ef4b7a1292b8d5971cd7ac9173278f6);
        saftInvestProofInvestor1Updated[1] = bytes32(0xb228cd64aa129d34d329c6d163763ebe0af9cb1cda3ea7b4c02aac3d75cd171b);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.ExcessCapitalWithdrawn(
            1000 * 1e18,
            investor1,
            40,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            (block.timestamp)
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawExcessCapital(
            1000 * 1e18,
            9000 * 1e18,
            40,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            saftInvestProofInvestor1Updated
        );
    }

    /**
     * @dev Test Case: Attempt to withdraw excess capital after SAFT has been updated, but sale has been canceled.
     */
    function test_withdrawExcessCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateSAFTMerkleRoot(SAFT_MERKLE_ROOT_UPDATED);

        bytes32[] memory saftInvestProofInvestor1Updated = new bytes32[](2);

        saftInvestProofInvestor1Updated[0] = bytes32(0xaf325546cc30a71479fc43db2eac83f81ef4b7a1292b8d5971cd7ac9173278f6);
        saftInvestProofInvestor1Updated[1] = bytes32(0xb228cd64aa129d34d329c6d163763ebe0af9cb1cda3ea7b4c02aac3d75cd171b);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawExcessCapital(
            1000 * 1e18,
            9000 * 1e18,
            40,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            saftInvestProofInvestor1Updated
        );
    }

    /**
     * @dev Test Case: Attempt to withdraw more excess capital after SAFT has been updated.
     */
    function test_withdrawExcessCapital_revertsIfTryToWithdrawMoreThanExcess() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateSAFTMerkleRoot(SAFT_MERKLE_ROOT_UPDATED);

        bytes32[] memory saftInvestProofInvestor1Updated = new bytes32[](2);

        saftInvestProofInvestor1Updated[0] = bytes32(0xaf325546cc30a71479fc43db2eac83f81ef4b7a1292b8d5971cd7ac9173278f6);
        saftInvestProofInvestor1Updated[1] = bytes32(0xb228cd64aa129d34d329c6d163763ebe0af9cb1cda3ea7b4c02aac3d75cd171b);

        // Assert
        vm.expectRevert(
            abi.encodeWithSelector(ILegionPreLiquidSale.NotAllowedToWithdrawExcessCapital.selector, investor1)
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawExcessCapital(
            2000 * 1e18,
            9000 * 1e18,
            40,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            saftInvestProofInvestor1Updated
        );
    }

    /**
     * @dev Test Case: Attempt to withdraw excess capital after SAFT has been updated with invalid proof data.
     */
    function test_withdrawExcessCapital_revertsIfInvalidProofData() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateSAFTMerkleRoot(SAFT_MERKLE_ROOT_UPDATED);

        bytes32[] memory saftInvestProofInvestor1Updated = new bytes32[](2);

        saftInvestProofInvestor1Updated[0] = bytes32(0xaf325546cc30a71479fc43db2eac83f81ef4b7a1292b8d5971cd7ac9173278f6);
        saftInvestProofInvestor1Updated[1] = bytes32(0xb228cd64aa129d34d329c6d163763ebe0af9cb1cda3ea7b4c02aac3d75cd171b);

        // Assert
        vm.expectRevert(
            abi.encodeWithSelector(ILegionPreLiquidSale.NotAllowedToWithdrawExcessCapital.selector, investor1)
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawExcessCapital(
            1000 * 1e18,
            9000 * 1e18,
            100,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            saftInvestProofInvestor1Updated
        );
    }

    /* ========== UPDATE VESTING TERMS TESTS ========== */

    /**
     * @dev Test Case: Successfully update vesting terms by the Project.
     */
    function test_updateVestingTerms_successfullyEmitVestingTermsUpdated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.VestingTermsUpdated(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_BPS + 10)
        );

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_BPS + 10)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms if the sale is canceled.
     */
    function test_updateVestingTerms_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_BPS + 10)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms by non-project admin.
     */
    function test_updateVestingTerms_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotCalledByProjectAdmin.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_BPS + 10)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms if tokens are already allocated.
     */
    function test_updateVestingTerms_revertsIfTokensAreAlreadyAllocated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.TokensAlreadyAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_BPS + 10)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms after the project has withdrawn capital.
     */
    function test_updateVestingTerms_revertsIfCapitalHasBeenWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).withdrawRaisedCapital(investedAddresses);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.ProjectHasWithdrawnCapital.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_BPS + 10)
        );
    }

    /* ========== CLAIM ASK TOKENS ALLOCATION TESTS ========== */

    /**
     * @dev Test Case: Successfully claim allocated tokens by investors.
     */
    function test_claimAskTokenAllocation_successfullyEmitsTokenAllocationClaimed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).claimAskTokenAllocation();

        (,,,,,, bool hasSettled, address vestingAddress) =
            LegionPreLiquidSale(payable(legionPreLiquidSaleInstance)).investorPositions(investor1);

        assertEq(hasSettled, true);
        assertEq(MockToken(askToken).balanceOf(vestingAddress), 4500 * 1e18);
        assertEq(MockToken(askToken).balanceOf(investor1), 500 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to claim token allocation if investor has not invested capital.
     */
    function test_claimAskTokenAllocation_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.CapitalNotInvested.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).claimAskTokenAllocation();
    }

    /**
     * @dev Test Case: Attempt to claim token allocation if the askToken has not been supplied.
     */
    function test_claimAskTokenAllocation_revertsIfAskTokenNotSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.AskTokensNotSupplied.selector));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).claimAskTokenAllocation();
    }

    /**
     * @dev Test Case: Attempt to claim token allocation if investor has already claimed.
     */
    function test_claimAskTokenAllocation_revertsIfPositionAlreadySettled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).claimAskTokenAllocation();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.AlreadySettled.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).claimAskTokenAllocation();
    }

    /* ========== RELEASE TOKENS TESTS ========== */

    /**
     * @dev Test Case: Successfully release tokens from investor vesting contract after vesting distribution.
     */
    function test_releaseTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).claimAskTokenAllocation();

        vm.warp(block.timestamp + TWO_WEEKS + VESTING_CLIFF_DURATION_SECONDS + 3600);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).releaseTokens();

        // Assert
        assertEq(MockToken(askToken).balanceOf(investor1), 501027111872146118721);
    }

    /**
     * @dev Test Case: Attempt to release tokens if an investor does not have deployed vesting contract
     */
    function test_releaseTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        bytes32[] memory saftInvestProofInvestor1 = new bytes32[](2);

        saftInvestProofInvestor1[0] = bytes32(0x7781c5053112c59523cd5ad10f3848f06c4ec03dc830e1d06fe74a9db2c7921c);
        saftInvestProofInvestor1[1] = bytes32(0xadb7b49d77e80d6ec12e1b1444c186e8f23587767a7fa5461396f08b2562dafe);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).invest(
            10000 * 1e18,
            10000 * 1e18,
            50,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            saftInvestProofInvestor1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).supplyAskTokens(20000 * 1e18, 500 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).releaseTokens();
    }

    /* ========== TOGGLE INVESTMENT ACCEPTED TESTS ========== */

    /**
     * @dev Test Case: Successfully toggle `investmentAccepted` by the Project
     */
    function test_toggleInvestmentAccepted_successfullyEmitsToggleInvestmentAccepted() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSale.ToggleInvestmentAccepted(false);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).toggleInvestmentAccepted();
    }

    /**
     * @dev Test Case: Attempt to toggle `investmentAccepted` by non-Project admin
     */
    function test_toggleInvestmentAccepted_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.NotCalledByProjectAdmin.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).toggleInvestmentAccepted();
    }

    /**
     * @dev Test Case: Attempt to toggle `investmentAccepted` when tokens have been already allocated
     */
    function test_toggleInvestmentAccepted_revertsIfTokensAllocated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1000000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionPreLiquidSale.TokensAlreadyAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSale(legionPreLiquidSaleInstance).toggleInvestmentAccepted();
    }
}
