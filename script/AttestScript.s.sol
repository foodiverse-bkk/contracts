// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

// Import the ISP interface and related contracts
import "../lib/sign-protocol-evm/src/interfaces/ISP.sol";
import "../lib/sign-protocol-evm/src/models/Attestation.sol";
import "../lib/sign-protocol-evm/src/models/DataLocation.sol";
import "../src/helpers/ByteHasher.sol";

contract AttestScript is Script {
    using ByteHasher for bytes;

    function run() external {
        // Load the private key from the environment variable as a string
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");

        // Parse the private key string to a uint256
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);

        // Get the attester address (the address corresponding to the private key)
       address attester = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Instantiate the ISP contract at the specified address
        ISP ispContract = ISP(0x4e4af2a21ebf62850fD99Eb6253E1eFBb56098cD);

        // Prepare the attestation data
        uint64 schemaId = 0x2e4; // Replace with the actual schema ID
        Attestation memory attestation = Attestation({
            schemaId: schemaId,
            linkedAttestationId: 0,
            attestTimestamp: 0,
            revokeTimestamp: 0,
            attester: attester, // The attester's address
            validUntil: 0,
            dataLocation: DataLocation.ONCHAIN,
            revoked: false,
            recipients: new bytes[](0),
            data: abi.encode("This is a sample attestation.")
        });

        console.log("Attester:", attester);
        // Set the indexing key
        string memory indexingKey = "user123";

        // Empty delegate signature (not in delegate mode)
        bytes memory delegateSignature = "";

        // Prepare the World ID verification parameters
        // These should be obtained from the World ID verification process
        uint256 root = 0x2897864a946c0d6c516626273dfaac3213470b8abfba95ad255c8c0d6dbe7cb5;
        uint256 nullifierHash = 0x0784518dbb2fed7650a9b7a3473bdccc4826e0b05158190ed0085378248e9312;

        // Create proof
        uint256[8] memory proof = [
            0x00fd8e4629017fef831c14aa134d9cf9fb1614cd18b24152f30c2e63b9550532,
            0x051ee84c6d9c2395a88c32b7ca40824df1d92c96f9c3bbc43ed5e88855ef4778,
            0x0d77987f0d3aa536c97949b2ad25390ed89073d842b0b1b049ce198f604c9480,
            0x2dc2eb92b7966a81454c6f1420fb101bbf185fc5f30cb2162e95f8090a3ad1b9,
            0x229c31d4c89b447e95a82a7b7bcc7209ecac924c018fd7f7429777401fa12fe8,
            0x1089b2c8d259b8aeac3f9b3d7954b373ec1010ad5690debf933311c43e8ffd2e,
            0x2153a499dea6542e3c7f04d16f73caa9aaeca97be2883130e9d71b7503fd77e1,
            0x1582a98893aae1fc69d87401131f9565bc2313de874790d69ae64a4284d8f831
        ];
        // Encode the extraData with the World ID parameters
        bytes memory extraData = abi.encode(root, nullifierHash, proof);

        // Call the attest function
        uint64 attestationId = ispContract.attest(
            attestation,
            indexingKey,
            delegateSignature,
            extraData
        );

        // Log the attestation ID
        console.log("Attestation ID:", attestationId);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
