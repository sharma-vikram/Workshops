// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Oracle} from "../../src/Oracle.sol";

/**
 * @title OracleStep1Test
 * @notice Tests for Step 1 - Contract Structure and Node Management
 * 
 * Run with: forge test --match-contract OracleStep1Test -vvv
 */
contract OracleStep1Test is Test {
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

    // ============ CONSTRUCTOR TESTS ============

    function test_ConstructorSetsOwner() public view {
        assertEq(oracle.owner(), owner, "Owner should be the deployer");
    }

    // ============ QUORUM TESTS ============

    function test_GetQuorumWithZeroNodes() public view {
        // With 0 nodes, quorum should be minimum (3)
        assertEq(oracle.getQuorum(), 3, "Quorum with 0 nodes should be 3");
    }

    function test_GetQuorumWithOneNode() public {
        vm.prank(node1);
        oracle.addNode();
        
        assertEq(oracle.getQuorum(), 3, "Quorum with 1 node should be 3");
    }

    function test_GetQuorumWithTwoNodes() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        
        assertEq(oracle.getQuorum(), 3, "Quorum with 2 nodes should be 3");
    }

    function test_GetQuorumWithThreeNodes() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();
        
        // With 3 nodes: ceil(3 * 2/3) = 2
        assertEq(oracle.getQuorum(), 2, "Quorum with 3 nodes should be 2 (66%)");
    }

    function test_GetQuorumWithFourNodes() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();
        vm.prank(node4);
        oracle.addNode();
        
        // With 4 nodes: ceil(4 * 2/3) = 3
        assertEq(oracle.getQuorum(), 3, "Quorum with 4 nodes should be 3 (66% rounded up)");
    }

    // ============ ADD NODE TESTS ============

    function test_AddNodeSetsNodeAsValid() public {
        vm.prank(node1);
        oracle.addNode();

        assertTrue(oracle.isNode(node1), "Node1 should be registered");
        assertEq(oracle.nodes(0), node1, "Node1 should be at index 0");
    }

    function test_AddNodeMultipleNodes() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        assertTrue(oracle.isNode(node1), "Node1 should be registered");
        assertTrue(oracle.isNode(node2), "Node2 should be registered");
        assertTrue(oracle.isNode(node3), "Node3 should be registered");
        
        assertEq(oracle.nodes(0), node1, "Node1 should be at index 0");
        assertEq(oracle.nodes(1), node2, "Node2 should be at index 1");
        assertEq(oracle.nodes(2), node3, "Node3 should be at index 2");
    }

    function test_AddNodeRevertsIfNodeAlreadyExists() public {
        vm.prank(node1);
        oracle.addNode();

        vm.prank(node1);
        vm.expectRevert("Node already exists");
        oracle.addNode();
    }

    // ============ REMOVE NODE TESTS ============

    function test_RemoveNodeRemovesNode() public {
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();

        assertTrue(oracle.isNode(node1), "Node1 should be registered initially");

        vm.prank(node1);
        oracle.removeNode();

        assertFalse(oracle.isNode(node1), "Node1 should no longer be registered");
    }

    function test_RemoveNodeRevertsIfNodeDoesNotExist() public {
        vm.prank(node1);
        vm.expectRevert("Node does not exist");
        oracle.removeNode();
    }

    function test_RemoveNodeSwapsWithLastElement() public {
        // Add 3 nodes
        vm.prank(node1);
        oracle.addNode();
        vm.prank(node2);
        oracle.addNode();
        vm.prank(node3);
        oracle.addNode();

        // Remove node1 (at index 0)
        vm.prank(node1);
        oracle.removeNode();

        // Node3 (last) should now be at index 0
        assertEq(oracle.nodes(0), node3, "Node3 should be swapped to index 0");
        assertEq(oracle.nodes(1), node2, "Node2 should still be at index 1");
        
        // Verify node1 is no longer registered
        assertFalse(oracle.isNode(node1), "Node1 should no longer be registered");
    }
}

