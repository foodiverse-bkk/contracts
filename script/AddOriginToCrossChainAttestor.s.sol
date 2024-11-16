// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {CrossChainAttestor} from "../src/CrossChainAttestor.sol";

contract AddOriginToCrossChainAttestorScript is Script {
    function run() external {
        // Replace with the address of your deployed CrossChainAttestor contract
        address crossChainAttestorAddress = 0x935588C6018925E659847b07891A62CdA5054B2d;

        // Retrieve the deployer's private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        // Create an instance of the deployed CrossChainAttestor contract
        CrossChainAttestor crossChainAttestor = CrossChainAttestor(payable(crossChainAttestorAddress));

        // Example: Adding Linea Sepolia Origin
        uint32 lineaSepoliaOriginChainId = 59141;
        address lineaSepoliaExpectedSenderAddress = 0x02d16BC51af6BfD153d67CA61754cF912E82C4d9;
        bytes32 lineaSepoliaExpectedSenderBytes32 = bytes32(uint256(uint160(lineaSepoliaExpectedSenderAddress)));
        // Call setOrigin for AirDAO
        crossChainAttestor.setOrigin(lineaSepoliaOriginChainId, lineaSepoliaExpectedSenderBytes32);
        console.log("Origin address set for Linea Sepolia chain ID:", lineaSepoliaOriginChainId);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}