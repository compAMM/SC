// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Swap} from "../src/Swap.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {MockREIT} from "../src/MockREIT.sol";

contract SwapTest is Test {
    Swap public swap;
    MockUSDC public usdc;
    MockREIT public reit;

    address public user = address(1);

    function setUp() public {
        usdc = new MockUSDC();
        reit = new MockREIT();
        swap = new Swap(address(usdc), address(reit));
    }

    function test_SwapREITToUSDC_Ratio() public {
        // Ratio 1 REIT : 1000 USDC

        // Let's use 1 unit of REIT (1 * 10^18)
        uint256 reitAmount = 1;

        // Expected USDC = 1 * 1000 = 1000 * 10^18
        uint256 expectedUsdcAmount = 1000;

        console.log("----- Initial State -----");
        console.log("Rate: 1 REIT = 1000 USDC");
        console.log("User Address: ", user);
        console.log("User REIT Balance: ", reit.balanceOf(user));
        console.log("User USDC Balance: ", usdc.balanceOf(user));

        // Mint REIT to user
        reit.mint(user, reitAmount);

        assertEq(reit.balanceOf(user), reitAmount, "Mint failed");
        assertEq(usdc.balanceOf(user), 0, "USDC should be 0");

        console.log("----- After Minting REIT -----");
        console.log("Minted REIT Amount: ", reitAmount);
        console.log("User REIT Balance: ", reit.balanceOf(user));
        console.log("User USDC Balance: ", usdc.balanceOf(user));

        // Prank as user to call swap
        vm.startPrank(user);
        console.log("----- Performing Swap (REIT -> USDC) -----");
        console.log("Swapping ", reitAmount, " REIT");

        swap.swapREITToUSDC(reitAmount);

        vm.stopPrank();

        // Check balances
        assertEq(reit.balanceOf(user), 0, "REIT not burned");
        assertEq(
            usdc.balanceOf(user),
            expectedUsdcAmount,
            "USDC amount incorrect based on ratio"
        );

        console.log("----- Final State After Swap -----");
        console.log("User REIT Balance: ", reit.balanceOf(user));
        console.log("User USDC Balance: ", usdc.balanceOf(user));
        console.log("Expected USDC: ", expectedUsdcAmount);
        console.log("Swap successful: 1:1000 ratio maintained");
    }
}
