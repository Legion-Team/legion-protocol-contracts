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
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ILegionBaseSale} from "./interfaces/ILegionBaseSale.sol";
import {ILegionLinearVesting} from "./interfaces/ILegionLinearVesting.sol";
import {ILegionVestingFactory} from "./interfaces/ILegionVestingFactory.sol";

abstract contract LegionBaseSale is ILegionBaseSale, Initializable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev The sale period duration in seconds.
    uint256 internal salePeriodSeconds;

    /// @dev The refund period duration in seconds.
    uint256 internal refundPeriodSeconds;

    /// @dev The lockup period duration in seconds.
    uint256 internal lockupPeriodSeconds;

    /// @dev The vesting schedule duration for the token sold in seconds.
    uint256 internal vestingDurationSeconds;

    /// @dev The vesting cliff duration for the token sold in seconds.
    uint256 internal vestingCliffDurationSeconds;

    /// @dev Legion's fee on capital raised in BPS (Basis Points).
    uint256 internal legionFeeOnCapitalRaisedBps;

    /// @dev Legion's fee on tokens sold in BPS (Basis Points).
    uint256 internal legionFeeOnTokensSoldBps;

    /// @dev The minimum pledge amount denominated in the `bidToken`
    uint256 internal minimumPledgeAmount;

    /// @dev The address of the token used for raising capital.
    address internal bidToken;

    /// @dev The address of the token being sold to investors.
    address internal askToken;

    /// @dev The admin address of the project raising capital.
    address internal projectAdmin;

    /// @dev The address of Legion's Address Registry contract.
    address internal addressRegistry;

    /// @dev The address of Legion bouncer.
    address internal legionBouncer;

    /// @dev The address of Legion signer.
    address internal legionSigner;

    /// @dev The address of Legion fee receiver.
    address internal legionFeeReceiver;

    /// @dev The address of Legion's Vesting Factory contract.
    address internal vestingFactory;

    /// @dev The unix timestamp (seconds) of the block when the sale starts.
    uint256 internal startTime;

    /// @dev The unix timestamp (seconds) of the block when the sale ends.
    uint256 internal endTime;

    /// @dev The unix timestamp (seconds) of the block when the refund period ends.
    uint256 internal refundEndTime;

    /// @dev The unix timestamp (seconds) of the block when the lockup period ends.
    uint256 internal lockupEndTime;

    /// @dev The unix timestamp (seconds) of the block when the vesting period starts.
    uint256 internal vestingStartTime;

    /// @dev The total capital pledged by investors.
    uint256 internal totalCapitalPledged;

    /// @dev The total amount of tokens allocated to investors.
    uint256 internal totalTokensAllocated;

    /// @dev The total capital raised from the sale.
    uint256 internal totalCapitalRaised;

    /// @dev The merkle root for verification of token distribution amounts.
    bytes32 internal claimTokensMerkleRoot;

    /// @dev The merkle root for verification of excess capital distribution amounts.
    bytes32 internal excessCapitalMerkleRoot;

    /// @dev Whether the sale has been canceled or not.
    bool internal isCanceled;

    /// @dev Whether tokens have been supplied by the project or not.
    bool internal tokensSupplied;

    /// @dev Mapping of investor address to investor position.
    mapping(address investorAddress => InvestorPosition investorPosition) public investorPositions;

    /// @dev Constant representing 1 hour in seconds.
    uint256 internal constant ONE_HOUR = 3600;

    /// @dev Constant representing 2 weeks in seconds.
    uint256 internal constant TWO_WEEKS = 1209600;

    /// @dev Constant representing 3 months in seconds.
    uint256 internal constant THREE_MONTHS = 7776000;

    /// @dev Constant representing 6 months in seconds.
    uint256 internal constant SIX_MONTHS = 15780000;

    /// @dev Constant representing the LEGION_BOUNCER unique ID
    bytes32 internal constant LEGION_BOUNCER_ID = bytes32("LEGION_BOUNCER");

    /// @dev Constant representing the LEGION_SIGNER unique ID
    bytes32 internal constant LEGION_SIGNER_ID = bytes32("LEGION_SIGNER");

    /// @dev Constant representing the LEGION_FEE_RECEIVER unique ID
    bytes32 internal constant LEGION_FEE_RECEIVER_ID = bytes32("LEGION_FEE_RECEIVER");

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
     * @notice Throws when method is called and the `askToken` is unavailable.
     */
    modifier askTokenAvailable() {
        if (askToken == address(0)) revert AskTokenUnavailable();
        _;
    }

    /**
     * @notice LegionBaseSale constructor.
     */
    constructor() {
        /// Disable initialization
        _disableInitializers();
    }

    /**
     * @notice See {ILegionBaseSale-requestRefund}.
     */
    function requestRefund() external virtual {
        /// Verify that the refund period is not over
        _verifyRefundPeriodIsNotOver();

        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the sale has ended
        _verifySaleHasEnded();

        /// Cache the amount to refund in memory
        uint256 amountToRefund = investorPositions[msg.sender].pledgedCapital;

        /// Revert in case there's nothing to refund
        if (amountToRefund == 0) revert InvalidRefundAmount();

        /// Set the total pledged capital for the investor to 0
        investorPositions[msg.sender].pledgedCapital = 0;

        /// Decrement total capital pledged from investors
        totalCapitalPledged -= amountToRefund;

        /// Emit successfully CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender);

        /// Transfer the refunded amount back to the investor
        IERC20(bidToken).safeTransfer(msg.sender, amountToRefund);
    }

    /**
     * @notice See {ILegionBaseSale-withdrawCapital}.
     */
    function withdrawCapital() external virtual onlyProject {
        /// Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that sale results have been published
        _verifySaleResultsArePublished();

        /// Check if projects are withdrawing capital on the sale source chain
        if (askToken != address(0)) {
            /// Allow projects to withdraw capital only in case they've supplied tokens
            _verifyTokensSupplied();
        }

        /// Cache value in memory
        uint256 _totalCapitalRaised = totalCapitalRaised;

        /// Calculate Legion Fee
        uint256 _legionFee = (legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / 10000;

        /// Emit successfully CapitalWithdrawn
        emit CapitalWithdrawn(_totalCapitalRaised, msg.sender);

        /// Transfer the raised capital to the project owner
        IERC20(bidToken).safeTransfer(msg.sender, (_totalCapitalRaised - _legionFee));

        /// Transfer the Legion fee to the Legion fee receiver address
        if (_legionFee != 0) IERC20(bidToken).safeTransfer(legionFeeReceiver, _legionFee);
    }

    /**
     * @notice See {ILegionBaseSale-claimTokenAllocation}.
     */
    function claimTokenAllocation(uint256 amount, bytes32[] calldata proof) external virtual askTokenAvailable {
        /// Verify that sales results have been published
        _verifySaleResultsArePublished();

        /// Verify that the investor is eligible to claim the requested amount
        _verifyCanClaimTokenAllocation(msg.sender, amount, proof);

        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the lockup period is over
        _verifyLockupPeriodIsOver();

        /// Mark that the token amount has been settled
        investorPositions[msg.sender].hasSettled = true;

        /// Deploy vesting and distribute tokens only if there is anything to distribute
        if (amount != 0) {
            /// Deploy a linear vesting schedule contract
            address payable vestingAddress = _createVesting(
                msg.sender,
                uint64(vestingStartTime),
                uint64(vestingDurationSeconds),
                uint64(vestingCliffDurationSeconds)
            );

            /// Emit successfully TokenAllocationClaimed
            emit TokenAllocationClaimed(amount, msg.sender, vestingAddress);

            /// Save the vesting address for the investor
            investorPositions[msg.sender].vestingAddress = vestingAddress;

            /// Transfer the allocated amount of tokens for distribution
            IERC20(askToken).safeTransfer(vestingAddress, amount);
        }
    }

    /**
     * @notice See {ILegionBaseSale-claimExcessCapital}.
     */
    function claimExcessCapital(uint256 amount, bytes32[] calldata proof) external virtual {
        /// Verify that the sale has ended
        _verifySaleHasEnded();

        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the investor is eligible to get excess capital back
        _verifyCanClaimExcessCapital(msg.sender, amount, proof);

        /// Mark that the excess capital has been returned
        investorPositions[msg.sender].hasClaimedExcess = true;

        if (amount != 0) {
            /// Decrement the total pledged capital for the investor
            investorPositions[msg.sender].pledgedCapital -= amount;

            /// Decrement total capital pledged from investors
            totalCapitalPledged -= amount;

            /// Emit successfully ExcessCapitalClaimed
            emit ExcessCapitalClaimed(amount, msg.sender);

            /// Transfer the excess capital back to the investor
            IERC20(bidToken).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @notice See {ILegionBaseSale-releaseTokens}.
     */
    function releaseTokens() external virtual askTokenAvailable {
        /// Get the investor position details
        InvestorPosition memory position = investorPositions[msg.sender];

        /// Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert ZeroAddressProvided();

        /// Release tokens to the investor account
        ILegionLinearVesting(position.vestingAddress).release(askToken);
    }

    /**
     * @notice See {ILegionBaseSale-supplyTokens}.
     */
    function supplyTokens(uint256 amount, uint256 legionFee) external virtual onlyProject askTokenAvailable {
        /// Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that tokens have not been supplied
        _verifyTokensNotSupplied();

        /// Flag that tokens have been supplied
        tokensSupplied = true;

        /// Calculate and verify Legion Fee
        if (legionFee != (legionFeeOnTokensSoldBps * amount) / 10000) revert InvalidFeeAmount();

        /// Emit successfully TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee);

        /// Transfer the allocated amount of tokens for distribution
        IERC20(askToken).safeTransferFrom(msg.sender, address(this), amount);

        /// Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) IERC20(askToken).safeTransferFrom(msg.sender, legionFeeReceiver, legionFee);
    }

    /**
     * @notice See {ILegionBaseSale-publishExcessCapitalResults}.
     */
    function publishExcessCapitalResults(bytes32 merkleRoot) external virtual onlyLegion {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the sale has ended
        _verifySaleHasEnded();

        /// Verify that excess capital results are not already published
        _verifyCanPublishExcessCapitalResults();

        /// Set the merkle root for claiming excess capital
        excessCapitalMerkleRoot = merkleRoot;

        /// Emit successfully ExcessCapitalResultsPublished
        emit ExcessCapitalResultsPublished(merkleRoot);
    }

    /**
     * @notice See {ILegionBaseSale-cancelSale}.
     */
    function cancelSale() public virtual onlyProject {
        /// Allow the Project to cancel the sale at any time until results are published
        /// Results are published after the refund period is over
        _verifySaleResultsNotPublished();

        /// Verify sale has not already been canceled
        _verifySaleNotCanceled();

        /// Mark sale as canceled
        isCanceled = true;

        /// Emit successfully SaleCanceled
        emit SaleCanceled();
    }

    /**
     * @notice See {ILegionBaseSale-cancelExpiredSale}.
     */
    function cancelExpiredSale() external virtual {
        /// Verify that the lockup period is over
        _verifyLockupPeriodIsOver();

        /// Verify sale has not already been canceled
        _verifySaleNotCanceled();

        if (askToken != address(0)) {
            /// Verify that no tokens have been supplied by the project
            _verifyTokensNotSupplied();
        } else {
            /// Verify that the sale results have not been published
            _verifySaleResultsNotPublished();
        }

        /// Mark sale as canceled
        isCanceled = true;

        /// Emit successfully SaleCanceled
        emit SaleCanceled();
    }

    /**
     * @notice See {ILegionBaseSale-claimBackCapitalIfCanceled}.
     */
    function claimBackCapitalIfCanceled() external virtual {
        /// Verify that the sale has been actually canceled
        _verifySaleIsCanceled();

        /// Cache the amount to refund in memory
        uint256 amountToClaim = investorPositions[msg.sender].pledgedCapital;

        /// Revert in case there's nothing to claim
        if (amountToClaim == 0) revert InvalidClaimAmount();

        /// Set the total pledged capital for the investor to 0
        investorPositions[msg.sender].pledgedCapital = 0;

        /// Decrement total capital pledged from investors
        totalCapitalPledged -= amountToClaim;

        /// Emit successfully CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToClaim, msg.sender);

        /// Transfer the refunded amount back to the investor
        IERC20(bidToken).safeTransfer(msg.sender, amountToClaim);
    }

    /**
     * @notice See {ILegionBaseSale-emergencyWithdraw}.
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external virtual onlyLegion {
        /// Emit successfully EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        /// Transfer the amount to Legion's address
        IERC20(token).safeTransfer(receiver, amount);
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
    ) internal virtual returns (address payable vestingInstance) {
        /// Deploy a vesting schedule instance
        vestingInstance = ILegionVestingFactory(vestingFactory).createLinearVesting(
            _beneficiary, _startTimestamp, _durationSeconds, _cliffDurationSeconds
        );
    }

    /**
     * @notice Verify if an investor is eligible to claim tokens allocated from the sale.
     *
     * @param _investor The address of the investor trying to participate.
     * @param _amount The amount to claim.
     * @param _proof The merkle proof that the investor is part of the whitelist
     */
    function _verifyCanClaimTokenAllocation(address _investor, uint256 _amount, bytes32[] calldata _proof)
        internal
        view
        virtual
    {
        /// Generate the merkle leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, _amount))));

        /// Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        /// Verify the merkle proof
        if (!MerkleProof.verify(_proof, claimTokensMerkleRoot, leaf)) revert NotInClaimWhitelist(_investor);

        /// Check if the investor has already settled their allocation
        if (position.hasSettled) revert AlreadySettled(_investor);

        /// Safeguard to check if the investor has pledged capital
        if (position.pledgedCapital == 0) revert NoCapitalPledged(_investor);
    }

    /**
     * @notice Verify if an investor is eligible to get excess capital back.
     *
     * @param _investor The address of the investor trying to participate.
     * @param _amount The amount to claim.
     * @param _proof The merkle proof that the investor is part of the whitelist
     */
    function _verifyCanClaimExcessCapital(address _investor, uint256 _amount, bytes32[] calldata _proof)
        internal
        view
        virtual
    {
        /// Generate the merkle leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, _amount))));

        /// Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        /// Verify the merkle proof
        if (!MerkleProof.verify(_proof, excessCapitalMerkleRoot, leaf)) revert CannotClaimExcessCapital(_investor);

        /// Check if the investor has already settled their allocation
        if (position.hasClaimedExcess) revert AlreadyClaimedExcess(_investor);

        /// Safeguard to check if the investor has pledged capital
        if (position.pledgedCapital == 0) revert NoCapitalPledged(_investor);
    }

    /**
     * @notice Verify that the amount pledge is more than the minimum required.
     *
     * @param _amount The amount being pledged.
     */
    function _verifyMinimumPledgeAmount(uint256 _amount) internal view virtual {
        if (_amount < minimumPledgeAmount) revert InvalidPledgeAmount(_amount);
    }

    /**
     * @notice Verify that the sale has ended.
     */
    function _verifySaleHasEnded() internal view virtual {
        if (block.timestamp < endTime) revert SaleHasNotEnded();
    }

    /**
     * @notice Verify that the sale has not ended.
     */
    function _verifySaleHasNotEnded() internal view virtual {
        if (block.timestamp >= endTime) revert SaleHasEnded();
    }

    /**
     * @notice Verify that the refund period is over.
     */
    function _verifyRefundPeriodIsOver() internal view virtual {
        if (block.timestamp < refundEndTime) revert RefundPeriodIsNotOver();
    }

    /**
     * @notice Verify that the refund period is not over.
     */
    function _verifyRefundPeriodIsNotOver() internal view virtual {
        if (block.timestamp >= refundEndTime) revert RefundPeriodIsOver();
    }

    /**
     * @notice Verify that the lockup period is over.
     */
    function _verifyLockupPeriodIsOver() internal view virtual {
        if (block.timestamp < lockupEndTime) revert LockupPeriodIsNotOver();
    }

    /**
     * @notice Verify if sale results are published.
     */
    function _verifySaleResultsArePublished() internal view virtual {
        if (totalTokensAllocated == 0) revert SaleResultsNotPublished();
    }

    /**
     * @notice Verify if sale results are not published.
     */
    function _verifySaleResultsNotPublished() internal view virtual {
        if (totalTokensAllocated != 0) revert SaleResultsAlreadyPublished();
    }

    /**
     * @notice Verify if the project can supply tokens for distribution.
     *
     * @param _amount The amount to supply.
     */
    function _verifyCanSupplyTokens(uint256 _amount) internal view virtual {
        /// Revert if Legion has not set the total amount of tokens allocated for distribution
        if (totalTokensAllocated == 0) revert TokensNotAllocated();

        /// Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != totalTokensAllocated) revert InvalidTokenAmountSupplied(_amount);
    }

    /**
     * @notice Verify if Legion can publish sale results.
     */
    function _verifyCanPublishSaleResults() internal view virtual {
        if (totalTokensAllocated != 0) revert TokensAlreadyAllocated(totalTokensAllocated);
    }

    /**
     * @notice Verify if Legion can publish the excess capital results.
     */
    function _verifyCanPublishExcessCapitalResults() internal view virtual {
        if (excessCapitalMerkleRoot != bytes32(0)) revert ExcessCapitalResultsAlreadyPublished(excessCapitalMerkleRoot);
    }

    /**
     * @notice Verify that the sale is not canceled.
     */
    function _verifySaleNotCanceled() internal view virtual {
        if (isCanceled) revert SaleIsCanceled();
    }

    /**
     * @notice Verify that the sale is canceled.
     */
    function _verifySaleIsCanceled() internal view virtual {
        if (!isCanceled) revert SaleIsNotCanceled();
    }

    /**
     * @notice Verify that the project has not supplied tokens to the sale.
     */
    function _verifyTokensNotSupplied() internal view virtual {
        if (tokensSupplied) revert TokensAlreadySupplied();
    }

    /**
     * @notice Verify that the project has supplied tokens to the sale.
     */
    function _verifyTokensSupplied() internal view virtual {
        if (!tokensSupplied) revert TokensNotSupplied();
    }

    /**
     * @notice Verify that the signature provided is signed by Legion.
     *
     * @param _signature The signature to verify.
     */
    function _verifyLegionSignature(bytes memory _signature) internal view virtual {
        bytes32 _data = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid)).toEthSignedMessageHash();
        if (_data.recover(_signature) != legionSigner) revert InvalidSignature();
    }
}
