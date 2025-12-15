# Workshop - Create a Decentralized Price Oracle 🔮

✔ 📖 Understand what an Oracle is and why it matters

✔ 🛠️ Build your own decentralized price Oracle smart contract

✔ 🚀 Deploy it locally with Anvil and test it with a real frontend

✔ 🔗 Run Oracle nodes that fetch real crypto prices from CoinGecko

## Introduction

### What is a Blockchain Oracle? 🤔

An **Oracle** is a bridge between the blockchain and the outside world. Smart contracts are powerful, but they have one fundamental limitation: **they cannot access external data on their own**.

Think about it:
- How can a DeFi protocol know the current price of ETH?
- How can an insurance smart contract know if a flight was delayed?
- How can a betting contract know who won a sports match?

**Oracles solve this problem** by bringing off-chain data on-chain in a trustworthy way.

### The Oracle Problem ⚠️

The challenge is: **how do we trust the data?**

If only one source provides the data, that source becomes a central point of failure. If it's hacked or malicious, the entire system is compromised.

### The Solution: Decentralized Oracles 🌐

Instead of trusting a single source, we use **multiple independent nodes** that:
1. Each fetch data from external sources
2. Submit their data to the smart contract
3. The contract **aggregates** the submissions (average, median, etc.)
4. Only publishes the result when a **quorum** is reached

### What We'll Build 🏗️

```
┌─────────────────────────────────────────────────────────────────────┐
│                          ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────┐     ┌──────────┐     ┌──────────┐                   │
│   │  Node 1  │     │  Node 2  │     │  Node 3  │     ...           │
│   │ (Go App) │     │ (Go App) │     │ (Go App) │                   │
│   └────┬─────┘     └────┬─────┘     └────┬─────┘                   │
│        │                │                │                          │
│        │  CoinGecko     │                │                          │
│        │    API         │                │                          │
│        ▼                ▼                ▼                          │
│   ┌─────────────────────────────────────────────────────────┐      │
│   │                   ORACLE CONTRACT                        │      │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │      │
│   │  │ submitPrice │  │  getQuorum  │  │currentPrices│     │      │
│   │  └─────────────┘  └─────────────┘  └─────────────┘     │      │
│   │                                                          │      │
│   │              When quorum reached:                        │      │
│   │              emit PriceUpdated(coin, avgPrice, roundId) │      │
│   └──────────────────────────┬──────────────────────────────┘      │
│                              │                                      │
│                              ▼                                      │
│                    ┌──────────────────┐                            │
│                    │    FRONTEND      │                            │
│                    │  (Next.js App)   │                            │
│                    │                  │                            │
│                    │  Listens for     │                            │
│                    │  PriceUpdated    │                            │
│                    │  events          │                            │
│                    └──────────────────┘                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Real-World Examples 🌍

| Oracle | Use Case |
|--------|----------|
| **Chainlink** | DeFi price feeds, VRF (randomness), Any API |
| **Pyth Network** | High-frequency trading data |
| **Band Protocol** | Cross-chain data oracle |
| **API3** | First-party oracles |

Our workshop will help you understand how these systems work under the hood!

---

## Step 0 - Setup 💻

Please refer to the [SETUP.md](./tuto/SETUP.md) file to install Foundry.

If you need a Solidity refresher, check out [Solidity.md](./tuto/Solidity.md).

### Preparing the Workshop Files

Navigate to the `oracle` folder:

```bash
cd oracle
```

📂 Your project structure should look like:

```
7.create_an_oracle/
├── oracle/
│   ├── foundry.toml
│   ├── lib/
│   │   └── forge-std/
│   ├── script/                 # Deployment script will be copied here
│   ├── src/
│   │   └── Oracle.sol          # Your implementation (start here!)
│   └── test/                   # Test files will be copied here
└── utils/
    ├── Oracle.script.sol       # Deployment script to copy
    └── tests/                  # Test files to copy step by step
        ├── Oracle.Step1.t.sol
        ├── Oracle.Step2.t.sol
        └── Oracle.Step3.t.sol
