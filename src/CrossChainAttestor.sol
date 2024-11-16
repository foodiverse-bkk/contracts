// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import Hyperlane's IMailbox interface
import {IMailbox} from "../lib/hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Import the Sign Protocol's interfaces
interface ISignProtocol {
    enum DataLocation { None, OnChain, OffChain }

    struct Attestation {
        uint64 schemaId;
        uint64 linkedAttestationId;
        uint64 attestTimestamp;
        uint64 revokeTimestamp;
        address attester;
        uint64 validUntil;
        DataLocation dataLocation;
        bool revoked;
        bytes[] recipients;
        bytes data;
    }

    function attest(
        Attestation calldata attestation,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    ) external payable returns (uint64);

    function attest(
        Attestation calldata attestation,
        uint256 resolverFeesETH,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    ) external payable returns (uint64);

    function attest(
        Attestation calldata attestation,
        IERC20 resolverFeesERC20Token,
        uint256 resolverFeesERC20Amount,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    ) external returns (uint64);
}

// Import IERC20 interface for ERC20 token interactions
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract CrossChainAttestor is Ownable {
    // Hyperlane mailbox instance
    IMailbox public mailbox;

    // Sign Protocol contract instance
    ISignProtocol public signProtocol;

    // Mapping to store allowed origin addresses (chain ID => sender address)
    mapping(uint32 => bytes32) public originAddresses;

    // Events
    event AttestationReceived(uint64 attestationId, string indexingKey);
    event InvalidAction(uint256 action);
    event InvalidOrigin(uint32 origin, bytes32 sender);

    // Modifiers
    modifier onlyMailbox() {
        require(msg.sender == address(mailbox), "Caller is not mailbox");
        _;
    }

    constructor(IMailbox _mailbox, ISignProtocol _signProtocol) Ownable(msg.sender) {
        mailbox = _mailbox;
        signProtocol = _signProtocol;
    }

    // Function to set allowed origin addresses
    function setOrigin(uint32 _origin, bytes32 _caller) external onlyOwner {
        originAddresses[_origin] = _caller;
    }

    // Hyperlane handle function to receive messages
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external onlyMailbox {
        // Verify the origin and sender
        if (originAddresses[_origin] != _sender) {
            emit InvalidOrigin(_origin, _sender);
            revert("Invalid origin or sender");
        }

        // Decode the message
        (uint256 action, bytes memory data) = abi.decode(_message, (uint256, bytes));

        // Process the action
        if (action == 0) {
            // Action 0: Receive attestation without resolver fees
            (
                uint64 schemaId,
                string memory contractDetails,
                address signer,
                string memory indexingKey,
                bytes memory extraData
            ) = abi.decode(data, (uint64, string, address, string, bytes));

            _receiveAttestationWithoutFees(
                schemaId,
                contractDetails,
                signer,
                indexingKey,
                extraData
            );
        } else if (action == 1) {
            // Action 1: Receive attestation with ETH resolver fees
            (
                uint64 schemaId,
                string memory contractDetails,
                address signer,
                uint256 resolverFeesETH,
                string memory indexingKey,
                bytes memory extraData
            ) = abi.decode(data, (uint64, string, address, uint256, string, bytes));

            _receiveAttestationWithETHFees(
                schemaId,
                contractDetails,
                signer,
                resolverFeesETH,
                indexingKey,
                extraData
            );
        } else if (action == 2) {
            // Action 2: Receive attestation with ERC20 resolver fees
            (
                uint64 schemaId,
                string memory contractDetails,
                address signer,
                address resolverFeesERC20Token,
                uint256 resolverFeesERC20Amount,
                string memory indexingKey,
                bytes memory extraData
            ) = abi.decode(data, (uint64, string, address, address, uint256, string, bytes));

            _receiveAttestationWithERC20Fees(
                schemaId,
                contractDetails,
                signer,
                IERC20(resolverFeesERC20Token),
                resolverFeesERC20Amount,
                indexingKey,
                extraData
            );
        } else {
            emit InvalidAction(action);
        }
    }

    // Internal function to process the attestation without fees
    function _receiveAttestationWithoutFees(
        uint64 schemaId,
        string memory contractDetails,
        address signer,
        string memory indexingKey,
        bytes memory extraData
    ) internal {
        // Encode the schema data
        bytes memory schemaData = abi.encode(contractDetails, signer);

        // Prepare the attestation struct
        ISignProtocol.Attestation memory attestation = ISignProtocol.Attestation({
            schemaId: schemaId,
            linkedAttestationId: 0, // Not linking to another attestation
            attestTimestamp: uint64(block.timestamp),
            revokeTimestamp: 0, // Not revoked
            attester: address(this), // This contract is the attester
            validUntil: 0, // No expiry
            dataLocation: ISignProtocol.DataLocation.OnChain,
            revoked: false,
            recipients: new bytes[](1),
            data: schemaData
        });

        // Set the recipient
        attestation.recipients[0] = abi.encodePacked(signer);

        // Call the attest function on the Sign Protocol contract
        uint64 attestationId = signProtocol.attest{
            value: 0 // No ETH fees
        }(
            attestation,
            indexingKey,
            "", // No delegate signature
            extraData // Pass extraData
        );

        emit AttestationReceived(attestationId, indexingKey);
    }

    // Internal function to process the attestation with ETH fees
    function _receiveAttestationWithETHFees(
        uint64 schemaId,
        string memory contractDetails,
        address signer,
        uint256 resolverFeesETH,
        string memory indexingKey,
        bytes memory extraData
    ) internal {
        // Encode the schema data
        bytes memory schemaData = abi.encode(contractDetails, signer);

        // Prepare the attestation struct
        ISignProtocol.Attestation memory attestation = ISignProtocol.Attestation({
            schemaId: schemaId,
            linkedAttestationId: 0, // Not linking to another attestation
            attestTimestamp: uint64(block.timestamp),
            revokeTimestamp: 0, // Not revoked
            attester: address(this), // This contract is the attester
            validUntil: 0, // No expiry
            dataLocation: ISignProtocol.DataLocation.OnChain,
            revoked: false,
            recipients: new bytes[](1),
            data: schemaData
        });

        // Set the recipient
        attestation.recipients[0] = abi.encodePacked(signer);

        // Call the attest function on the Sign Protocol contract
        uint64 attestationId = signProtocol.attest{
            value: resolverFeesETH // Pass ETH fees
        }(
            attestation,
            resolverFeesETH,
            indexingKey,
            "", // No delegate signature
            extraData // Pass extraData
        );

        emit AttestationReceived(attestationId, indexingKey);
    }

    // Internal function to process the attestation with ERC20 fees
    function _receiveAttestationWithERC20Fees(
        uint64 schemaId,
        string memory contractDetails,
        address signer,
        IERC20 resolverFeesERC20Token,
        uint256 resolverFeesERC20Amount,
        string memory indexingKey,
        bytes memory extraData
    ) internal {
        // Encode the schema data
        bytes memory schemaData = abi.encode(contractDetails, signer);

        // Prepare the attestation struct
        ISignProtocol.Attestation memory attestation = ISignProtocol.Attestation({
            schemaId: schemaId,
            linkedAttestationId: 0, // Not linking to another attestation
            attestTimestamp: uint64(block.timestamp),
            revokeTimestamp: 0, // Not revoked
            attester: address(this), // This contract is the attester
            validUntil: 0, // No expiry
            dataLocation: ISignProtocol.DataLocation.OnChain,
            revoked: false,
            recipients: new bytes[](1),
            data: schemaData
        });

        // Set the recipient
        attestation.recipients[0] = abi.encodePacked(signer);

        // Approve the resolver fees to the Sign Protocol contract
        resolverFeesERC20Token.approve(address(signProtocol), resolverFeesERC20Amount);

        // Call the attest function on the Sign Protocol contract
        uint64 attestationId = signProtocol.attest(
            attestation,
            resolverFeesERC20Token,
            resolverFeesERC20Amount,
            indexingKey,
            "", // No delegate signature
            extraData // Pass extraData
        );

        emit AttestationReceived(attestationId, indexingKey);
    }

    function attest(
        ISignProtocol.Attestation calldata attestation,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    ) external payable returns (uint64) {
        return signProtocol.attest(attestation, indexingKey, delegateSignature, extraData);
    }

    function attest(
        ISignProtocol.Attestation calldata attestation,
        uint256 resolverFeesETH,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    ) external payable returns (uint64) {
        return signProtocol.attest(attestation, resolverFeesETH, indexingKey, delegateSignature, extraData);
    }

    function attest(
        ISignProtocol.Attestation calldata attestation,
        IERC20 resolverFeesERC20Token,
        uint256 resolverFeesERC20Amount,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    ) external returns (uint64) {
        return signProtocol.attest(attestation, resolverFeesERC20Token, resolverFeesERC20Amount, indexingKey, delegateSignature, extraData);
    }

    // Function to receive ETH (if needed for attestations that require ETH)
    receive() external payable {}
}
