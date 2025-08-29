# Deployment Process

This guide outlines the steps to deploy the Withdrawal Monitor Trap system on the Ethereum Hoodi Network.

### Prerequisites

1.  **Foundry:** Ensure you have Foundry installed and configured.
2.  **Drosera CLI:** Ensure you have the `drosera` CLI tool installed.
3.  **Environment Variables:** Set the following environment variables for deployment. You can add them to a `.env` file.
    ```
    ETH_RPC_URL=<your_hoodi_network_rpc_url>
    PRIVATE_KEY=<your_deployer_private_key>
    ```

---

### Step 1: Deploy the Mock Bridge Contract

First, deploy the `MockMonitoredBridge` contract. This is the contract our trap will watch.

Run the following command:

```bash
forge create --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY src/mock/MockMonitoredBridge.sol:MockMonitoredBridge
```

After deployment, **copy the `Deployed to:` address**. This will be your `BRIDGE_ADDRESS`.

### Step 2: Deploy the Response Contract

Next, deploy the `Response` contract. This contract will be called by the Drosera node to pause the bridge. It requires the `BRIDGE_ADDRESS` from the previous step as a constructor argument.

Run the following command, replacing `<BRIDGE_ADDRESS>` with the address you copied:

```bash
forge create --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY src/Response.sol:Response --constructor-args <BRIDGE_ADDRESS>
```

After deployment, **copy the `Deployed to:` address**. This will be your `RESPONSE_ADDRESS`.

### Step 3: Hardcode the Bridge Address in the Trap

Open the `src/WithdrawalMonitorTrap.sol` file and update the `MONITORED_BRIDGE` constant with your `BRIDGE_ADDRESS`.

**Change this:**
```solidity
IMonitoredBridge public constant MONITORED_BRIDGE = IMonitoredBridge(0x5FbDB2315678afecb367f032d93F642f64180aa3);
```

**To this (example):**
```solidity
IMonitoredBridge public constant MONITORED_BRIDGE = IMonitoredBridge(0x...); // Paste your BRIDGE_ADDRESS here
```

### Step 4: Update `drosera.toml`

Update the `drosera.toml` configuration file with the path to the compiled trap and the details of your `Response` contract.

-   Set `response_contract_address` to your `RESPONSE_ADDRESS`.
-   The `trap_file_path` and `response_function_signature` have been pre-filled for you.

Your `[response]` section should look like this:

```toml
[response]
# The address of the contract to call when the trap is triggered
response_contract_address = "0x..." # Paste your RESPONSE_ADDRESS here
# The function to call on the response contract
response_function_signature = "pause()"
```

### Step 5: Deploy the Trap via Drosera CLI

With all the contracts deployed and configurations set, you can now deploy the main trap contract using the Drosera CLI.

Run the following command:

```bash
drosera trap deploy
```

The Drosera network will now begin monitoring your bridge contract according to the logic in your trap.
