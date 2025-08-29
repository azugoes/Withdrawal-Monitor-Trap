// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "./interfaces/ITrap.sol";
import {IMonitoredBridge} from "./interfaces/IMonitoredBridge.sol";

/// @title WithdrawalMonitorTrap
/// @notice A Drosera trap that monitors for a high frequency of withdrawals.
/// @dev This trap is stateless and uses a hardcoded address for the contract it monitors.
contract WithdrawalMonitorTrap is ITrap {
    // --- Constants & Placeholders ---

    /// @notice The address of the bridge/vault contract to monitor.
    /// @dev THIS IS A PLACEHOLDER. Replace with the actual deployed contract address.
    IMonitoredBridge public constant MONITORED_BRIDGE = IMonitoredBridge(0x5FbDB2315678afecb367f032d93F642f64180aa3);

    /// @notice The number of withdrawals within the monitored window that triggers the trap.
    uint256 public constant WITHDRAWAL_THRESHOLD = 10;

    // NOTE: The time window is not enforced on-chain. The Drosera node's probing
    // frequency determines the effective time window. For example, if the node
    // probes every 60 seconds, the check is effectively per minute.

    /// @notice Collects the current withdrawal count from the monitored contract.
    /// @return abi-encoded withdrawal count.
    function collect() external view override returns (bytes memory) {
        uint256 currentWithdrawalCount = MONITORED_BRIDGE.getWithdrawalCount();
        return abi.encode(currentWithdrawalCount);
    }

    /// @notice Determines if the withdrawal threshold has been crossed.
    /// @param data An array of collected data points (encoded withdrawal counts).
    /// @return (true, "") if the threshold is crossed, otherwise (false, "").
    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, "");
        }

        (uint256 firstCount) = abi.decode(data[0], (uint256));
        (uint256 lastCount) = abi.decode(data[data.length - 1], (uint256));

        if (lastCount > firstCount) {
            uint256 withdrawals = lastCount - firstCount;
            if (withdrawals >= WITHDRAWAL_THRESHOLD) {
                // Trigger the response. The response data is empty because the
                // `pause()` function requires no arguments.
                return (true, "");
            }
        }

        return (false, "");
    }
}
