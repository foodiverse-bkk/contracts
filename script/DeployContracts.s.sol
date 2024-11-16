// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {CheckBalanceSchemaHook} from "../src/CheckBalanceSchemaHook.sol";
import {console2} from "forge-std/console2.sol";

contract DeployContracts is Script {
    function run() public returns (MockUSDC, CheckBalanceSchemaHook) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address spAddress = vm.envAddress("SP_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MockUSDC first
        MockUSDC mockUSDC = new MockUSDC();
        console2.log("MockUSDC deployed at:", address(mockUSDC));

        // Deploy CheckBalanceSchemaHook with MockUSDC and SP addresses
        CheckBalanceSchemaHook hook = new CheckBalanceSchemaHook(
            address(mockUSDC),
            spAddress
        );
        console2.log("CheckBalanceSchemaHook deployed at:", address(hook));

        // Optional: Transfer some initial USDC to the hook for testing
        mockUSDC.transfer(address(hook), 1000 * 10**6); // Transfer 1000 USDC
        
        vm.stopBroadcast();
        
        return (mockUSDC, hook);
    }
} 