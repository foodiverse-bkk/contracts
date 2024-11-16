// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {AttestationDispatcher} from "../src/AttestationDispatcher.sol";
import {IMailbox} from "../lib/hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";

contract DeployAttestationDispatcherScript is Script {
    function run() external {
        // Retrieve configuration from environment variables
        address mailboxAddress = 0x03f9Cc54E1Ff0002286f326FB8F7ca6eE191167f;
        uint32 destinationChainId = 84532;
        address crossChainAttestorAddress = 0x935588C6018925E659847b07891A62CdA5054B2d;

        // Retrieve the deployer's private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the AttestationDispatcher contract
        AttestationDispatcher attestationDispatcher = new AttestationDispatcher(
            IMailbox(mailboxAddress),
            destinationChainId,
            crossChainAttestorAddress
        );

        console.log("AttestationDispatcher deployed at:", address(attestationDispatcher));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
