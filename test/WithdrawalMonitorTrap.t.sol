// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WithdrawalMonitorTrap} from "../src/WithdrawalMonitorTrap.sol";
import {Response} from "../src/Response.sol";
import {MockMonitoredBridge} from "../src/mock/MockMonitoredBridge.sol";
import {IMonitoredBridge} from "../src/interfaces/IMonitoredBridge.sol";

contract WithdrawalMonitorTrapTest is Test {
    WithdrawalMonitorTrap internal trap;
    MockMonitoredBridge internal bridge;
    Response internal response;

    // This is the hardcoded address from `WithdrawalMonitorTrap.sol`.
    // We use it here to ensure our test environment mirrors the trap's expectation.
    address private constant HARDCODED_BRIDGE_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

    function setUp() public {
        // 1. Deploy the MockMonitoredBridge code to the *exact* hardcoded address
        // that the WithdrawalMonitorTrap expects. This is crucial for the test.
        vm.etch(HARDCODED_BRIDGE_ADDRESS, address(new MockMonitoredBridge()).code);
        bridge = MockMonitoredBridge(HARDCODED_BRIDGE_ADDRESS);

        // 2. Deploy the Response contract, linking it to our mock bridge.
        response = new Response(address(bridge));

        // 3. Deploy the trap. It will automatically point to the hardcoded bridge address.
        trap = new WithdrawalMonitorTrap();
    }

    function test_ShouldNotRespond_WhenThresholdNotCrossed() public {
        // Simulate a Drosera node collecting data.
        bytes[] memory data = new bytes[](2);
        data[0] = trap.collect(); // Withdrawal count = 0

        // Simulate 5 withdrawals, which is below the threshold of 10.
        for (uint256 i = 0; i < 5; i++) {
            bridge.withdraw();
        }

        data[1] = trap.collect(); // Withdrawal count = 5

        // Check if the trap would respond.
        (bool should, ) = trap.shouldRespond(data);

        assertFalse(should, "Trap should not respond when threshold is not crossed");
    }

    function test_ShouldRespond_WhenThresholdIsMet() public {
        bytes[] memory data = new bytes[](2);
        data[0] = trap.collect(); // Withdrawal count = 0

        // Simulate 10 withdrawals, meeting the threshold.
        uint256 threshold = trap.WITHDRAWAL_THRESHOLD();
        for (uint256 i = 0; i < threshold; i++) {
            bridge.withdraw();
        }

        data[1] = trap.collect(); // Withdrawal count = 10

        (bool should, ) = trap.shouldRespond(data);

        assertTrue(should, "Trap should respond when threshold is met");
    }

    function test_FullFlow_TriggerAndPause() public {
        // --- This test simulates the entire Drosera flow ---

        // 1. Drosera node collects initial state.
        bytes[] memory data = new bytes[](2);
        data[0] = trap.collect();

        // 2. Activity occurs on-chain (10 withdrawals).
        uint256 threshold = trap.WITHDRAWAL_THRESHOLD();
        for (uint256 i = 0; i < threshold; i++) {
            bridge.withdraw();
        }

        // 3. Drosera node collects the new state.
        data[1] = trap.collect();

        // 4. Drosera node checks if a response is warranted.
        (bool should, ) = trap.shouldRespond(data);
        assertTrue(should, "Trap should have triggered a response");

        // 5. Drosera node executes the response on the Response contract.
        // We simulate this by directly calling the `pause` function.
        response.pause();

        // --- Verification ---

        // Check that the bridge is now paused.
        assertTrue(bridge.paused(), "Bridge should be paused after response");

        // Verify that withdrawals fail now that the contract is paused.
        vm.expectRevert(bytes("Contract is paused"));
        bridge.withdraw();
    }
}
