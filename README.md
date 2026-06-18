# ChainLuck

A decentralized lottery smart contract built in **Solidity** using the **Foundry** development framework.  
This project lets users participate in a lottery on an Ethereum-compatible blockchain and selects a random winner — showcasing key Web3 concepts like randomness, testing, and deployment.

🧠 How It Works

This contract accepts lottery entries and picks a random winner using on-chain randomness oracles (e.g., Chainlink VRF). The winner receives the pooled funds while fees/commissions (if any) can be retained per contract logic.

## 🚀 Features

- 🔐 Secure and gas-efficient Solidity contract
- 🚀 Lottery smart contract written in Solidity
- 🧪 Comprehensive unit & integration tests with Foundry
- 🛠️ Deployable on local Anvil, testnets, or mainnet
- 💡 Implements key patterns needed for on-chain randomness
- 📦 Sample scripts for deployment & testing
- 📁 Clean, production-ready repository structure

---

## 🧱 Tech Stack

| Layer           | Technology                                               |
| --------------- | -------------------------------------------------------- |
| Smart Contracts | Solidity ^0.8.x                                          |
| Framework       | Foundry (Forge, Anvil, Cast)                             |
| Randomness      | Chainlink VRF (or mock implementation for local testing) |
| Testing         | Forge test suite                                         |
| Tooling         | Git, Makefile                                            |
| Network Support | Localhost, Ethereum Testnets                             |

---

## 📁 Repository Structure

📦 Smart-contract-lottery \
├── 📂 .github/… \
├── 📂 broadcast/ \
├── 📂 lib/ \
├── 📂 script/ \
| └── _.s.sol \
├── 📂 src/ \
│ └── _.sol \
├── 📂 test/ \
│ └── \_.t.sol \
├── 📜 .gitignore \
├── 📜 Makefile \
├── 📜 foundry.toml \
└── 📜 README.md

## 🛠️ Tech Stack

| Technology                 | Purpose                                |
| -------------------------- | -------------------------------------- |
| **Solidity**               | Smart contracts                        |
| **Foundry (Forge & Cast)** | Local development, testing, deployment |
| **OpenZeppelin Contracts** | Secure base ERC20 & utilities          |
| **Chainlink Price Feeds**  | Reliable on-chain market data          |

---

## 🧩 Prerequisites

Make sure you have the following installed:

- **Git** — version control
- **Foundry** (with `forge` & `anvil`) — smart contract development toolkit
- **Node.js & npm** (optional, for scripts / integration)
- ETH wallet & testnet funds for real deployment

---

## ⚡️ Quick Start

Clone the repository:

```bash
git clone https://github.com/1khushibarnwal/Smart-contract-lottery.git
cd Smart-contract-lottery
```

Install Foundry dependencies and build:

```bash
forge install
forge build
```

---

## 🧪 Local Development & Testing

Start a local node (Anvil):

```bash
anvil
```

Run Tests:

```bash
forge test
```

Run Tests With Verbosity:

```bash
forge test -vvv
```

Deploy to local:

```bash
forge script script/DeployRaffle.s.sol --fork-url http://localhost:8545 --broadcast
```

---

## 📦 Deployment

💡 Configure Environment Variables

Create a .env file based on .env.example and set:

```bash
RPC_URL=<Your_RPC_URL>
PRIVATE_KEY=<Your_Private_Key>
```

📤 Deploy to Testnet:

```bash
forge script script/DeployRaffle.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## 📈 Running Tests

Foundry tests cover unit logic and integration:

```bash
forge test --fork-url $RPC_URL
```

To generate coverage report:

```bash
forge coverage
```

---

🧠 Contract Logic Overview

1. Users enter the lottery by sending ETH.

2. Entries are recorded on-chain.

3. At predefined intervals or conditions:
   - A randomness request is triggered.

   - A winner is selected in a trust-minimized manner.

4. The winner receives the entire prize pool.

5. Contract state resets for the next round.

✔️ No centralized authority
✔️ Verifiable randomness
✔️ Transparent execution

## 🔒 Security Considerations

- Reentrancy-safe payout logic

- Strict state transitions

- Deterministic testing using mocks

- Uses Solidity ^0.8.x overflow protections

❗ This project is not audited. Do not use in production with real funds.
