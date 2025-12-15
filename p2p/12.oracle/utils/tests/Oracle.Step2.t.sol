// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Oracle} from "../../src/Oracle.sol";

/**
 * @title OracleStep2Test
 * @notice Tests for Step 2 - Round System and Data Structures
 * 
 * Run with: forge test --match-contract OracleStep2Test -vvv
 */
contract OracleStep2Test is Test {
    Oracle public oracle;
    address public owner;
    address public node1;
    address public node2;
    address public node3;

    function setUp() public {
        owner = address(this);
        node1 = makeAddr("node1");
        node2 = makeAddr("node2");
        node3 = makeAddr("node3");

        oracle = new Oracle();
    }

    // ============ ROUND STRUCT TESTS ============

    function test_RoundInitialValues() public view {
        // Get round info for a coin that hasn't been used
        (uint256 id, uint256 totalSubmissionCount, uint256 lastUpdatedAt) = oracle.rounds("BTC");
        
        assertEq(id, 0, "Initial round ID should be 0");
        assertEq(totalSubmissionCount, 0, "Initial submission count should be 0");
        assertEq(lastUpdatedAt, 0, "Initial lastUpdatedAt should be 0");
    }

    function test_RoundIndependentPerCoin() public view {
        // Rounds for different coins should be independent
        (uint256 btcId, , ) = oracle.rounds("BTC");
        (uint256 ethId, , ) = oracle.rounds("ETH");
        (uint256 solId, , ) = oracle.rounds("SOL");
        
        assertEq(btcId, 0, "BTC round ID should be 0");
        assertEq(ethId, 0, "ETH round ID should be 0");
        assertEq(solId, 0, "SOL round ID should be 0");
    }

    // ============ MAPPINGS TESTS ============

    function test_NodePricesMappingExists() public view {
        // Just checking the mapping exists and returns default value
        uint256 price = oracle.nodePrices("BTC", 0, node1);
        assertEq(price, 0, "Default node price should be 0");
    }

    function test_HasSubmittedMappingExists() public view {
        // Just checking the mapping exists and returns default value
        bool submitted = oracle.hasSubmitted("BTC", 0, node1);
        assertFalse(submitted, "Default hasSubmitted should be false");
    }

    function test_CurrentPricesMappingExists() public view {
        // Just checking the mapping exists and returns default value
        uint256 price = oracle.currentPrices("BTC");
        assertEq(price, 0, "Default current price should be 0");
    }

    // ============ STATE VARIABLE ORDER TEST ============

    function test_StateVariablesExist() public {
        // Test that all required state variables exist
        // These calls will fail compilation if variables are missing
        
        oracle.owner();
        oracle.currentPrices("BTC");
        oracle.rounds("BTC");
        oracle.nodePrices("BTC", 0, address(this));
        oracle.hasSubmitted("BTC", 0, address(this));
        
        // Add a node first to test nodes array
        vm.prank(node1);
        oracle.addNode();
        oracle.nodes(0);
    }
}

