// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";

import {ScrollStateBridge} from "src/ScrollStateBridge.sol";
import {ScrollWorldID} from "src/ScrollWorldID.sol";
import {MockL1ScrollMessenger} from "src/mocks/MockL1ScrollMessenger.sol";
import {MockL2ScrollMessenger} from "src/mocks/MockL2ScrollMessenger.sol";
import {MockWorldIDIdentityManager} from "src/mocks/MockWorldIDIdentityManager.sol";

contract L1ToL2CrossChainTest is PRBTest, StdCheats {
    MockWorldIDIdentityManager public mockWorldIDIdentityManager;
    ScrollStateBridge public scrollStateBridge;
    MockL1ScrollMessenger public l1Messenger;
    MockL2ScrollMessenger public l2Messenger;
    ScrollWorldID public scrollWorldID;
    address public owner;

    function setUp() public {
        uint256 initialRoot = uint256(0x111);
        uint8 sampleDepth = uint8(30);

        // Deploy the Mock WorldIdentityManager, that provides the root
        mockWorldIDIdentityManager = new MockWorldIDIdentityManager(initialRoot);

        // Deploy the L2 Messenger (used by both L1 and L2)
        l2Messenger = new MockL2ScrollMessenger();

        // Deploy the L2 World ID contract (with cross-domain ownership)
        scrollWorldID = new ScrollWorldID(sampleDepth, address(l2Messenger));

        // Deploy the L1 Messenger, which will interact with the L2 Messenger
        l1Messenger = new MockL1ScrollMessenger(address(l2Messenger));

        // Deploy the L1 State Bridge (which will send the message to L2)
        scrollStateBridge = new ScrollStateBridge(
            address(mockWorldIDIdentityManager), address(scrollWorldID), address(l1Messenger)
        );

        owner = scrollStateBridge.owner();
    }

    modifier ownershipTransferred() {
        vm.prank(owner);
        // transfer ownership to the scroll State bridge
        address oldOwner = scrollWorldID.owner();
        address newOwner = address(scrollStateBridge);
        bool isLocal = false;
        scrollWorldID.transferOwnership(newOwner, isLocal);
        assertEq(scrollWorldID.owner(), address(scrollStateBridge));
        _;
    }

    function testPropagateRoot() public ownershipTransferred {
        uint256 root = mockWorldIDIdentityManager.latestRoot();
        // Send the root from the L1 State Bridge contract
        vm.prank(owner); // Simulating the owner of the contract calling this
        scrollStateBridge.propagateRoot(owner);
        // Verify that the root was correctly set in the L2 ScrollWorldID contract
        assertEq(scrollWorldID.latestRoot(), root);
    }

    function testSetRootHistoryExpiry(uint256 _rootHistoryExpiry) public ownershipTransferred {
        vm.assume(_rootHistoryExpiry != 0);
        vm.prank(owner);
        scrollStateBridge.setRootHistoryExpiry(_rootHistoryExpiry, owner);
        // Verify that the owner was correctly set in the L2 ScrollWorldID contract
        assertEq(scrollWorldID.rootHistoryExpiry(), _rootHistoryExpiry);
    }

    function testTransferOwnershipScroll(address newOwner) public ownershipTransferred {
        vm.assume(newOwner != address(0));
        vm.prank(owner);
        scrollStateBridge.transferOwnershipScroll(newOwner, owner, true);
        // Verify that the owner was correctly set in the L2 ScrollWorldID contract
        assertEq(scrollWorldID.owner(), newOwner);
    }

    function testOnlyL2MessengerCanCallWorldID() public ownershipTransferred {
        // Ensure that only the L2 messenger can interact with ScrollWorldID

        // Attempt to call the ScrollWorldID contract as an unauthorized address
        vm.prank(owner); // Owner tries to call receiveRoot directly (should fail)
        uint256 fakeRoot = uint256(0x1138296);
        vm.expectRevert("ScrollCrossDomainOwnable: caller is not the messenger");
        scrollWorldID.receiveRoot(fakeRoot);
    }
}
