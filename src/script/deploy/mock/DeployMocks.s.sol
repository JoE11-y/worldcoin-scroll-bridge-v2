// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script} from "forge-std/Script.sol";
import {MockWorldIDIdentityManager} from "src/mocks/MockWorldIDIdentityManager.sol";
import {ScrollWorldID} from "src/ScrollWorldID.sol";
import {ScrollStateBridge} from "src/ScrollStateBridge.sol";
import {MockL1ScrollMessenger} from "src/mocks/MockL1ScrollMessenger.sol";
import {MockL2ScrollMessenger} from "src/mocks/MockL2ScrollMessenger.sol";

/// @title Mock State Bridge deployment script
/// @notice forge script to deploy MockStateBridge.sol
/// @author Worldcoin
/// @dev Can be executed by running `make mock` or `make local-mock`.
contract DeployMockStateBridge is Script {
    ScrollStateBridge public mockStateBridge;
    MockWorldIDIdentityManager public mockWorldID;
    ScrollWorldID public mockBridgedWorldID;
    MockL1ScrollMessenger public l1Messenger;
    MockL2ScrollMessenger public l2Messenger;

    address public owner;

    uint8 public treeDepth;

    uint256 public initialRoot;

    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////
    string public root = vm.projectRoot();
    string public path = string.concat(root, "/src/script/.deploy-config.json");
    string public json = vm.readFile(path);

    uint256 public privateKey = abi.decode(vm.parseJson(json, ".privateKey"), (uint256));

    function run() public {
        vm.startBroadcast(privateKey);

        treeDepth = uint8(30);

        initialRoot = uint256(0x111);

        mockWorldID = new MockWorldIDIdentityManager(initialRoot);

        l2Messenger = new MockL2ScrollMessenger();

        l1Messenger = new MockL1ScrollMessenger(address(l2Messenger));

        mockBridgedWorldID = new ScrollWorldID(treeDepth, address(l2Messenger));

        mockStateBridge = new ScrollStateBridge(
            address(mockWorldID), address(mockBridgedWorldID), address(l1Messenger)
        );

        vm.stopBroadcast();
    }
}
