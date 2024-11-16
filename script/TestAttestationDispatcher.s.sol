// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {AttestationDispatcher} from "../src/AttestationDispatcher.sol";

contract TestAttestationDispatcherScript is Script {
    function run() external {
        address attestationDispatcherAddress = 0x790d846ad311772E311B1C7525ba07A799535dd2;

        // Retrieve the deployer's private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        AttestationDispatcher attestationDispatcher = AttestationDispatcher(payable(attestationDispatcherAddress));

        attestationDispatcher.dispatchAttestation(0, "0x0");

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}