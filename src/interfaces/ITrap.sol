// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ITrap
/// @notice The interface that all Drosera traps must implement.
interface ITrap {
    /// @notice Called by a Drosera node to collect data from the chain.
    /// @return A bytes array containing the collected data.
    function collect() external view returns (bytes memory);

    /// @notice Called by a Drosera node to determine if a response should be triggered.
    /// @param data An array of bytes arrays, each containing data from a `collect` call.
    /// @return A boolean indicating whether to respond and a bytes array for the response call.
    function shouldRespond(
        bytes[] calldata data
    ) external view returns (bool, bytes memory);
}
