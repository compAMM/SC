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

    function test_SwapREITToUSDC() public {
        uint256 amount = 100 * 10 ** 18;

        console.log("----- Initial State -----");
        console.log("User Address: ", user);
        console.log("User REIT Balance: ", reit.balanceOf(user));
        console.log("User USDC Balance: ", usdc.balanceOf(user));

        // Mint REIT to user
        reit.mint(user, amount);

        assertEq(reit.balanceOf(user), amount, "Mint failed");
        assertEq(usdc.balanceOf(user), 0, "USDC should be 0");

        console.log("----- After Minting REIT -----");
        console.log("Minted Amount: ", amount);
        console.log("User REIT Balance: ", reit.balanceOf(user));
        console.log("User USDC Balance: ", usdc.balanceOf(user));

        // Prank as user to call swap
        vm.startPrank(user);
        console.log("----- Performing Swap (REIT -> USDC) -----");
        swap.swapREITToUSDC(amount);
        vm.stopPrank();

        // Check balances
        assertEq(reit.balanceOf(user), 0, "REIT not burned");
        assertEq(usdc.balanceOf(user), amount, "USDC not minted");

        console.log("----- Final State After Swap -----");
        console.log("User REIT Balance: ", reit.balanceOf(user));
        console.log("User USDC Balance: ", usdc.balanceOf(user));
        console.log("Swap successful: 1:1 ratio maintained");
    }
}
