// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {WorldIDBridge} from "src/abstract/WorldIDBridge.sol";
import {SemaphoreTreeDepthValidator} from "src/utils/SemaphoreTreeDepthValidator.sol";
import {SemaphoreVerifier} from "src/SemaphoreVerifier.sol";
import {ScrollCrossDomainOwnable} from "src/ScrollCrossDomainOwnable.sol";

/// @title ScrollWorldID Mock
/// @author Worldcoin
/// @notice Mock of ScrollWorldId in order to test functionality on a local chain
/// @custom:deployment deployed through make local-mock
contract ScrollWorldID is WorldIDBridge, ScrollCrossDomainOwnable {
    ///////////////////////////////////////////////////////////////////////////////
    ///                                CONSTRUCTION                             ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Initializes the contract the depth of the associated merkle tree.
    ///
    /// @param _treeDepth The depth of the WorldID Semaphore merkle tree.
    /// @param _l2Messenger The address of the L2Messenger.
    constructor(uint8 _treeDepth, address _l2Messenger)
        WorldIDBridge(_treeDepth)
        ScrollCrossDomainOwnable(_l2Messenger)
    {}

    ///////////////////////////////////////////////////////////////////////////////
    ///                               ROOT MIRRORING                            ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice This function is called by the state bridge contract when it forwards a new root to
    ///         the bridged WorldID.
    ///
    /// @param newRoot The value of the new root.
    ///
    /// @custom:reverts CannotOverwriteRoot If the root already exists in the root history.
    /// @custom:reverts string If the caller is not the owner.
    function receiveRoot(uint256 newRoot) public virtual onlyOwner {
        _receiveRoot(newRoot);
    }
}
