// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/Swap.sol";
import "../src/MockUSDY.sol";
import "../src/MockREIT.sol";
import "../src/KYCOracle.sol";

contract SwapTest is Test {
    Swap swap;
    MockUSDY usdy;
    MockREIT reit;
    KYCOracle kycOracle;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.startPrank(owner);

        usdy = new MockUSDY();
        reit = new MockREIT();
        kycOracle = new KYCOracle();
        swap = new Swap(address(usdy), address(reit), address(kycOracle));

        // Setup Liquidity
        // Price 1000 USDY = 1 REIT
        // Reserve: 100,000 USDY : 100 REIT
        uint256 usdyLiq = 100_000 ether;
        uint256 reitLiq = 100 ether;

        usdy.mint(owner, usdyLiq);
        reit.mint(owner, reitLiq);

        usdy.approve(address(swap), usdyLiq);
        reit.approve(address(swap), reitLiq);

        swap.addLiquidity(usdyLiq, reitLiq);

        vm.stopPrank();
    }

    function test_SwapAccredited() public {
        vm.startPrank(alice);

        // 1. Get Money
        usdy.mint(alice, 2000 ether);
        usdy.approve(address(swap), 2000 ether);

        // 2. Get Accredited
        kycOracle.setAccredited(alice, true);

        // 3. Swap
        // Swap 1000 USDY for REIT
        uint256 amountIn = 1000 ether;

        uint256 amountOut = swap.swap(address(usdy), amountIn, 0);

        assertGt(amountOut, 0.9 ether);
        assertLt(amountOut, 1.0 ether);
        assertEq(reit.balanceOf(alice), amountOut);

        vm.stopPrank();
    }

    function test_RevertIf_SwapNotAccredited() public {
        vm.startPrank(bob);

        usdy.mint(bob, 1000 ether);
        usdy.approve(address(swap), 1000 ether);

        // Bob is NOT accredited
        vm.expectRevert("NOT ACCREDITED");
        swap.swap(address(usdy), 1000 ether, 0);

        vm.stopPrank();
    }

    function test_RevertIf_PriceImpactTooHigh() public {
        vm.startPrank(alice);
        kycOracle.setAccredited(alice, true);

        // Try to swap HUGE amount that shifts price beyond 5%
        // Liquidity is 100k USDY.
        usdy.mint(alice, 50_000 ether);
        usdy.approve(address(swap), 50_000 ether);

        // Price check is:
        // 950 <= amountIn/amountOut <= 1050
        // When swapping huge USDY, amountOut diminishes (slippage).
        // So amountIn/amountOut becomes VERY LARGE.
        // e.g. 10,000 / 5 => 2000.
        // 2000 > 1050.
        // Revert "Price above 1050". (Wait, "Price out of bounds" or "Price above 1050" from my code logic?)
        // My code: require(amountIn <= 1050 * amountOut, "Price above 1050");
        // If amountIn=50k, amountOut=33k. 50k <= 1050*33k = 34k??? No. 50k > 34k.
        // Wait. 1050 * 33k = ~34,650k??
        // 50,000 <= 34,650,000 ??

        // Let's recheck math.
        // amountIn = 50,000 USDY.
        // amountOut ~ 33 REIT. (33e18).
        // 50,000e18 <= 1050 * 33e18 = 34,650e18. FALSE.
        // Revert "Price above 1050".

        vm.expectRevert("Price above 1050");
        swap.swap(address(usdy), 50_000 ether, 0);

        vm.stopPrank();
    }
}
