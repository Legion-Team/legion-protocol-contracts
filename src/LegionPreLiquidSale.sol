// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * ██      ███████  ██████  ██  ██████  ███    ██
 * ██      ██      ██       ██ ██    ██ ████   ██
 * ██      █████   ██   ███ ██ ██    ██ ██ ██  ██
 * ██      ██      ██    ██ ██ ██    ██ ██  ██ ██
 * ███████ ███████  ██████  ██  ██████  ██   ████
 *
 * If you find a bug, please contact security(at)legion.cc
 * We will pay a fair bounty for any issue that puts user's funds at risk.
 *
 */
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ILegionAddressRegistry} from "./interfaces/ILegionAddressRegistry.sol";
import {ILegionPreLiquidSale} from "./interfaces/ILegionPreLiquidSale.sol";
import {ILegionLinearVesting} from "./interfaces/ILegionLinearVesting.sol";
import {ILegionVestingFactory} from "./interfaces/ILegionVestingFactory.sol";

/**
 * @title Legion Pre-Liquid Sale.
 * @author Legion.
 * @notice A contract used to execute pre-liquid sales of ERC20 tokens before TGE.
 */
contract LegionPreLiquidSale is ILegionPreLiquidSale, Initializable {
    using SafeERC20 for IERC20;

    /// @dev The refund period duration in seconds.
    uint256 private refundPeriodSeconds;

    /// @dev The vesting schedule duration for the token sold in seconds.
    uint256 private vestingDurationSeconds;

    /// @dev The vesting cliff duration for the token sold in seconds.
    uint256 private vestingCliffDurationSeconds;

    /// @dev The token allocation amount released to investors after TGE in BPS (Basis Points).
    uint256 private tokenAllocationOnTGEBps;

    /// @dev Legion's fee on capital raised in BPS (Basis Points).
    uint256 private legionFeeOnCapitalRaisedBps;

    /// @dev Legion's fee on tokens sold in BPS (Basis Points).
    uint256 private legionFeeOnTokensSoldBps;

    /// @dev The merkle root for verification of token distribution amounts.
    bytes32 private saftMerkleRoot;

    /// @dev The address of the token used for raising capital.
    address private bidToken;

    /// @dev The admin address of the project raising capital.
    address private projectAdmin;

    /// @dev The address of Legion's Address Registry contract.
    address private addressRegistry;

    /// @dev The admin address of Legion.
    address private legionBouncer;

    /// @dev The address of Legion's Vesting Factory contract.
    address private vestingFactory;

    /// @dev The address of the token being sold to investors.
    address private askToken;

    /// @dev The unix timestamp (seconds) of the block when the vesting starts.
    uint256 private vestingStartTime;

    /// @dev The total supply of the ask token
    uint256 private askTokenTotalSupply;

    /// @dev The total capital invested by investors.
    uint256 private totalCapitalInvested;

    /// @dev The total amount of tokens allocated to investors.
    uint256 private totalTokensAllocated;

    /// @dev The total capital withdrawn by the Project, from the sale.
    uint256 private totalCapitalWithdrawn;

    /// @dev Whether the sale has been canceled or not.
    bool internal isCanceled;

    /// @dev Whether the ask tokens have been supplied to the sale.
    bool internal askTokensSupplied;

    /// @dev Whether investment is being accepted by the Project.
    bool internal investmentAccepted;

    /// @dev Mapping of investor address to investor position.
    mapping(address investorAddress => InvestorPosition investorPosition) public investorPositions;

    /// @dev Constant representing 2 weeks in seconds.
    uint256 private constant TWO_WEEKS = 1209600;

    /// @dev Constant representing the LEGION_BOUNCER unique ID
    bytes32 internal constant LEGION_BOUNCER_ID = bytes32("LEGION_BOUNCER");

    /// @dev Constant representing the LEGION_VESTING_FACTORY unique ID
    bytes32 internal constant LEGION_VESTING_FACTORY_ID = bytes32("LEGION_VESTING_FACTORY");

    /**
     * @notice Throws if called by any account other than Legion.
     */
    modifier onlyLegion() {
        if (msg.sender != legionBouncer) revert NotCalledByLegion();
        _;
    }

    /**
     * @notice Throws if called by any account other than the Project.
     */
    modifier onlyProject() {
        if (msg.sender != projectAdmin) revert NotCalledByProject();
        _;
    }

    /**
     * @notice LegionPreLiquidSale constructor.
     */
    constructor() {
        /// Disable initialization
        _disableInitializers();
    }

    /**
     * @notice See {ILegionPreLiquidSale-initialize}.
     */
    function initialize(PreLiquidSaleConfig calldata preLiquidSaleConfig) external initializer {
        /// Initialize pre-liquid sale configuration
        refundPeriodSeconds = preLiquidSaleConfig.refundPeriodSeconds;
        vestingDurationSeconds = preLiquidSaleConfig.vestingDurationSeconds;
        vestingCliffDurationSeconds = preLiquidSaleConfig.vestingCliffDurationSeconds;
        tokenAllocationOnTGEBps = preLiquidSaleConfig.tokenAllocationOnTGEBps;
        legionFeeOnCapitalRaisedBps = preLiquidSaleConfig.legionFeeOnCapitalRaisedBps;
        legionFeeOnTokensSoldBps = preLiquidSaleConfig.legionFeeOnTokensSoldBps;
        saftMerkleRoot = preLiquidSaleConfig.saftMerkleRoot;
        bidToken = preLiquidSaleConfig.bidToken;
        projectAdmin = preLiquidSaleConfig.projectAdmin;
        addressRegistry = preLiquidSaleConfig.addressRegistry;

        /// Cache Legion addresses from `LegionAddressRegistry`
        legionBouncer = ILegionAddressRegistry(addressRegistry).getLegionAddress(LEGION_BOUNCER_ID);
        vestingFactory = ILegionAddressRegistry(addressRegistry).getLegionAddress(LEGION_VESTING_FACTORY_ID);

        /// Accepting investment is set to true by default
        investmentAccepted = true;

        /// Verify if the sale configuration is valid
        _verifyValidConfig(preLiquidSaleConfig);
    }

    /**
     * @notice See {ILegionPreLiquidSale-invest}.
     */
    function invest(
        uint256 amount,
        uint256 saftInvestAmount,
        uint256 tokenAllocationBps,
        bytes32 saftHash,
        bytes32[] calldata proof
    ) external {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that investment is accepted by the Project
        _verifyInvestmentAccepted();

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Increment total capital invested from investors
        totalCapitalInvested += amount;

        /// Increment total capital for the investor
        position.investedCapital += amount;

        // Cache the capital invest timestamp
        if (position.cachedInvestTimestamp == 0) {
            position.cachedInvestTimestamp = block.timestamp;
        }

        /// Cache the SAFT amount the investor is allowed to invest
        if (position.cachedSAFTInvestAmount != saftInvestAmount) {
            position.cachedSAFTInvestAmount = saftInvestAmount;
        }

        /// Cache the token allocation in BPS
        if (position.cachedTokenAllocationBps != tokenAllocationBps) {
            position.cachedTokenAllocationBps = tokenAllocationBps;
        }

        /// Cache the hash of the SAFT signed by the investor
        if (position.cachedSAFTHash != saftHash) {
            position.cachedSAFTHash = saftHash;
        }

        /// Verify that the user can invest capital
        _verifyCanInvestCapital(msg.sender, proof);

        /// Emit successfully CapitalInvested
        emit CapitalInvested(amount, msg.sender, tokenAllocationBps, saftHash, block.timestamp);

        /// Transfer the invested capital to the contract
        IERC20(bidToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice See {ILegionPreLiquidSale-refund}.
     */
    function refund() external {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the investor can get a refund
        _verifyRefundPeriodIsNotOver(msg.sender);

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Cache the amount to refund in memory
        uint256 amountToRefund = position.investedCapital;

        /// Revert in case there's nothing to refund
        if (amountToRefund == 0) revert InvalidRefundAmount();

        /// Set the total invested capital for the investor to 0
        position.investedCapital = 0;

        /// Decrement total capital invested from investors
        totalCapitalInvested -= amountToRefund;

        /// Emit successfully CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender);

        /// Transfer the refunded amount back to the investor
        IERC20(bidToken).safeTransfer(msg.sender, amountToRefund);
    }

    /**
     * @notice See {ILegionPreLiquidSale-setTokenDetails}.
     */
    function publishTgeDetails(
        address _askToken,
        uint256 _askTokenTotalSupply,
        uint256 _vestingStartTime,
        uint256 _totalTokensAllocated
    ) external onlyLegion {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that the totalSupply is valid
        _verifyValidTotalSupply(_askToken, _askTokenTotalSupply);

        /// Set the address of the token ditributed to investors
        askToken = _askToken;

        /// Set the total supply of the token distributed to investors
        askTokenTotalSupply = _askTokenTotalSupply;

        /// Set the vesting start time block timestamp
        vestingStartTime = _vestingStartTime;

        /// Set the total allocated amount of token for distribution.
        totalTokensAllocated = _totalTokensAllocated;

        /// Set `investmentAccepted` status to false
        if (investmentAccepted) investmentAccepted = false;

        /// Emit successfully TgeDetailsPublished
        emit TgeDetailsPublished(_askToken, _askTokenTotalSupply, _vestingStartTime, _totalTokensAllocated);
    }

    /**
     * @notice See {ILegionPreLiquidSale-supplyTokens}.
     */
    function supplyAskTokens(uint256 amount, uint256 legionFee) external onlyProject {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        /// Calculate and verify Legion Fee
        if (legionFee != (legionFeeOnTokensSoldBps * amount) / 10000) revert InvalidFeeAmount();

        /// Flag that ask tokens have been supplied
        askTokensSupplied = true;

        /// Emit successfully TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee);

        /// Transfer the allocated amount of tokens for distribution
        IERC20(askToken).safeTransferFrom(msg.sender, address(this), amount);

        /// Transfer the Legion fee to the Legion admin address
        if (legionFee != 0) IERC20(askToken).safeTransferFrom(msg.sender, legionBouncer, legionFee);
    }

    /**
     * @notice See {ILegionPreLiquidSale-updateSAFTMerkleRoot}.
     */
    function updateSAFTMerkleRoot(bytes32 merkleRoot) external onlyProject {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the project has not withdrawn any capital
        _verifyNoCapitalWithdrawn();

        /// Set the new SAFT merkle root
        saftMerkleRoot = merkleRoot;

        /// Emit successfully SAFTMerkleRootUpdated
        emit SAFTMerkleRootUpdated(merkleRoot);
    }

    /**
     * @notice See {ILegionPreLiquidSale-updateVestingTerms}.
     */
    function updateVestingTerms(
        uint256 _vestingDurationSeconds,
        uint256 _vestingCliffDurationSeconds,
        uint256 _tokenAllocationOnTGEBps
    ) external onlyProject {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the project has not withdrawn any capital
        _verifyNoCapitalWithdrawn();

        /// Verify that tokens for distribution have not been allocated
        _verifyTokensNotAllocated();

        /// Set the vesting duration in seconds
        vestingDurationSeconds = _vestingDurationSeconds;

        /// Set the vesting cliff duraation in seconds
        vestingCliffDurationSeconds = _vestingCliffDurationSeconds;

        /// Set the token allocation on TGE
        tokenAllocationOnTGEBps = _tokenAllocationOnTGEBps;

        /// Emit successfully VestingTermsUpdated
        emit VestingTermsUpdated(_vestingDurationSeconds, _vestingCliffDurationSeconds, _tokenAllocationOnTGEBps);
    }

    /**
     * @notice See {ILegionPreLiquidSale-emergencyWithdraw}.
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        /// Emit successfully EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        /// Transfer the amount to Legion's address
        IERC20(token).safeTransfer(receiver, amount);
    }

    /**
     * @notice See {ILegionPreLiquidSale-withdrawCapital}.
     */
    function withdrawRaisedCapital(address[] calldata investors) external onlyProject returns (uint256 amount) {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Loop through the investors positions
        for (uint256 i = 0; i < investors.length; ++i) {
            /// Verify that the refund period is over for the specified position
            _verifyRefundPeriodIsOver(investors[i]);

            /// Verify that the investor has actually invested capital
            _verifyCanWithdrawInvestorPosition(investors[i]);

            /// Load the investor position
            InvestorPosition storage position = investorPositions[investors[i]];

            /// Mark the amount of capital withdrawn
            position.withdrawnCapital += position.investedCapital;

            /// Increment the total amount to be withdrawn
            amount += position.investedCapital;
        }

        /// Account for the capital withdrawn
        totalCapitalWithdrawn += amount;

        /// Calculate Legion Fee
        uint256 legionFee = (legionFeeOnCapitalRaisedBps * amount) / 10000;

        /// Emit successfully CapitalWithdrawn
        emit CapitalWithdrawn(amount);

        /// Transfer the amount to the Project's address
        IERC20(bidToken).safeTransfer(msg.sender, (amount - legionFee));

        /// Transfer the Legion fee to the Legion admin address
        if (legionFee != 0) IERC20(bidToken).safeTransfer(legionBouncer, legionFee);
    }

    /**
     * @notice See {ILegionPreLiquidSale-claimTokenAllocation}.
     */
    function claimAskTokenAllocation() external {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that the investor can claim the token allocation
        _verifyCanClaimTokenAllocation(msg.sender);

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Calculate the total token amount to be claimed
        uint256 totalAmount = askTokenTotalSupply * position.cachedTokenAllocationBps / 10000;

        /// Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim = totalAmount * tokenAllocationOnTGEBps / 10000;

        /// Calculate the remaining amount to be vested
        uint256 amountToBeVested = totalAmount - amountToDistributeOnClaim;

        /// Deploy a linear vesting schedule contract
        address payable vestingAddress = _createVesting(
            msg.sender, uint64(vestingStartTime), uint64(vestingDurationSeconds), uint64(vestingCliffDurationSeconds)
        );

        /// Save the vesting address for the investor
        position.vestingAddress = vestingAddress;

        /// Mark that the token amount has been settled
        position.hasSettled = true;

        /// Emit successfully TokenAllocationClaimed
        emit TokenAllocationClaimed(amountToBeVested, amountToDistributeOnClaim, msg.sender, vestingAddress);

        /// Transfer the allocated amount of tokens for distribution
        IERC20(askToken).safeTransfer(vestingAddress, amountToBeVested);

        if (amountToDistributeOnClaim != 0) {
            /// Transfer the allocated amount of tokens for distribution on claim
            IERC20(askToken).safeTransfer(msg.sender, amountToDistributeOnClaim);
        }
    }

    /**
     * @notice See {ILegionPreLiquidSale-cancelSale}.
     */
    function cancelSale() external onlyProject {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Cache the amount of funds to be returned to the sale
        uint256 capitalToReturn = totalCapitalWithdrawn;

        /// Mark the sale as canceled
        isCanceled = true;

        /// Emit successfully CapitalWithdrawn
        emit SaleCanceled();

        /// In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            /// Set the totalCapitalWithdrawn to zero
            totalCapitalWithdrawn = 0;
            /// Transfer the allocated amount of tokens for distribution
            IERC20(bidToken).safeTransferFrom(msg.sender, address(this), capitalToReturn);
        }
    }

    /**
     * @notice See {ILegionPreLiquidSale-claimBackCapitalIfSaleIsCanceled}.
     */
    function withdrawCapitalIfSaleIsCanceled() external {
        /// Verify that the sale has been actually canceled
        _verifySaleIsCanceled();

        /// Cache the amount to refund in memory
        uint256 amountToClaim = investorPositions[msg.sender].investedCapital;

        /// Revert in case there's nothing to claim
        if (amountToClaim == 0) revert InvalidClaimAmount();

        /// Set the total pledged capital for the investor to 0
        investorPositions[msg.sender].investedCapital = 0;

        /// Decrement total capital pledged from investors
        totalCapitalInvested -= amountToClaim;

        /// Emit successfully CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToClaim, msg.sender);

        /// Transfer the refunded amount back to the investor
        IERC20(bidToken).safeTransfer(msg.sender, amountToClaim);
    }

    /**
     * @notice See {ILegionPreLiquidSale-withdrawExcessCapital}.
     */
    function withdrawExcessCapital(
        uint256 amount,
        uint256 saftInvestAmount,
        uint256 tokenAllocationBps,
        bytes32 saftHash,
        bytes32[] calldata proof
    ) external {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Load the investor position
        InvestorPosition storage position = investorPositions[msg.sender];

        /// Decrement total capital invested from investors
        totalCapitalInvested -= amount;

        /// Decrement total investor capital for the investor
        position.investedCapital -= amount;

        /// Cache the maximum amount the investor is allowed to invest
        if (position.cachedSAFTInvestAmount != saftInvestAmount) {
            position.cachedSAFTInvestAmount = saftInvestAmount;
        }

        /// Cache the token allocation in BPS
        if (position.cachedTokenAllocationBps != tokenAllocationBps) {
            position.cachedTokenAllocationBps = tokenAllocationBps;
        }

        /// Cache the hash of the SAFT signed by the investor
        if (position.cachedSAFTHash != saftHash) {
            position.cachedSAFTHash = saftHash;
        }

        /// Verify that the investor can claim excess capital
        _verifyCanWithdrawExcessCapital(msg.sender, proof);

        /// Emit successfully ExcessCapitalWithdrawn
        emit ExcessCapitalWithdrawn(amount, msg.sender, tokenAllocationBps, saftHash, block.timestamp);

        /// Transfer the excess capital to the investor
        IERC20(bidToken).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice See {ILegionPreLiquidSale-releaseTokens}.
     */
    function releaseTokens() external {
        /// Get the investor position details
        InvestorPosition memory position = investorPositions[msg.sender];

        /// Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert ZeroAddressProvided();

        /// Release tokens to the investor account
        ILegionLinearVesting(position.vestingAddress).release(askToken);
    }

    /**
     * @notice See {ILegionPreLiquidSale-toggleInvestmentAccepted}.
     */
    function toggleInvestmentAccepted() external onlyProject {
        /// Verify that tokens for distribution have not been allocated
        _verifyTokensNotAllocated();

        /// Update the `investmentAccepted` status
        investmentAccepted = !investmentAccepted;

        /// Emit successfully ToggleInvestmentAccepted
        emit ToggleInvestmentAccepted(investmentAccepted);
    }

    /**
     * @notice See {ILegionPreLiquidSale-saleConfig}.
     */
    function saleConfig() external view returns (PreLiquidSaleConfig memory preLiquidSaleConfig) {
        /// Get the pre-liquid sale config
        preLiquidSaleConfig = PreLiquidSaleConfig(
            refundPeriodSeconds,
            vestingDurationSeconds,
            vestingCliffDurationSeconds,
            tokenAllocationOnTGEBps,
            legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps,
            saftMerkleRoot,
            bidToken,
            projectAdmin,
            addressRegistry
        );
    }

    /**
     * @notice See {ILegionPreLiquidSale-saleStatus}.
     */
    function saleStatus() external view returns (PreLiquidSaleStatus memory preLiquidSaleStatus) {
        /// Get the pre-liquid sale status
        preLiquidSaleStatus = PreLiquidSaleStatus(
            askToken,
            vestingStartTime,
            askTokenTotalSupply,
            totalCapitalInvested,
            totalTokensAllocated,
            totalCapitalWithdrawn,
            isCanceled,
            askTokensSupplied,
            investmentAccepted
        );
    }

    /**
     * @notice Create a vesting schedule contract.
     *
     * @param _beneficiary The beneficiary.
     * @param _startTimestamp The start timestamp.
     * @param _durationSeconds The duration in seconds.
     * @param _cliffDurationSeconds The cliff duration in seconds.
     *
     * @return vestingInstance The address of the deployed vesting instance.
     */
    function _createVesting(
        address _beneficiary,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        uint64 _cliffDurationSeconds
    ) internal returns (address payable vestingInstance) {
        /// Deploy a vesting schedule instance
        vestingInstance = ILegionVestingFactory(vestingFactory).createLinearVesting(
            _beneficiary, _startTimestamp, _durationSeconds, _cliffDurationSeconds
        );
    }

    /**
     * @notice Verify if the sale configuration is valid.
     *
     * @param _preLiquidSaleConfig The configuration for the pre-liquid sale.
     */
    function _verifyValidConfig(PreLiquidSaleConfig calldata _preLiquidSaleConfig) private view {
        /// Check for zero addresses provided
        if (
            _preLiquidSaleConfig.bidToken == address(0) || _preLiquidSaleConfig.projectAdmin == address(0)
                || _preLiquidSaleConfig.addressRegistry == address(0) || legionBouncer == address(0)
                || vestingFactory == address(0)
        ) revert ZeroAddressProvided();

        /// Check for zero values provided
        if (_preLiquidSaleConfig.refundPeriodSeconds == 0 || _preLiquidSaleConfig.saftMerkleRoot == 0) {
            revert ZeroValueProvided();
        }

        /// Check if prefund, allocation, sale, refund and lockup periods are within range
        if (_preLiquidSaleConfig.refundPeriodSeconds > TWO_WEEKS) revert InvalidPeriodConfig();
    }

    /**
     * @notice Verify if an investor is eligible to invest capital in the pre-liquid sale.
     *
     * @param _investor The address of the investor trying to participate.
     * @param _proof The merkle proof that the investor is part of the whitelist
     */
    function _verifyCanInvestCapital(address _investor, bytes32[] calldata _proof) private view {
        /// Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        /// Generate the merkle leaf
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(
                        _investor,
                        position.cachedSAFTInvestAmount,
                        position.cachedTokenAllocationBps,
                        position.cachedSAFTHash
                    )
                )
            )
        );

        /// Verify that the amount invested is the maximum invest amount allowed
        if ((position.investedCapital != position.cachedSAFTInvestAmount)) {
            revert NotAllowedToInvestCapital(_investor);
        }

        /// Verify the merkle proof
        if (!MerkleProof.verify(_proof, saftMerkleRoot, leaf)) revert NotAllowedToInvestCapital(_investor);
    }

    function _verifyCanWithdrawInvestorPosition(address _investor) private view {
        /// Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        /// Check if the investor has invested capital
        if (position.investedCapital == 0) revert CapitalNotInvested(_investor);

        /// Check if the capital has not been already withdrawn by the Project
        if (position.withdrawnCapital == position.investedCapital) revert CapitalAlreadyWithdrawn(_investor);
    }

    /**
     * @notice Verify that the refund period is not over.
     *
     * @param _investor The address of the investor
     */
    function _verifyRefundPeriodIsNotOver(address _investor) private view {
        /// Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        /// Check if the refund period is over
        if (block.timestamp > position.cachedInvestTimestamp + refundPeriodSeconds) revert RefundPeriodIsOver();
    }

    /**
     * @notice Verify that the refund period is over.
     *
     * @param _investor The address of the investor
     */
    function _verifyRefundPeriodIsOver(address _investor) private view {
        /// Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        /// Check if the refund period is not over
        if (block.timestamp <= position.cachedInvestTimestamp + refundPeriodSeconds) revert RefundPeriodIsNotOver();
    }

    /**
     * @notice Verify if the project can supply tokens for distribution.
     *
     * @param _amount The amount to supply.
     */
    function _verifyCanSupplyTokens(uint256 _amount) private view {
        /// Revert if Legion has not set the total amount of tokens allocated for distribution
        if (totalTokensAllocated == 0) revert TokensNotAllocated();

        /// Revert if tokens have already been supplied
        if (askTokensSupplied) revert TokensAlreadySupplied();

        /// Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != totalTokensAllocated) revert InvalidTokenAmountSupplied(_amount);
    }

    /**
     * @notice Verify if the tokens for distribution have not been allocated.
     */
    function _verifyTokensNotAllocated() private view {
        /// Revert if the tokens for distribution have already been allocated
        if (totalTokensAllocated > 0) revert TokensAlreadyAllocated();
    }

    /**
     * @notice Verify that the sale is not canceled.
     */
    function _verifySaleNotCanceled() internal view {
        if (isCanceled) revert SaleIsCanceled();
    }

    /**
     * @notice Verify that the sale is canceled.
     */
    function _verifySaleIsCanceled() internal view {
        if (!isCanceled) revert SaleIsNotCanceled();
    }

    /**
     * @notice Verify that the totalSupply provided by Legion is valid.
     */
    function _verifyValidTotalSupply(address _token, uint256 _totalSupply) internal view {
        if (_totalSupply < IERC20(_token).totalSupply()) revert InvalidTotalSupply();
    }

    /**
     * @notice Verify that the Project has not withdrawn any capital.
     */
    function _verifyNoCapitalWithdrawn() internal view {
        if (totalCapitalWithdrawn > 0) revert ProjectHasWithdrawnCapital();
    }

    /**
     * @notice Verify if an investor is eligible to withdraw excess capital.
     *
     * @param _investor The address of the investor trying to participate.
     * @param _proof The merkle proof that the investor is part of the whitelist
     */
    function _verifyCanWithdrawExcessCapital(address _investor, bytes32[] calldata _proof) internal view {
        /// Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        /// Generate the merkle leaf
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(
                        _investor,
                        position.cachedSAFTInvestAmount,
                        position.cachedTokenAllocationBps,
                        position.cachedSAFTHash
                    )
                )
            )
        );

        /// Verify that the amount invested is equal to the maximum invest amount allowed
        if (position.investedCapital != position.cachedSAFTInvestAmount) {
            revert NotAllowedToWithdrawExcessCapital(_investor);
        }

        /// Verify the merkle proof
        if (!MerkleProof.verify(_proof, saftMerkleRoot, leaf)) revert NotAllowedToWithdrawExcessCapital(_investor);
    }

    /**
     * @notice Verify if an investor is eligible to claim token allocation.
     *
     * @param _investor The address of the investor.
     */
    function _verifyCanClaimTokenAllocation(address _investor) internal view {
        /// Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        /// Check if the askToken has been supplied to the sale
        if (!askTokensSupplied) revert AskTokensNotSupplied();

        /// Check if the investor has already settled their allocation
        if (position.hasSettled) revert AlreadySettled(_investor);

        /// Check if the investor has invested capital
        if (position.investedCapital == 0) revert CapitalNotInvested(msg.sender);
    }

    /**
     * @notice Verify that the Project has not accepted the investment round.
     */
    function _verifyInvestmentAccepted() internal view {
        /// Check if investment is accepted by the Project
        if (!investmentAccepted) revert InvestmentNotAccepted();
    }
}
