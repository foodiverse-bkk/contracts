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

        // Deploy CheckBalanceSchemaHook
        CheckBalanceSchemaHook hook = new CheckBalanceSchemaHook(
            address(mockUSDC),
            spAddress
        );
        console2.log("CheckBalanceSchemaHook deployed at:", address(hook));

        // Optional: Transfer some initial USDC to the hook for testing
        mockUSDC.transfer(address(hook), 1000 * 10 ** 6);

        vm.stopBroadcast();

        // // Print verification commands
        // console2.log("\nVerification Commands:");
        // console2.log("----------------------");
        // console2.log("Verify MockUSDC:");
        // console2.log(
        //     "forge verify-contract --chain base-sepolia --compiler-version v0.8.13+commit.abaa5c0e",
        //     address(mockUSDC),
        //     "src/MockUSDC.sol:MockUSDC",
        //     "--watch"
        // );

        // console2.log("\nVerify CheckBalanceSchemaHook:");
        // console2.log(
        //     "forge verify-contract --chain base-sepolia --compiler-version v0.8.13+commit.abaa5c0e",
        //     address(hook),
        //     "src/CheckBalanceSchemaHook.sol:CheckBalanceSchemaHook",
        //     "--constructor-args",
        //     string.concat(
        //         '$(cast abi-encode "constructor(address,address)" ',
        //         vm.toString(address(mockUSDC)),
        //         " ",
        //         vm.toString(spAddress),
        //         ")"
        //     ),
        //     "--watch"
        // );

        return (mockUSDC, hook);
    }
}
