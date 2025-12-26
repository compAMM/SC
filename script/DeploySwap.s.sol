// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Swap} from "../src/Swap.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {MockREIT} from "../src/MockREIT.sol";

contract DeploySwap is Script {
    function run() public {
        // Start broadcasting transactions based on the private key provided in the command line
        vm.startBroadcast();

        // 1. Deploy Mock USDC
        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));

        // 2. Deploy Mock REIT
        MockREIT reit = new MockREIT();
        console.log("MockREIT deployed at:", address(reit));

        // 3. Deploy Swap Contract
        Swap swap = new Swap(address(usdc), address(reit));
        console.log("Swap deployed at:", address(swap));

        vm.stopBroadcast();
    }
}
