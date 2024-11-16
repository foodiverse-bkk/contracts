// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import Hyperlane's IMailbox interface
import {IMailbox} from "../lib/hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";

// Import IERC20 interface for ERC20 token interactions
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract AttestationDispatcher {
    // Hyperlane mailbox instance
    IMailbox public mailbox;

    // Destination chain ID and address of CrossChainAttestor
    uint32 public destinationChainId;
    bytes32 public crossChainAttestorAddress;

    // Events
    event AttestationDispatched(uint256 action, bytes message);

    constructor(
        IMailbox _mailbox,
        uint32 _destinationChainId,
        address _crossChainAttestorAddress
    ) {
        mailbox = _mailbox;
        destinationChainId = _destinationChainId;
        crossChainAttestorAddress = bytes32(uint256(uint160(_crossChainAttestorAddress)));
    }

    // Function to dispatch attestation without resolver fees
    function dispatchAttestation(
        uint256 action, // Action code (0, 1, or 2)
        bytes calldata attestationData
    ) external payable {
        // Prepare the message
        bytes memory message = abi.encode(action, attestationData);

        // Dispatch the message via Hyperlane
        mailbox.dispatch(
            destinationChainId,
            crossChainAttestorAddress,
            message
        );

        emit AttestationDispatched(action, message);
    }
}
