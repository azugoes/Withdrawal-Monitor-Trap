// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IMonitoredBridge
/// @notice The interface for the bridge contract that the trap will monitor.
interface IMonitoredBridge {
    /// @notice Gets the total number of withdrawals.
    /// @return The withdrawal count.
    function getWithdrawalCount() external view returns (uint256);

    /// @notice Pauses the contract.
    function pause() external;

    /// @notice Returns true if the contract is paused.
    /// @return A boolean indicating the paused state.
    function paused() external view returns (bool);
}
