// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

//       ___       ___           ___                       ___           ___
//      /\__\     /\  \         /\  \          ___        /\  \         /\__\
//     /:/  /    /::\  \       /::\  \        /\  \      /::\  \       /::|  |
//    /:/  /    /:/\:\  \     /:/\:\  \       \:\  \    /:/\:\  \     /:|:|  |
//   /:/  /    /::\~\:\  \   /:/  \:\  \      /::\__\  /:/  \:\  \   /:/|:|  |__
//  /:/__/    /:/\:\ \:\__\ /:/__/_\:\__\  __/:/\/__/ /:/__/ \:\__\ /:/ |:| /\__\
//  \:\  \    \:\~\:\ \/__/ \:\  /\ \/__/ /\/:/  /    \:\  \ /:/  / \/__|:|/:/  /
//   \:\  \    \:\ \:\__\    \:\ \:\__\   \::/__/      \:\  /:/  /      |:/:/  /
//    \:\  \    \:\ \/__/     \:\/:/  /    \:\__\       \:\/:/  /       |::/  /
//     \:\__\    \:\__\        \::/  /      \/__/        \::/  /        /:/  /
//      \/__/     \/__/         \/__/                     \/__/         \/__/

import { VestingWalletUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";

import { Errors } from "../utils/Errors.sol";

/**
 * @title Legion Linear Vesting
 * @author Legion
 * @notice Releases vested tokens to users with a linear schedule and cliff protection.
 * @dev Extends OpenZeppelin's VestingWalletUpgradeable with cliff functionality.
 */
contract LegionLinearVesting is VestingWalletUpgradeable {
    /// @dev Unix timestamp (seconds) when the cliff period ends.
    uint64 private s_cliffEndTimestamp;

    /// @dev Address of the vesting controller.
    address private s_vestingController;

    /// @notice Restricts token release until the cliff period has ended.
    /// @dev Reverts with LegionVesting__CliffNotEnded if block.timestamp is before s_cliffEndTimestamp.
    modifier onlyCliffEnded() {
        if (block.timestamp < s_cliffEndTimestamp) revert Errors.LegionVesting__CliffNotEnded(block.timestamp);
        _;
    }

    /// @notice Restricts function access to the vesting controller only.
    /// @dev Reverts if the caller is not the configured vesting controller address.
    modifier onlyVestingController() {
        if (msg.sender != s_vestingController) revert Errors.LegionSale__NotCalledByVestingController();
        _;
    }

    /// @notice Constructor for the LegionLinearVesting contract.
    /// @dev Prevents the implementation contract from being initialized directly.
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /// @notice Initializes the vesting contract with specified parameters.
    /// @dev Sets up the linear vesting schedule and cliff; callable only once.
    /// @param beneficiary The address to receive the vested tokens.
    /// @param vestingController The address of the vesting controller contract for access control.
    /// @param startTimestamp The Unix timestamp (seconds) when vesting starts.
    /// @param durationSeconds The total duration of the vesting period in seconds.
    /// @param cliffDurationSeconds The duration of the cliff period in seconds.
    function initialize(
        address beneficiary,
        address vestingController,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    )
        external
        initializer
    {
        // Initialize the LegionLinearVesting clone
        __VestingWallet_init(beneficiary, startTimestamp, durationSeconds);

        // Set the cliff end timestamp based on the cliff duration
        s_cliffEndTimestamp = startTimestamp + cliffDurationSeconds;

        // Set the vesting controller address for access control
        s_vestingController = vestingController;
    }

    /// @notice Returns the timestamp when the cliff period ends.
    /// @dev Indicates when tokens become releasable.
    /// @return The Unix timestamp (seconds) of the cliff end.
    function cliffEndTimestamp() external view returns (uint64) {
        return s_cliffEndTimestamp;
    }

    /// @notice Releases vested tokens of a specific type to the beneficiary.
    /// @dev Overrides VestingWalletUpgradeable; requires cliff to have ended.
    /// @param token The address of the token to release.
    function release(address token) public override onlyCliffEnded {
        super.release(token);
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @dev Can only be called by the vesting controller.
    /// @param newOwner The address to transfer ownership to.
    function emergencyTransferOwnership(address newOwner) external onlyVestingController {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }
}
