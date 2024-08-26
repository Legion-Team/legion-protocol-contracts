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
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ILegionVestingFactory} from "./interfaces/ILegionVestingFactory.sol";
import {LegionLinearVesting} from "./LegionLinearVesting.sol";

/**
 * @title Legion Vesting Factory.
 * @author Legion.
 * @notice A factory contract for deploying proxy instances of a Legion vesting contracts.
 */
contract LegionVestingFactory is ILegionVestingFactory {
    using Clones for address;

    /// @dev The LegionLinearVesting implementation contract.
    address public immutable linearVestingTemplate = address(new LegionLinearVesting());

    /**
     * @notice See {ILegionLinearVestingFactory-createLinearVesting}.
     */
    function createLinearVesting(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    ) external returns (address payable linearVestingInstance) {
        /// Deploy a LegionLinearVesting instance
        linearVestingInstance = payable(linearVestingTemplate.clone());

        /// Emit successfully NewLinearVestingCreated
        emit NewLinearVestingCreated(beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds);

        /// Initialize the LegionLinearVesting with the provided configuration
        LegionLinearVesting(linearVestingInstance).initialize(
            beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds
        );
    }
}
