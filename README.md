# Smart Contract Lottery

A decentralized lottery smart contract built in **Solidity** using the **Foundry** development framework.  
This project lets users participate in a lottery on an Ethereum-compatible blockchain and selects a random winner — showcasing key Web3 concepts like randomness, testing, and deployment.

🧠 How It Works

This contract accepts lottery entries and picks a random winner using on-chain randomness oracles (e.g., Chainlink VRF). The winner receives the pooled funds while fees/commissions (if any) can be retained per contract logic.

## 🚀 Features

- 🚀 Lottery smart contract written in Solidity
- 🧪 Tested with Foundry
- 🛠️ Deployable on local Anvil, testnets, or mainnet
- 💡 Implements key patterns needed for on-chain randomness
- 📦 Sample scripts for deployment & testing

---

## 📁 Repository Structure

📦 Smart-contract-lottery \
├── 📂 .github/… \
├── 📂 broadcast/ \
├── 📂 lib/ \
├── 📂 script/ \
├── 📂 src/ \
│ └── _.sol \
├── 📂 test/ \
│ └── _.t.sol \
├── 📜 .gitignore \
├── 📜 Makefile \
├── 📜 foundry.toml \
└── 📜 README.md

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
forge build
```

## 🧪 Local Development

Start a local node (Anvil):

```bash
anvil
```

Deploy to local:

```bash
forge script script/DeployRaffle.s.sol --fork-url http://localhost:8545 --broadcast
```

Run tests:

```bash
forge test
```

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
