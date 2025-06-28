# FlashLoan-Arbitrage-Bot_multi-Arbitrage
---

# 📌 FlashLoan Arbitrage Bot

This is a **Solidity smart contract** that implements a configurable arbitrage strategy using **Aave V3 Flash Loans** and swaps through **Uniswap V3** and **PancakeSwap V2 & V3** liquidity pools.
The goal is to borrow a token with no upfront capital, perform multi-hop swaps between DEXs, capture price inefficiencies, and repay the loan in the same transaction, pocketing the profit.

---

## 🚀 Features

✅ **Aave V3 Flash Loans** — Borrow tokens instantly without collateral.

✅ **Supports multiple swap paths** — Uniswap V3 ➜ Pancake V2, Pancake V3 ➜ Pancake V2, V2 ➜ V3, V3 ➜ V3, V2 ➜ V2.

✅ **Configurable routers** — Easily update router addresses for Uniswap and PancakeSwap.

✅ **Owner withdraw & balance check** — Recover stuck funds and check balances safely.

✅ **Fully on-chain arbitrage loop** — All operations (loan, swaps, repayment) happen atomically.

---

## ⚙️ Architecture

**Contracts Used:**

* **FlashLoanSimpleReceiverBase** — Aave’s base for flash loan receivers.
* **ISwapRouter** — For Uniswap V3 swaps.
* **IPancakeRouter02** — For PancakeSwap V2 swaps.

**Workflow:**

1. Request a flash loan for a token (`token1`).
2. Perform one or more swaps across Uniswap V3 & PancakeSwap to exploit price differences.
3. Repay Aave with premium in the same transaction.
4. If profit remains, send it to the contract owner.

---

## 🔑 Main Variables

| Name             | Purpose                                              |
| ---------------- | ---------------------------------------------------- |
| `token1`         | The borrowed asset                                   |
| `token2`         | The intermediate swap token                          |
| `fee1`, `fee2`   | Uniswap V3 fee tiers (e.g., 500, 3000)               |
| `uniswapRouter3` | Uniswap V3 router address                            |
| `pancake2`       | PancakeSwap V2 router address                        |
| `pancake3`       | PancakeSwap V3 router address                        |
| `OutMin3`        | Minimum output for swaps to protect against slippage |
| `time`           | Swap deadline buffer                                 |
| `owner`          | Contract owner                                       |

---

## ⚡️ Supported Swap Modes

The arbitrage logic supports multiple swap modes, passed via the `mode` parameter:

| Mode | Route                   |
| ---- | ----------------------- |
| `1`  | Uniswap V3 ➜ Pancake V3 |
| `2`  | Uniswap V3 ➜ Uniswap V3 |
| `3`  | Pancake V3 ➜ Uniswap V3 |
| `4`  | Pancake V3 ➜ Pancake V3 |
| `5`  | Pancake V3 ➜ Pancake V2 |
| `6`  | Pancake V2 ➜ Pancake V3 |
| `7`  | Pancake V2 ➜ Pancake V2 |
| `8`  | Uniswap V3 ➜ Pancake V2 |
| `9`  | Pancake V2 ➜ Uniswap V3 |

---

## 📜 Main Functions

### 📍 Flash Loan

```solidity
fn_RequestFlashLoan(address _token1, address _token2, uint256 _amount, uint24 _fee1, uint24 _fee2, uint8 _mode)
```

* Starts the flash loan and arbitrage process.

### 📍 Core Execution

```solidity
executeOperation(...)
```

* Callback function called by Aave after lending. Handles all swaps & repayment.

---

## 🔄 Internal Swap Helpers

* `swap_v3_v3()`: Swap between Uniswap V3 / Pancake V3 pools.
* `swap_v3_v2()`: Uniswap/Pancake V3 ➜ Pancake V2.
* `swap_v2_v3()`: Pancake V2 ➜ Uniswap/Pancake V3.
* `swap_v2_v2()`: Pancake V2 ➜ Pancake V2.

---

## 🔐 Owner-Only Functions

* `withdraw(address _tokenAddress)`: Withdraw any ERC20 stuck in contract.
* `withdra_networktoken(uint256 _amount, address payable _to)`: Withdraw native chain tokens (BNB, ETH).
* `getBalance(address _token)`: Check ERC20 balance.
* `getBalance_networktoken()`: Check native token balance.
* `C_OutMin3()`, `C_uniswapRouter3()`, `C_pancake2()`, `C_pancake3()`, `C_aave()`: Update contract configuration.

---

## ⚠️ Security & Warnings

* **Highly risky** — Arbitrage relies on rapid execution and precise liquidity.
* **Reentrancy protection** — This version does not implement reentrancy guards. Consider adding `ReentrancyGuard` from OpenZeppelin.
* **Slippage** — Always set `OutMin3` carefully to prevent sandwich attacks.
* **Test thoroughly** — Run tests with mainnet fork and simulate realistic pool conditions.
* **MEV** — Front-running risk exists; use private mempool or Flashbots.

---

## ✅ Deployment Example

```solidity
constructor(address _AAVE) 
  FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_AAVE)) { 
  owner = payable(msg.sender);
  ...
}
```

* Pass Aave PoolAddressesProvider address for your chain.
* Update router addresses for your target DEXes.

---

## 🛡️ Requirements

* Solidity `^0.8.10`
* Aave V3 deployed on your network
* Uniswap V3 and PancakeSwap routers on target network
* Sufficient liquidity for the arbitrage pair

---

## ⚡️ Example Use

```solidity
fn_RequestFlashLoan(
  0x...WETH,
  0x...USDC,
  10 ether,
  500,   // fee1 for Uniswap V3
  3000,  // fee2 for Pancake V3
  1      // Mode: Uniswap V3 ➜ Pancake V3
);
```

---

## 📚 Disclaimer

This contract is for **educational & research** purposes. Use at your own risk. Improper use may cause **loss of funds**.

