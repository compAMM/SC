// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/Fauchet.sol";
import "../src/Swap.sol";
import "../src/MockUSDY.sol";
import "../src/MockREIT.sol";
import "../src/KYCOracle.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // If no private key, use a default (for local testing via anvil if needed, though usually passing --private-key works)
        // However, startBroadcast() with no args uses the --private-key flag or default sender.

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Tokens
        MockUSDY usdy = new MockUSDY();
        MockREIT reit = new MockREIT();
        KYCOracle oracle = new KYCOracle();

        console.log("MockUSDY deployed at:", address(usdy));
        console.log("MockREIT deployed at:", address(reit));
        console.log("KYCOracle deployed at:", address(oracle));

        // 2. Deploy Faucet
        Fauchet faucet = new Fauchet(
            address(usdy),
            address(reit),
            address(oracle)
        );
        console.log("Fauchet deployed at:", address(faucet));

        // 3. Deploy Swap
        Swap swap = new Swap(address(usdy), address(reit), address(oracle));
        console.log("Swap deployed at:", address(swap));

        // 4. Setup Faucet Balance
        // Mint 1,000,000 USDY and 1,000 REIT to Faucet
        usdy.mint(address(faucet), 1_000_000 ether);
        reit.mint(address(faucet), 1_000 ether);
        console.log("Faucet funded with tokens");

        // 5. Setup Swap Liquidity
        // Add 100,000 USDY and 100 REIT (Price 1000)
        uint256 usdyLiq = 100_000 ether;
        uint256 reitLiq = 100 ether;

        usdy.mint(msg.sender, usdyLiq);
        reit.mint(msg.sender, reitLiq);

        usdy.approve(address(swap), usdyLiq);
        reit.approve(address(swap), reitLiq);

        swap.addLiquidity(usdyLiq, reitLiq);
        console.log("Liquidity added to Swap");

        // 6. Whitelist Faucet in Oracle (if needed? No, Oracle is public setAccredited in Mock)
        // Check if Oracle needs ownership transfer? No, setAccredited is public.

        // However, Faucet.sol does NOT call kycOracle.setAccredited properly if it was OWNABLE restricted.
        // Since we made everything public for Mock, it works out of the box.

        vm.stopBroadcast();
    }
}