```

> 💡 You'll create the `Oracle.sol` file from scratch and implement it step by step!  
> ❓ **If you're stuck or have questions, ask the workshop supervisor.**

---

## Step 1 - Contract Structure and Node Management 👥

### 📑 **Description**

In this first step, you will create the foundation of your Oracle contract. This includes:
- The basic contract structure
- State variables to track nodes and prices
- Functions for nodes to register and unregister themselves
- A dynamic quorum calculation system

### 📌 **Tasks**

#### 1.1 - Create the Contract Base

Open `src/Oracle.sol` and create a basic Solidity contract named `Oracle`.

> 💡 Don't forget the SPDX license identifier and the pragma statement for Solidity version `^0.8.13`.

#### 1.2 - Add State Variables

Your contract needs to store important information. Add the following **public** state variables in this exact order:

| Variable | Type | Purpose |
|----------|------|---------|
| `owner` | `address` | Stores who deployed the contract |
| `nodes` | `address[]` | A dynamic array containing all registered node addresses |
| `isNode` | `mapping(address => bool)` | Quick lookup to check if an address is a registered node |
| `currentPrices` | `mapping(string => uint256)` | Stores the finalized price for each coin (key = coin name like "ethereum") |

> 📚 **Learn about:** [State Variables](https://docs.soliditylang.org/en/latest/structure-of-a-contract.html#state-variables), [Mappings](https://docs.soliditylang.org/en/latest/types.html#mapping-types), [Arrays](https://docs.soliditylang.org/en/latest/types.html#arrays)

#### 1.3 - Create the Constructor

Add a constructor that initializes the `owner` variable to the address that deploys the contract.

> 💡 The deployer's address is available via `msg.sender`.

#### 1.4 - Implement the Quorum Function

The **quorum** determines how many nodes must submit prices before a price is finalized. This ensures decentralization.

Create a function with these specifications:

| Function | `getQuorum` |
|----------|-------------|
| **Visibility** | `public view` |
| **Parameters** | none |
| **Returns** | `uint256` |

**Logic to implement:**
- If there are fewer than 3 registered nodes, always return `3` (minimum security threshold)
- Otherwise, calculate 66% of the total nodes using ceiling division
- Formula hint: `(nodeCount * 2 + 2) / 3` gives you the ceiling of 2/3

#### 1.5 - Implement Node Registration

Create a function that allows anyone to register as an Oracle node.

| Function | `addNode` |
|----------|-----------|
| **Visibility** | `public` |
| **Parameters** | none |
| **Returns** | nothing |

**What it should do:**
1. Verify the caller is not already a node (revert with `"Node already exists"` if they are)
2. Mark the caller as a node in the `isNode` mapping
3. Add the caller's address to the `nodes` array

> 📚 **Learn about:** [Require Statements](https://docs.soliditylang.org/en/latest/control-structures.html#require)

#### 1.6 - Implement Node Removal

Create a function that allows nodes to unregister themselves.

| Function | `removeNode` |
|----------|--------------|
| **Visibility** | `public` |
| **Parameters** | none |
| **Returns** | nothing |

**What it should do:**
1. Verify the caller IS a registered node (revert with `"Node does not exist"` if not)
2. Remove the node from the `isNode` mapping
3. Remove the caller's address from the `nodes` array

> 💡 **Tip:** Removing from an array in Solidity is tricky. The efficient pattern is:
> 1. Find the element's index
> 2. Swap it with the last element
> 3. Pop the last element
> This avoids shifting all elements, saving gas!

### ✔️ **Validation**

Copy the test file to your test folder:

```bash
cp ../utils/tests/Oracle.Step1.t.sol test/Oracle.Step1.t.sol
```

Run the tests:

```bash
forge test --match-contract OracleStep1Test -vvv
```

All 12 tests should pass! ✅

### 📚 **Documentation**

- [State Variables](https://docs.soliditylang.org/en/latest/structure-of-a-contract.html#state-variables)
- [Mappings](https://docs.soliditylang.org/en/latest/types.html#mapping-types)
- [Arrays](https://docs.soliditylang.org/en/latest/types.html#arrays)
- [Require Statements](https://docs.soliditylang.org/en/latest/control-structures.html#require)

---

## Step 2 - Round System and Data Structures 📊

### 📑 **Description**

An oracle needs to organize price submissions into **rounds**. Each round:
- Collects submissions from multiple nodes
- Tracks how many nodes have submitted
- Records when the price was last updated

This prevents nodes from voting multiple times and organizes the consensus process.

### 📌 **Tasks**

#### 2.1 - Create the Round Struct

Create a struct named `Round` with three `uint256` fields:
- `id`: The current round number (starts at 0)
- `totalSubmissionCount`: How many nodes have submitted in this round
- `lastUpdatedAt`: Timestamp of the last price finalization

> 📚 **Learn about:** [Structs](https://docs.soliditylang.org/en/latest/types.html#structs)

#### 2.2 - Add Round and Submission Tracking Variables

Add three new mappings to track rounds and submissions. **Important:** Add these variables **after** `isNode` but **before** `currentPrices` to maintain proper storage layout.

| Variable | Type | Purpose |
|----------|------|---------|
| `rounds` | `mapping(string => Round)` | Stores round info for each coin |
| `nodePrices` | `mapping(string => mapping(uint256 => mapping(address => uint256)))` | Nested mapping: `coin → roundId → nodeAddress → submittedPrice` |
| `hasSubmitted` | `mapping(string => mapping(uint256 => mapping(address => bool)))` | Nested mapping: `coin → roundId → nodeAddress → hasVoted` |

> 💡 The nested mappings allow us to track which node submitted what price for which coin in which round.

> 📚 **Learn about:** [Nested Mappings](https://docs.soliditylang.org/en/latest/types.html#mapping-types)

#### 2.3 - Add the PriceUpdated Event

Events allow external applications (like our frontend) to be notified when something happens on-chain.

Declare an event named `PriceUpdated` with:
- `coin` (string, **indexed**): The cryptocurrency name
- `price` (uint256): The finalized price
- `roundId` (uint256): Which round this price was finalized in

> 💡 The `indexed` keyword allows filtering events by that parameter.

> 📚 **Learn about:** [Events](https://docs.soliditylang.org/en/latest/contracts.html#events)

### ✔️ **Validation**

Copy the test file to your test folder:

```bash
cp ../utils/tests/Oracle.Step2.t.sol test/Oracle.Step2.t.sol
```

Run the tests:

```bash
forge test --match-contract OracleStep2Test -vvv
```

All 6 tests should pass! ✅

### 📚 **Documentation**

- [Structs](https://docs.soliditylang.org/en/latest/types.html#structs)
- [Nested Mappings](https://docs.soliditylang.org/en/latest/types.html#mapping-types)
- [Events](https://docs.soliditylang.org/en/latest/contracts.html#events)

---

## Step 3 - Price Submission and Aggregation 💰

### 📑 **Description**

This is the core logic of the Oracle! Nodes submit prices, and when enough nodes agree (quorum is reached), the contract:
1. Calculates the average price from all submissions
2. Emits an event to notify listeners
3. Moves to the next round

### 📌 **Tasks**

#### 3.1 - Implement the Submit Price Function

Create the main function that nodes call to submit their price data.

| Function | `submitPrice` |
|----------|---------------|
| **Visibility** | `public` |
| **Parameters** | `string memory coin`, `uint256 price` |
| **Returns** | nothing |

**Logic to implement (in order):**

1. **Access Control**: Verify the caller is a registered node. If not, revert with message `"Not a node"`.

2. **Get Round Info**: Retrieve the current round ID for this coin from your rounds mapping.

3. **Prevent Double Voting**: Check if this node has already submitted for this coin in this round. If yes, revert with message `"Already submitted for this round"`.

4. **Store the Price**: Save the submitted price in the `nodePrices` mapping using the coin, current round, and sender's address as keys.

5. **Mark as Submitted**: Update the `hasSubmitted` mapping to prevent this node from voting again this round.

6. **Increment Counter**: Increase the `totalSubmissionCount` for this coin's current round.

7. **Check Quorum**: If the submission count is now greater than or equal to `getQuorum()`, call the internal `_finalizePrice` function.

#### 3.2 - Implement the Finalize Price Function

Create an internal function that calculates the average price and finalizes the round.

| Function | `_finalizePrice` |
|----------|------------------|
| **Visibility** | `internal` |
| **Parameters** | `string memory coin`, `uint256 roundId` |
| **Returns** | nothing |

**Logic to implement:**

1. **Initialize Counters**: Create two local variables to track the total price sum and the count of valid submissions.

2. **Aggregate Prices**: Loop through all nodes in the `nodes` array:
   - For each node, check if they submitted for this coin/round
   - If yes, add their submitted price to your running total
   - Increment your valid submission counter

3. **Calculate & Store Average**: If at least one valid submission exists:
   - Calculate the average price (total divided by count)
   - Store it in `currentPrices` for this coin

4. **Emit Event**: Emit the `PriceUpdated` event with the coin name, calculated average, and round ID.

5. **Prepare Next Round**:
   - Increment the round ID in the rounds mapping
   - Reset the submission count to 0
   - Update `lastUpdatedAt` to the current block timestamp

> 💡 Use `block.timestamp` to get the current time.

> 📚 **Learn about:** [Loops](https://docs.soliditylang.org/en/latest/control-structures.html#for), [Block Properties](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#block-and-transaction-properties)

### ✔️ **Validation**

Copy the test file to your test folder:

```bash
cp ../utils/tests/Oracle.Step3.t.sol test/Oracle.Step3.t.sol
```

Run all tests:

```bash
forge test -vvv
```

All 30 tests should pass! 🎉

**Congratulations!** Your Oracle contract is complete!

### 📚 **Documentation**

- [Functions](https://docs.soliditylang.org/en/latest/contracts.html#functions)
- [Block Properties](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#block-and-transaction-properties)
- [Loops](https://docs.soliditylang.org/en/latest/control-structures.html#for)

---

## Step 4 - Local Deployment with Anvil 🚀

### 📑 **Description**

Now that your contract is complete, let's deploy it locally using **Anvil** (Foundry's local Ethereum node) and interact with it!

### 📌 **Tasks**

#### 4.1 - Start Anvil

Open a **new terminal** and start Anvil:

```bash
anvil
```

You should see output like:

```
Available Accounts
==================
(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
(1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH)
...

Private Keys
==================
(0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
...

Listening on 127.0.0.1:8545
```

> ⚠️ **Keep this terminal open!** Anvil needs to run continuously.

#### 4.2 - Copy the Deployment Script

Before deploying, copy the deployment script to your project:

```bash
cp ../utils/Oracle.script.sol script/Oracle.sol
```

#### 4.3 - Deploy Your Contract

In a **new terminal**, navigate to the `oracle` folder and deploy:

```bash
cd oracle
forge script script/Oracle.sol:OracleScript \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

You should see:

```
== Return ==
oracle: contract Oracle 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

📝 **Save this contract address!** You'll need it for the frontend and nodes.

#### 4.4 - Verify Deployment

Test that your contract is working:

```bash
# Get the current quorum (should return 3 with 0 nodes)
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getQuorum()" --rpc-url http://localhost:8545
```

### 📚 **Documentation**

- [Anvil](https://book.getfoundry.sh/anvil/)
- [Forge Script](https://book.getfoundry.sh/forge/deploying)
- [Cast](https://book.getfoundry.sh/cast/)

---

## Step 5 - Launch the Frontend 🖥️

### 📑 **Description**

The frontend is a Next.js application that displays real-time prices from your Oracle. It listens for `PriceUpdated` events and updates automatically.

### 📌 **Tasks**

#### 5.1 - Configure the Frontend

Navigate to the frontend folder:

```bash
cd ../frontend
```

Create a `.env.local` file:

```bash
echo "NEXT_PUBLIC_ORACLE_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3" > .env.local
```

> ⚠️ Replace the address if your deployed contract has a different address!

#### 5.2 - Install Dependencies and Start

```bash
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

You should see the Oracle dashboard, but prices will be `$0.00` since no nodes have submitted prices yet.

<p align="center">
  <b>🖥️ Your Oracle Dashboard is running!</b>
</p>

---

## Step 6 - Run the Oracle Nodes 🔗

### 📑 **Description**

The Go application runs multiple Oracle nodes that:
1. Register themselves with the contract
2. Fetch real prices from CoinGecko API
3. Submit prices to the contract periodically
4. When quorum is reached, the contract emits `PriceUpdated` and the frontend updates!

### 📌 **Tasks**

#### 6.1 - Get a CoinGecko API Key

1. Go to [CoinGecko API](https://www.coingecko.com/en/api)
2. Sign up for a free account
3. Create a **Demo API Key**
4. Copy your API key

#### 6.2 - Configure the Node

Navigate to the Node folder:

```bash
cd ../Node
```

Create a `.env` file:

```bash
cat > .env << EOF
RPC_URL=http://127.0.0.1:8545
CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
COINGECKO_API_KEY=your_api_key_here
EOF
```

> ⚠️ Replace `your_api_key_here` with your actual CoinGecko API key!

#### 6.3 - Install Go Dependencies

```bash
go mod download
```

#### 6.4 - Generate Contract Bindings (if needed)

The `oracle_contract.go` file is already generated. If you need to regenerate it:

```bash
# Install abigen
go install github.com/ethereum/go-ethereum/cmd/abigen@latest

# Generate bindings
abigen --abi ../oracle/out/Oracle.sol/Oracle.json --pkg main --out oracle_contract.go
```

#### 6.5 - Run the Nodes

```bash
go run .
```

You should see output like:

```
========================================
Starting 4 Oracle Nodes (Sharing 3 API Keys)
========================================

[Node 0] Oracle Node initialized
[Node 0]   Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
[Node 0]   Contract: 0x5FbDB2315678afecb367f032d93F642f64180aa3
[Node 0] ⚠ Not registered. Requesting to join Oracle...
[Node 0] ✓ Successfully registered! Block: 2, Gas: 96547

[Node 0] Fetched ethereum: $3456.78
[Node 0] Submitting ethereum tx: 0x...
[Node 0] ✓ ethereum submitted! Block: 3, Gas: 89234
```

#### 6.6 - Watch the Magic! ✨

Go back to your browser at [http://localhost:3000](http://localhost:3000).

When the quorum (3 nodes by default) has submitted prices:
1. The contract calculates the **average price**
2. Emits a `PriceUpdated` event
3. The frontend receives the event and updates the displayed price!

You should see **toast notifications** appearing when prices are updated.

---

## Understanding the Complete Flow 🔄

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         COMPLETE FLOW                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. Node starts                                                          │
│     └─→ Checks if registered → If not, calls addNode()                  │
│                                                                          │
│  2. Node fetches price from CoinGecko                                   │
│     └─→ GET https://api.coingecko.com/api/v3/simple/price               │
│                                                                          │
│  3. Node submits price to contract                                      │
│     └─→ submitPrice("ethereum", 345678000000)                           │
│                                                                          │
│  4. Contract checks quorum                                              │
│     └─→ With 4 nodes, quorum = 3 (66% of 4 rounded up)                 │
│                                                                          │
│  5. When quorum reached                                                 │
│     └─→ Calculate average                                               │
│     └─→ Emit PriceUpdated event                                        │
│     └─→ Move to next round                                              │
│                                                                          │
│  6. Frontend receives event                                             │
│     └─→ Update displayed price                                          │
│     └─→ Show toast notification                                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Conclusion 🏁

Congratulations! 🎉 You've successfully built a **decentralized price Oracle** that:

- ✅ Allows nodes to register and unregister
- ✅ Collects price submissions from multiple sources
- ✅ Uses a dynamic quorum system (66% consensus)
- ✅ Aggregates prices into a trusted average
- ✅ Emits events for real-time frontend updates

### What You Learned

1. **Oracle Design Patterns** - How to aggregate off-chain data on-chain
2. **Quorum Mechanisms** - Ensuring decentralized consensus
3. **Event-Driven Architecture** - Smart contract to frontend communication

---

## To Go Further 🔼

Now that you understand the basics, here are some advanced topics to explore:

- 🔐 **Access Control**: Add admin functions to manage nodes
- 📈 **Median vs Average**: Implement median calculation for outlier resistance
- ⏱️ **Stale Data Protection**: Add checks for price freshness
- 💎 **Economic Incentives**: Require nodes to stake tokens
- 🔗 **Chainlink Integration**: Compare with [Chainlink Price Feeds](https://docs.chain.link/data-feeds)
- 🎲 **VRF (Verifiable Random Function)**: Build a random number oracle

---

## Authors 👋

| [<img src="https://github.com/L3yserEpitech.png" width=120><br><sub>Jules Lordet</sub>](https://github.com/L3yserEpitech) |
| :--------------------------------------------------------------------------------------------------------------------: |

<h2 align="center">Organization</h2>
<br/>
<p align='center'>
    <a href="https://www.linkedin.com/company/pocinnovation/mycompany/">
        <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn logo">
    </a>
    <a href="https://www.instagram.com/pocinnovation/">
        <img src="https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram logo">
    </a>
    <a href="https://twitter.com/PoCInnovation">
        <img src="https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white" alt="Twitter logo">
    </a>
    <a href="https://discord.com/invite/Yqq2ADGDS7">
        <img src="https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white" alt="Discord logo">
    </a>
</p>
<p align="center">
    <a href="https://www.poc-innovation.fr/">
        <img src="https://img.shields.io/badge/WebSite-1a2b6d?style=for-the-badge&logo=GitHub Sponsors&logoColor=white" alt="Website logo">
    </a>
</p>

> 🚀 Don't hesitate to follow us on our different platforms, and give a star 🌟 to PoC's repositories.

