// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IScrollMessenger} from "@scroll-tech/contracts/libraries/IScrollMessenger.sol";
import {IL2ScrollMessenger} from "@scroll-tech/contracts/L2/IL2ScrollMessenger.sol";

contract MockL1ScrollMessenger is IScrollMessenger {
    address private messageSender;
    IL2ScrollMessenger private l2Messenger;
    uint256 private nonce;

    /// @notice Emitted when a cross domain message is sent.
    /// @param sender The address of the sender who initiates the message.
    /// @param target The address of target contract to call.
    /// @param value The amount of value passed to the target contract.
    /// @param messageNonce The nonce of the message.
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    /// @param message The calldata passed to the target contract.
    event SentMessage(
        address indexed sender,
        address indexed target,
        uint256 value,
        uint256 messageNonce,
        uint256 gasLimit,
        bytes message
    );

    /// @notice Emitted when a cross domain message is relayed successfully.
    /// @param messageHash The hash of the message.
    event RelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is failed to relay.
    /// @param messageHash The hash of the message.
    event FailedRelayedMessage(bytes32 indexed messageHash);

    constructor(address _l2Messenger) {
        l2Messenger = IL2ScrollMessenger(_l2Messenger);
    }

    /**
     *
     * Public View Functions *
     *
     */

    /// @notice Return the sender of a cross domain message.
    function xDomainMessageSender() external view returns (address) {
        return messageSender;
    }

    function sendMessage(address target, uint256 value, bytes calldata message, uint256 gasLimit)
        external
        override
    {
        // set message sender as xDomainMessageSender
        messageSender = msg.sender;
        // Simulate sending a message to L2 messenger
        l2Messenger.relayMessage(messageSender, target, value, nonce, message);
        // increment message nonce
        nonce++;
        emit SentMessage(msg.sender, address, value, nonce, gasLimit, message);
    }

    function sendMessage(
        address target,
        uint256 value,
        bytes calldata message,
        uint256 gasLimit,
        address refundAddress
    ) external override {
        // set message sender as xDomainMessageSender
        messageSender = msg.sender;
        // Simulate sending a message to L2 messenger
        l2Messenger.relayMessage(messageSender, target, value, nonce, message);
        // increment nonce
        nonce++;
        emit SentMessage(msg.sender, address, value, nonce, gasLimit, message);
    }
}
