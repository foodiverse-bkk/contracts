// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {FoodiversePoints} from "../src/FoodiversePoints.sol";
import {PaymentContract} from "../src/PaymentContract.sol";
import {console2} from "forge-std/console2.sol";

contract DeployPaymentSystem is Script {
    function run() public returns (MockUSDC) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deploying contracts from:", deployer);

        MockUSDC mockUSDC = new MockUSDC();

        // Deploy FoodiversePoints
        FoodiversePoints fp = new FoodiversePoints();
        console2.log("FoodiversePoints deployed at:", address(fp));

        // Deploy PaymentContract
        PaymentContract payment = new PaymentContract(
            address(mockUSDC),
            address(fp)
        );
        console2.log("PaymentContract deployed at:", address(payment));

        // Transfer FP tokens to PaymentContract for distribution
        fp.transfer(address(payment), 500_000 * 10 ** 18); // Transfer 500k FP tokens

        vm.stopBroadcast();

        return mockUSDC;
    }
}
