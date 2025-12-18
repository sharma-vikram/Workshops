# Solidity Essentials to Create an Oracle

## Introduction

**Solidity** is a **programming language** specifically **designed for developing smart contracts on the Ethereum blockchain**. Understanding Solidity is crucial for creating **oracles**. Here's a summary of the key Solidity concepts you'll need to know.

## Contracts

- **Contracts**: The building blocks of Ethereum smart contracts.
  - [Solidity by Example - Hello World](https://solidity-by-example.org/hello-world/)

## Data Types and State Variables

- **Data Types**: Essential types include `uint`, `address`, `string`, and `bool`.
  - [Solidity by Example - Data Types](https://solidity-by-example.org/primitives/)
- **State Variables**: Hold data across function calls, stored on the blockchain.
  - [Solidity by Example - Variables](https://solidity-by-example.org/variables/)

## Visibility Modifiers

- **public**: Can be accessed internally and externally.
- **internal**: Accessible only within the contract and derived contracts.
- **external**: Can be called from outside the contract.
- **private**: Accessible only within the contract.
  - [Solidity by Example - Visibility](https://solidity-by-example.org/visibility/)

## Data Locations

- **Storage**: Persistent data stored on the blockchain.
- **Memory**: Temporary data stored during function execution.
- **Stack**: Local variables stored in function execution context.
  - [Solidity by Example - Data Locations](https://solidity-by-example.org/data-locations/)

## Mappings

Mappings are key-value stores essential for oracles:

```solidity
// Simple mapping
mapping(address => bool) public isNode;

// Nested mapping (used for tracking submissions)
mapping(string => mapping(uint256 => mapping(address => uint256))) public nodePrices;
```

- [Solidity by Example - Mapping](https://solidity-by-example.org/mapping/)

## Structs

Structs allow you to group related data:

```solidity
struct Round {
    uint256 id;
    uint256 totalSubmissionCount;
    uint256 lastUpdatedAt;
}
```

- [Solidity by Example - Struct](https://solidity-by-example.org/structs/)

## Arrays

Dynamic arrays are useful for storing lists of nodes:

```solidity
address[] public nodes;

// Add to array
nodes.push(msg.sender);

// Remove last element
nodes.pop();
```

- [Solidity by Example - Array](https://solidity-by-example.org/array/)

## Functions

- **Functions**: Code blocks within contracts that execute specific tasks.
  - [Solidity by Example - Functions](https://solidity-by-example.org/function/)

### Function Visibility

```solidity
// Anyone can call this
function addNode() public { }

// Only this contract can call this
function _finalizePrice(string memory coin) internal { }

// Read-only function, doesn't modify state
function getQuorum() public view returns (uint256) { }
```

## Constructor

- The constructor initializes contract variables when the contract is deployed.
  - [Solidity by Example - Constructor](https://solidity-by-example.org/constructor/)

```solidity
constructor() {
    owner = msg.sender;
}
```

## Events

Events are crucial for oracles - they notify external applications (like our frontend) when prices are updated:

```solidity
// Declare the event
event PriceUpdated(string indexed coin, uint256 price, uint256 roundId);

// Emit the event
emit PriceUpdated("ethereum", 350000000000, 1);
```

The `indexed` keyword allows filtering events by that parameter.

- [Solidity by Example - Events](https://solidity-by-example.org/events/)

## Error Handling

Use `require` to validate conditions and revert with helpful messages:

```solidity
require(isNode[msg.sender], "Not a node");
require(!hasSubmitted[coin][roundId][msg.sender], "Already submitted for this round");
```

- [Solidity by Example - Error Handling](https://solidity-by-example.org/error/)

## Loops

Loops are needed to iterate over nodes and calculate averages:

```solidity
for (uint256 i = 0; i < nodes.length; i++) {
    address node = nodes[i];
    // Do something with each node
}
```

- [Solidity by Example - Loop](https://solidity-by-example.org/loop/)

## Block Properties

Access blockchain information like timestamps:

```solidity
// Current block timestamp (seconds since Unix epoch)
uint256 timestamp = block.timestamp;

// Current block number
uint256 blockNum = block.number;
```

- [Solidity by Example - Block and Transaction](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#block-and-transaction-properties)

## msg Object

Information about the current transaction:

```solidity
// Address that called the function
address caller = msg.sender;

// ETH sent with the transaction
uint256 value = msg.value;
```

## Units

- **Units**: Ether and Wei are the primary units of Ethereum. 1 ether = 10^18 wei.
  - [Solidity by Example - Units](https://solidity-by-example.org/ether-units/)

For price oracles, we often use custom precision (e.g., 8 decimals):
```solidity
// Price $50,000.25 stored as 5000025000000 (50000.25 * 10^8)
uint256 price = 5000025000000;
```

## Solidity by Example

- To find more examples of practical Solidity implementations, explore [Solidity by Example](https://solidity-by-example.org/).

## Conclusion

Mastering these Solidity essentials will empower you to create your own oracle with confidence and understanding. Dive into the documentation, experiment with code, and explore real-world examples to solidify your knowledge.

## Back to the workshop

[Jump !](../README.md)
