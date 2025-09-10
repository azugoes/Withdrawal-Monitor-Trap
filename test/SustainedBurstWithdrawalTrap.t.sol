// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SustainedBurstWithdrawalTrap} from "../src/SustainedBurstWithdrawalTrap.sol";
import {Response} from "../src/Response.sol";
import {MockMonitoredBridge} from "../src/mock/MockMonitoredBridge.sol";

contract SustainedBurstWithdrawalTrapTest is Test {
    SustainedBurstWithdrawalTrap internal trap;
    MockMonitoredBridge internal bridge;
    Response internal response;

    address private constant HARDCODED_BRIDGE_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address private constant DROSERA_EXECUTOR = address(0x1337);

    function setUp() public {
        vm.etch(HARDCODED_BRIDGE_ADDRESS, address(new MockMonitoredBridge()).code);
        bridge = MockMonitoredBridge(HARDCODED_BRIDGE_ADDRESS);
        response = new Response(DROSERA_EXECUTOR, address(bridge));
        trap = new SustainedBurstWithdrawalTrap();
    }

    function collectHelper(uint256 count, bool paused) internal view returns (bytes memory) {
        return abi.encode(count, paused, block.number);
    }

    function test_ShouldNotRespond_InsufficientHistory() public {
        bytes[] memory data = new bytes[](trap.MIN_SAMPLES() - 1);
        (bool should, bytes memory reason) = trap.shouldRespond(data);
        assertFalse(should);
        assertEq(reason, "insufficient_history");
    }

    function test_ShouldNotRespond_AlreadyPaused() public {
        bytes[] memory data = new bytes[](trap.MIN_SAMPLES());
        for (uint i = 0; i < trap.MIN_SAMPLES(); i++) {
            data[i] = collectHelper(0, i == 0);
        }

        (bool should, bytes memory reason) = trap.shouldRespond(data);
        assertFalse(should);
        assertEq(reason, "already_paused");
    }

    function test_ShouldNotRespond_NonMonotonic() public {
        bytes[] memory data = new bytes[](trap.MIN_SAMPLES());
        data[0] = collectHelper(100, false);
        data[data.length - 1] = collectHelper(200, false);
        for (uint i = 1; i < data.length - 1; i++) {
            data[i] = collectHelper(150, false);
        }

        (bool should, bytes memory reason) = trap.shouldRespond(data);
        assertFalse(should);
        assertEq(reason, "non_monotonic");
    }

    function test_ShouldNotRespond_TotalThresholdNotMet() public {
        bytes[] memory data = new bytes[](trap.MIN_SAMPLES());
        uint256 count = 0;
        for (uint i = 0; i < trap.MIN_SAMPLES(); i++) {
            data[trap.MIN_SAMPLES() - 1 - i] = collectHelper(count, false);
            count += 1; 
        }

        (bool should, ) = trap.shouldRespond(data);
        assertFalse(should);
    }

    function test_ShouldNotRespond_StreakNotMet() public {
        bytes[] memory data = new bytes[](trap.MIN_SAMPLES());
        uint256 count = 0;
        uint256 total_threshold = trap.TOTAL_THRESHOLD();
        uint256 min_samples = trap.MIN_SAMPLES();

        for (uint i = 0; i < min_samples; i++) {
            data[min_samples - 1 - i] = collectHelper(count, false);
            if (i % 2 == 0) {
                count += (total_threshold / min_samples) + 1; 
            } else {
                count += 1; 
            }
        }

        (bool should, ) = trap.shouldRespond(data);
        assertFalse(should);
    }

    function test_ShouldRespond_ConditionsMet() public {
        bytes[] memory data = new bytes[](trap.MIN_SAMPLES());
        uint256 count = 0;
        uint256 per_interval_min = 6;

        for (uint i = 0; i < trap.MIN_SAMPLES(); i++) {
            data[trap.MIN_SAMPLES() - 1 - i] = collectHelper(count, false);
            count += per_interval_min;
        }

        (bool should, bytes memory payload) = trap.shouldRespond(data);
        assertTrue(should, "Trap should respond");

        (uint256 totalIncrease, uint256 longestStreak, uint256 bigIntervals) = abi.decode(payload, (uint256, uint256, uint256));

        assertEq(totalIncrease, per_interval_min * (trap.MIN_SAMPLES() - 1));
        assertEq(longestStreak, trap.MIN_SAMPLES() - 1);
        assertEq(bigIntervals, trap.MIN_SAMPLES() - 1);
    }

    function test_FullFlow_TriggerAndPause() public {
        bytes[] memory data = new bytes[](trap.MIN_SAMPLES());
        uint256 count = 0;
        for (uint i = 0; i < trap.MIN_SAMPLES(); i++) {
            for(uint j=count; j>0; j--){
                bridge.withdraw();
            }
            data[trap.MIN_SAMPLES() - 1 - i] = trap.collect();
            count = trap.PER_INTERVAL_MIN() * (i + 1);
        }

        (bool should, ) = trap.shouldRespond(data);
        assertTrue(should, "Trap should have triggered a response");

        vm.prank(DROSERA_EXECUTOR);
        response.pause();

        assertTrue(bridge.paused(), "Bridge should be paused after response");

        vm.expectRevert(bytes("Contract is paused"));
        bridge.withdraw();
    }

    function test_Response_Unauthorized() public {
        vm.expectRevert(bytes("unauthorized"));
        response.pause();
    }
}