// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IScrollMessenger} from "@scroll-tech/contracts/libraries/IScrollMessenger.sol";
import {IRootHistory} from "../interfaces/IRootHistory.sol";
import {IWorldIDIdentityManager} from "../interfaces/IWorldIDIdentityManager.sol";
import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";

contract MockScrollStateBridge is Ownable2Step {
    /// @notice The address of the ScrollWorldID contract
    address public immutable scrollWorldIDAddress;

    /// @notice address for the Scroll Messenger contract on Ethereum
    address internal immutable scrollMessengerAddress;

    /// @notice Ethereum World ID Identity Manager Address
    address public immutable worldIDAddress;

    /// @notice Amount of gas purchased on Scroll for propagateRoot
    uint32 internal _gasLimitPropagateRoot;

    /// @notice The default gas limit amount to buy on Scroll
    uint32 public constant DEFAULT_SCROLL_GAS_LIMIT = 268000;

    /// @notice Emitted when the StateBridge sends a root to the ScrollWorldID contract
    /// @param root The root sent to the ScrollWorldID contract on Scroll
    event RootPropagated(uint256 root);

    /// @notice Emitted when an attempt is made to set an address to zero
    error AddressZero();

    event RootSentToL2(bytes32 indexed root);

    /// @notice constructor
    /// @param _worldIDIdentityManager Deployment address of the WorldID Identity Manager contract
    /// @param _scrollWorldIDAddress Address of the Scroll contract that will receive the new root and timestamp
    /// @param _scrollMessengerAddress Scroll Messenger address on Ethereum
    /// @custom:revert if any of the constructor params addresses are zero
    constructor(
        address _worldIDIdentityManager,
        address _scrollWorldIDAddress,
        address _scrollMessengerAddress
    ) {
        if (
            _worldIDIdentityManager == address(0) || _scrollWorldIDAddress == address(0)
                || _scrollMessengerAddress == address(0)
        ) {
            revert AddressZero();
        }

        scrollWorldIDAddress = _scrollWorldIDAddress;
        worldIDAddress = _worldIDIdentityManager;
        scrollMessengerAddress = _scrollMessengerAddress;
        _gasLimitPropagateRoot = DEFAULT_SCROLL_GAS_LIMIT;
    }

    function propagateRoot(address _refundAddress) external payable {
        uint256 latestRoot = IWorldIDIdentityManager(worldIDAddress).latestRoot();
        uint256 value = 0; // receive root is not a payable function.

        IScrollMessenger(scrollMessengerAddress).sendMessage{value: msg.value}(
            // World ID contract address on Scroll
            scrollWorldIDAddress,
            //value
            value,
            //message
            abi.encodeWithSignature("receiveRoot(uint256)", uint256(latestRoot)),
            // gas limit
            _gasLimitPropagateRoot,
            // refund address
            _refundAddress
        );

        emit RootPropagated(latestRoot);
    }
}
