// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "./interfaces/ITrap.sol";
import {IMonitoredBridge} from "./interfaces/IMonitoredBridge.sol";

/**
 * @title SustainedBurstWithdrawalTrap
 * @notice Triggers only on *sustained* withdrawal bursts:
 *         - total increase over the window >= TOTAL_THRESHOLD, AND
 *         - at least STREAK_MIN consecutive intervals with increase >= PER_INTERVAL_MIN
 *
 * Data ordering from Drosera: data[0] = newest, data[n-1] = oldest.
 */
contract SustainedBurstWithdrawalTrap is ITrap {
    // :wrench: Replace with your real bridge address
    IMonitoredBridge public constant MONITORED_BRIDGE =
        IMonitoredBridge(0x5FbDB2315678afecb367f032d93F642f64180aa3);

    // --- Tuning knobs (edit to taste) ---
    uint256 public constant MIN_SAMPLES       = 6;  // need at least 6 snapshots (=> 5 intervals)
    uint256 public constant TOTAL_THRESHOLD   = 30; // total withdrawals across window
    uint256 public constant PER_INTERVAL_MIN  = 5;  // withdrawals in a single interval to count toward streak
    uint256 public constant STREAK_MIN        = 3;  // require this many consecutive "big" intervals

    // We include paused + block to make decisions & for observability
    function collect() external view override returns (bytes memory) {
        return abi.encode(
            MONITORED_BRIDGE.getWithdrawalCount(),
            MONITORED_BRIDGE.paused(),
            block.number
        );
    }

    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        if (data.length < MIN_SAMPLES) {
            return (false, bytes("insufficient_history"));
        }

        (uint256 newestCount, bool newestPaused, ) =
            abi.decode(data[0], (uint256, bool, uint256));
        (uint256 oldestCount, , ) =
            abi.decode(data[data.length - 1], (uint256, bool, uint256));

        // Don't spam pause if already paused.
        if (newestPaused) return (false, bytes("already_paused"));

        // Guard reset/non-monotonic counter cases.
        if (newestCount <= oldestCount) return (false, bytes("non_monotonic"));

        uint256 totalIncrease = newestCount - oldestCount;

        // Compute longest consecutive streak of "big" intervals.
        uint256 longestStreak = 0;
        uint256 streak = 0;
        uint256 bigIntervals = 0;

        for (uint256 i = 0; i + 1 < data.length; i++) {
            (uint256 a,,) = abi.decode(data[i], (uint256, bool, uint256));       // newer
            (uint256 b,,) = abi.decode(data[i + 1], (uint256, bool, uint256));   // older

            // If counter moves backward, break the streak (treat as reset/noise).
            if (a < b) {
                streak = 0;
                continue;
            }

            uint256 inc = a - b;
            if (inc >= PER_INTERVAL_MIN) {
                unchecked { streak++; }
                if (streak > longestStreak) longestStreak = streak;
                unchecked { bigIntervals++; }
            } else {
                streak = 0;
            }
        }

        // Trigger only on sustained pressure + total spike.
        if (totalIncrease >= TOTAL_THRESHOLD && longestStreak >= STREAK_MIN) {
            // You can pass structured payload to the responder (e.g., for logging)
            // (totalIncrease, longestStreak, bigIntervals)
            return (true, abi.encode(totalIncrease, longestStreak, bigIntervals));
        }

        return (false, bytes(""));
    }
}