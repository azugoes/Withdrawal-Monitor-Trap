// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMonitoredBridge} from "../interfaces/IMonitoredBridge.sol";

/// @title MockMonitoredBridge
/// @notice A mock contract for testing the withdrawal monitoring trap.
contract MockMonitoredBridge is IMonitoredBridge {
    uint256 public withdrawalCount;
    bool public paused;

    /// @notice Simulates a withdrawal and increments the counter.
    function withdraw() external {
        require(!paused, "Contract is paused");
        withdrawalCount++;
    }

    /// @notice Gets the total number of withdrawals.
    /// @return The current withdrawal count.
    function getWithdrawalCount() external view returns (uint256) {
        return withdrawalCount;
    }

    /// @notice Pauses the contract, callable by anyone for this PoC.
    function pause() external {
        paused = true;
    }
}
