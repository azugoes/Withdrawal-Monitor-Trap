// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMonitoredBridge} from "./interfaces/IMonitoredBridge.sol";

/// @title Response
/// @notice This contract executes the action when a trap is triggered.
contract Response {
    address public immutable guardian;
    IMonitoredBridge public immutable bridge;

    /// @param bridgeAddress The address of the bridge contract to interact with.
    constructor(address _guardian, address bridgeAddress) {
        guardian = _guardian;
        bridge = IMonitoredBridge(bridgeAddress);
    }

    /// @notice Calls the pause function on the monitored bridge contract.
    function pause() external {
        require(msg.sender == guardian, "unauthorized");
        bridge.pause();
    }
}
