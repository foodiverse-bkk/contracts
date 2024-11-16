// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/WorldIDSchemaHook.sol";
import { IWorldID } from "../src/interfaces/IWorldID.sol";

contract DeployWorldIDSchemaHook is Script {
    function run() external {
        // Load environment variables
        address worldIdAddress = vm.envAddress("WORLD_ID_ADDRESS");
        string memory appId = vm.envString("APP_ID");
        string memory actionId = vm.envString("ACTION_ID");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the WorldIDSchemaHook contract
        WorldIDSchemaHook schemaHook = new WorldIDSchemaHook(
            IWorldID(worldIdAddress),
            appId,
            actionId
        );

        // Log the deployed contract address
        console.log("WorldIDSchemaHook deployed at:", address(schemaHook));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
