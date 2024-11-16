// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/WorldIDSchemaHook.sol";
import {IWorldID} from "../src/interfaces/IWorldID.sol";
import {ISPHook} from "../lib/sign-protocol-evm/src/interfaces/ISPHook.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ByteHasher} from "../src/helpers/ByteHasher.sol";

/// @title MockWorldID
/// @notice A mock implementation of the IWorldID interface for testing purposes.
contract MockWorldID is IWorldID {
    bool public shouldVerifySucceed;

    /// @notice Sets the result of the verifyProof function.
    /// @param _shouldSucceed Whether the proof verification should succeed.
    function setVerifyProofResult(bool _shouldSucceed) external {
        shouldVerifySucceed = _shouldSucceed;
    }

    /// @notice Mocks the verifyProof function.
    /// @dev Reverts if shouldVerifySucceed is false to simulate a failed verification.
    function verifyProof(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[8] calldata
    ) external view override {
        if (!shouldVerifySucceed) {
            revert("Mock verification failed");
        }
        // Do nothing if shouldVerifySucceed is true (simulate successful verification)
    }
}

/// @title WorldIDSchemaHookTest
/// @notice A test suite for the WorldIDSchemaHook contract.
contract WorldIDSchemaHookTest is Test {
    using ByteHasher for bytes;

    WorldIDSchemaHook public hook;
    MockWorldID public mockWorldID;

    address public attester = address(0x1234);
    uint64 public schemaId = 1;
    uint64 public attestationId = 1;
    bytes public extraData;

    /// @notice Sets up the test environment before each test.
    function setUp() public {
        // Instantiate the mock WorldID contract
        mockWorldID = new MockWorldID();

        // Set up appId and actionId
        string memory appId = "test-app-id";
        string memory actionId = "test-action-id";

        // Instantiate the hook contract with the mockWorldID
        hook = new WorldIDSchemaHook(mockWorldID, appId, actionId);
    }

    /// @notice Tests that didReceiveAttestation succeeds when the proof is valid.
    function testDidReceiveAttestation_Success() public {
        // Set the mock to succeed
        mockWorldID.setVerifyProofResult(true);

        // Prepare the extraData
        uint256 root = 0;
        uint256 nullifierHash = 0;
        uint256[8] memory proof = [uint256(0), 0, 0, 0, 0, 0, 0, 0];

        extraData = abi.encode(root, nullifierHash, proof);

        // Call the function
        vm.prank(attester);
        hook.didReceiveAttestation(attester, schemaId, attestationId, extraData);

        // If no revert, the test passes
        assertTrue(true);
    }

    /// @notice Tests that didReceiveAttestation fails when the proof is invalid.
    function testDidReceiveAttestation_Failure() public {
        // Set the mock to fail
        mockWorldID.setVerifyProofResult(false);

        // Prepare the extraData
        uint256 root = 0;
        uint256 nullifierHash = 0;
        uint256[8] memory proof = [uint256(0), 0, 0, 0, 0, 0, 0, 0];

        extraData = abi.encode(root, nullifierHash, proof);

        // Expect revert with WorldIDVerificationFailed()
        vm.expectRevert(WorldIDSchemaHook.WorldIDVerificationFailed.selector);

        vm.prank(attester);
        hook.didReceiveAttestation(attester, schemaId, attestationId, extraData);
    }

    /// @notice Tests that unsupported didReceiveAttestation overload reverts.
    function testDidReceiveAttestation_UnsupportedOperation() public {
        IERC20 token = IERC20(address(0));
        uint256 amount = 0;
        bytes memory data = "";

        vm.expectRevert(bytes("UnsupportedOperation"));

        vm.prank(attester);
        hook.didReceiveAttestation(attester, schemaId, attestationId, token, amount, data);
    }

    /// @notice Tests that unsupported didReceiveRevocation (payable) reverts.
    function testDidReceiveRevocation_UnsupportedOperation_Payable() public {
        bytes memory data = "";

        vm.expectRevert(bytes("UnsupportedOperation"));

        vm.prank(attester);
        hook.didReceiveRevocation{value: 0}(attester, schemaId, attestationId, data);
    }

    /// @notice Tests that unsupported didReceiveRevocation overload reverts.
    function testDidReceiveRevocation_UnsupportedOperation() public {
        IERC20 token = IERC20(address(0));
        uint256 amount = 0;
        bytes memory data = "";

        vm.expectRevert(bytes("UnsupportedOperation"));

        vm.prank(attester);
        hook.didReceiveRevocation(attester, schemaId, attestationId, token, amount, data);
    }
}
