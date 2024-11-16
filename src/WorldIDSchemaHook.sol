// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ISPHook } from "../lib/sign-protocol-evm/src/interfaces/ISPHook.sol";
import { ISP } from "../lib/sign-protocol-evm/src/interfaces/ISP.sol";
import { Attestation } from "../lib/sign-protocol-evm/src/models/Attestation.sol";
import { IWorldID } from "../src/interfaces/IWorldID.sol";
import { ByteHasher } from "../src/helpers/ByteHasher.sol";
import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract WorldIDSchemaHook is ISPHook {
    using ByteHasher for bytes;

    ////////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                  ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when World ID verification fails
    error WorldIDVerificationFailed();

    ////////////////////////////////////////////////////////////////////////////////
    ///                              STATE VARIABLES                             ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @dev The World ID instance for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The external nullifier for the contract
    uint256 internal immutable externalNullifier;

    /// @dev The World ID group ID (Orb-verified users)
    uint256 internal constant groupId = 1;

    ////////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTOR                                ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @param _worldId The World ID contract instance
    /// @param _appId The World ID app ID (obtained during registration)
    /// @param _actionId The World ID action ID (unique identifier for the action)
    constructor(
        IWorldID _worldId,
        string memory _appId,
        string memory _actionId
    ) {
        worldId = _worldId;
        externalNullifier = abi
        .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
        .hashToField();
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                          ISPHook Implementation                          ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Called when an attestation is received
    /// @param attester The address attempting to create the attestation
    /// @param schemaId The schema ID of the attestation
    /// @param attestationId The attestation ID
    /// @param extraData Encoded World ID verification parameters (root, nullifierHash, proof)
    function didReceiveAttestation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        bytes calldata extraData
    ) external payable override {
        // Decode extraData to extract World ID verification parameters
        (
            uint256 root,
            uint256 nullifierHash,
            uint256[8] memory proof
        ) = abi.decode(extraData, (uint256, uint256, uint256[8]));

        // Perform World ID verification
        try
            worldId.verifyProof(
                root,
                groupId,
                abi.encodePacked(attester).hashToField(),
                nullifierHash,
                externalNullifier,
                proof
            )
        {} catch {
            revert WorldIDVerificationFailed();
        }

        // Optionally, you can perform additional logic here
        // For example, emit an event or update state
    }

    /// @notice Revert unsupported operations for other ISPHook functions
    function didReceiveAttestation(
        address,
        uint64,
        uint64,
        IERC20,
        uint256,
        bytes calldata
    ) external pure override {
        revert("UnsupportedOperation");
    }

    function didReceiveRevocation(
        address,
        uint64,
        uint64,
        bytes calldata
    ) external payable override {
        revert("UnsupportedOperation");
    }

    function didReceiveRevocation(
        address,
        uint64,
        uint64,
        IERC20,
        uint256,
        bytes calldata
    ) external pure override {
        revert("UnsupportedOperation");
    }
}
