// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {CrossChainAttestor} from "../src/CrossChainAttestor.sol";
import {IMailbox} from "../lib/hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";
import {ISignProtocol} from "../src/CrossChainAttestor.sol";

contract DeployCrossChainAttestorScript is Script {
    function run() external {
        // Replace with actual addresses
        address mailboxAddress = 0x6966b0E55883d49BFB24539356a2f8A673E02039; // Hyperlane Mailbox contract address
        address signProtocolAddress = 0x4e4af2a21ebf62850fD99Eb6253E1eFBb56098cD; // Sign Protocol contract address

        // Retrieve the deployer's private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the CrossChainAttestor contract
        CrossChainAttestor crossChainAttestor = new CrossChainAttestor(
            IMailbox(mailboxAddress),
            ISignProtocol(signProtocolAddress)
        );

        console.log("CrossChainAttestor deployed at:", address(crossChainAttestor));

        // Set the origin addresses
        // Replace with actual origin chain IDs and expected sender addresses
        uint32 airDaoOriginChainId = 22040; // e.g., 1000
        address airDaoExpectedSenderAddress = 0x438D749BfAD69a368d85811155d6BB0dEf5f7A11; // Expected sender address on origin chain
        // Convert the expected sender address to bytes32
        bytes32 airDaoExpectedSenderBytes32 = bytes32(uint256(uint160(airDaoExpectedSenderAddress)));
        // Morph
        uint32 morphOriginChainId = 2810; // e.g., 1000
        address morphExpectedSenderAddress = 0x438D749BfAD69a368d85811155d6BB0dEf5f7A11; // Expected sender address on origin chain
        // Convert the expected sender address to bytes32
        bytes32 morphExpectedSenderBytes32 = bytes32(uint256(uint160(morphExpectedSenderAddress)));

        // Call setOrigin for AirDAO
        crossChainAttestor.setOrigin(airDaoOriginChainId, airDaoExpectedSenderBytes32);
        // Call setOrigin for Morph
        crossChainAttestor.setOrigin(morphOriginChainId, morphExpectedSenderBytes32);


        console.log("Origin address set for chain ID", airDaoOriginChainId);
        console.log("Origin address set for chain ID", morphOriginChainId);



        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
