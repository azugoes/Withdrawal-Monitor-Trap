# Withdrawal Monitor Trap

This project contains a Drosera-based security trap designed to protect a bridge-like dApp on the Ethereum Hoodi Network. I've built it to be a simple, streamlined, and reactive security layer.

The core idea is to monitor a target contract for an unusually high frequency of withdrawals. If more than a specified number of withdrawals occur within a set time window, the trap triggers a response to mitigate a potential attack, such as pausing the monitored contract.

## How It Works

The system is composed of three main on-chain components and one configuration file:

1.  **`WithdrawalMonitorTrap.sol`**: This is the main, stateless Drosera trap contract.
    *   `collect()`: This function is called periodically by a Drosera node. It retrieves the current withdrawal count from the `MockMonitoredBridge` contract.
    *   `shouldRespond()`: This function receives data from multiple `collect()` calls. It compares the withdrawal counts between two points in time to see if the number of withdrawals has exceeded `WITHDRAWAL_THRESHOLD`. If it has, it returns `true` and encodes the necessary data for the response.

2.  **`Response.sol`**: This is the action contract. When the trap is triggered, Drosera calls a function on this contract. In this implementation, it calls the `pause()` function on the `MockMonitoredBridge` to halt its operations.

3.  **`MockMonitoredBridge.sol`**: This is a mock contract that simulates the bridge or vault we are protecting. For testing and demonstration purposes, it includes a `withdraw()` function that increments a counter and a `pause()` function that can be called by the `Response` contract.

4.  **`drosera.toml`**: This is the configuration file for the Drosera node. It specifies which contract is the trap, which function on the `Response` contract to call, and other operational parameters.

### On-Chain Logic Flow

1.  A Drosera node, guided by `drosera.toml`, periodically calls the `collect()` function on a deployed `WithdrawalMonitorTrap` contract.
2.  `collect()` fetches the current `withdrawalCount` from the `MockMonitoredBridge` contract and returns it.
3.  The Drosera node gathers this data over time and passes an array of these results to the `shouldRespond()` function.
4.  `shouldRespond()` checks if the difference in `withdrawalCount` between the first and last data point surpasses the `WITHDRAWAL_THRESHOLD`.
5.  If the threshold is crossed, `shouldRespond()` returns `true`.
6.  The Drosera node then executes the specified function call—in this case, `pause()`—on the `Response` contract, which in turn pauses the bridge.

## Testing

To ensure everything works as expected, you can run the test suite using Foundry. The tests simulate the interaction between the trap, the mock bridge, and the response contract.

```bash
forge test
```

This project is ready to be pushed to a GitHub repository.