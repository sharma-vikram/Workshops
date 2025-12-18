// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Oracle} from "../../src/Oracle.sol";

/**
 * @title OracleStep3Test
 * @notice Tests for Step 3 - Price Submission and Aggregation
 * 
 * Run with: forge test --match-contract OracleStep3Test -vvv
 */
contract OracleStep3Test is Test {
    Oracle public oracle;
    address public owner;
    address public node1;
    address public node2;
    address public node3;
    address public node4;

    function setUp() public {
        owner = address(this);
        node1 = makeAddr("node1");
        node2 = makeAddr("node2");
        node3 = makeAddr("node3");
        node4 = makeAddr("node4");

        oracle = new Oracle();
    }

    // ============ SUBMIT PRICE ACCESS CONTROL ============

    function test_SubmitPriceRevertsIfNotNode() public {
        vm.prank(node1);
        vm.expectRevert("Not a node");
        oracle.submitPrice("BTC", 50000);
    }

    function test_SubmitPriceRevertsOnDoubleSubmission() public {
        // Add node1 as a valid node
        vm.prank(node1);
        oracle.addNode();

        // First submission should succeed
        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        // Second submission should fail
        vm.prank(node1);
        vm.expectRevert("Already submitted for this round");
        oracle.submitPrice("BTC", 51000);
    }

    // ============ PRICE STORAGE TESTS ============

    function test_SubmitPriceStoresNodePrice() public {
        vm.prank(node1);
        oracle.addNode();

        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        uint256 storedPrice = oracle.nodePrices("BTC", 0, node1);
        assertEq(storedPrice, 50000, "Stored price should match submitted price");

        assertTrue(oracle.hasSubmitted("BTC", 0, node1), "hasSubmitted should be true");
    }

    function test_SubmissionCountIncrementsCorrectly() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        (, uint256 count, ) = oracle.rounds("BTC");
        assertEq(count, 1, "Submission count should be 1");

        vm.prank(node2);
        oracle.submitPrice("BTC", 51000);

        // With 3 nodes, quorum = 2, so after 2nd submission, round resets
        (, count, ) = oracle.rounds("BTC");
        assertEq(count, 0, "Submission count should reset after quorum");
    }

    // ============ QUORUM AND FINALIZATION TESTS ============

    function test_QuorumFinalizesPrice() public {
        // Add 3 nodes (quorum = 2)
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        assertEq(oracle.getQuorum(), 2, "Quorum should be 2 with 3 nodes");

        // Submit prices from 2 nodes (reaches quorum)
        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        vm.prank(node2);
        oracle.submitPrice("BTC", 51000);

        // Check that price was finalized (average: 50500)
        uint256 finalPrice = oracle.currentPrices("BTC");
        assertEq(finalPrice, 50500, "Final price should be average of submissions");
    }

    function test_PartialSubmissionsDoNotFinalizePrice() public {
        // With 4 nodes, quorum = 3
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();
        vm.prank(node4);
        oracle.addNode();

        assertEq(oracle.getQuorum(), 3, "Quorum should be 3 with 4 nodes");

        // Only 2 submissions (quorum is 3)
        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        vm.prank(node2);
        oracle.submitPrice("BTC", 51000);

        // Price should not be finalized
        uint256 finalPrice = oracle.currentPrices("BTC");
        assertEq(finalPrice, 0, "Price should not be finalized before quorum");
    }

    // ============ EVENT EMISSION TESTS ============

    function test_QuorumEmitsPriceUpdatedEvent() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        // With 3 nodes, quorum = 2, so 2nd submission triggers event
        vm.expectEmit(true, false, false, true);
        emit Oracle.PriceUpdated("BTC", 50500, 0); // Average of 50000 and 51000

        vm.prank(node2);
        oracle.submitPrice("BTC", 51000);
    }

    // ============ ROUND PROGRESSION TESTS ============

    function test_RoundIncrementsAfterQuorum() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        // Round 0
        (uint256 roundId, , ) = oracle.rounds("BTC");
        assertEq(roundId, 0, "Initial round should be 0");

        // Submit to reach quorum
        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        vm.prank(node2);
        oracle.submitPrice("BTC", 51000);

        // Round should be incremented
        (roundId, , ) = oracle.rounds("BTC");
        assertEq(roundId, 1, "Round should increment to 1 after quorum");
    }

    function test_NodesCanSubmitInNewRound() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        // Round 0
        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);
        vm.prank(node2);
        oracle.submitPrice("BTC", 51000);

        // Now in Round 1 - nodes should be able to submit again
        vm.prank(node1);
        oracle.submitPrice("BTC", 60000);

        uint256 storedPrice = oracle.nodePrices("BTC", 1, node1);
        assertEq(storedPrice, 60000, "Node should be able to submit in new round");
    }

    // ============ MULTI-COIN TESTS ============

    function test_MultipleCoinsSeparateRounds() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        // Submit for BTC
        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);
        vm.prank(node2);
        oracle.submitPrice("BTC", 51000);

        // Submit for ETH
        vm.prank(node1);
        oracle.submitPrice("ETH", 3000);
        vm.prank(node2);
        oracle.submitPrice("ETH", 3100);

        // Check both prices
        assertEq(oracle.currentPrices("BTC"), 50500, "BTC price should be 50500");
        assertEq(oracle.currentPrices("ETH"), 3050, "ETH price should be 3050");
    }

    // ============ TIMESTAMP TESTS ============

    function test_LastUpdatedAtIsSet() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        // Warp time
        vm.warp(1000);

        vm.prank(node2);
        oracle.submitPrice("BTC", 51000);

        (, , uint256 lastUpdated) = oracle.rounds("BTC");
        assertEq(lastUpdated, 1000, "lastUpdatedAt should be set to block timestamp");
    }

    // ============ NODE REMOVAL EDGE CASES ============

    function test_RemovedNodeCannotSubmitPrice() public {
        vm.prank(node1);
        oracle.addNode();

        vm.prank(node1);
        oracle.submitPrice("BTC", 50000);

        vm.prank(node1);
        oracle.removeNode();

        vm.prank(node1);
        vm.expectRevert("Not a node");
        oracle.submitPrice("BTC", 51000);
    }
}

