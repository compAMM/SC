// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/Fauchet.sol";
import "../src/MockUSDY.sol";
import "../src/MockREIT.sol";
import "../src/KYCOracle.sol";

contract FauchetTest is Test {
    Fauchet fauchet;
    MockUSDY mockUSDY;
    MockREIT mockREIT;
    KYCOracle kycOracle;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");

    function setUp() public {
        vm.startPrank(owner);

        // Deploy tokens and oracle
        mockUSDY = new MockUSDY();
        mockREIT = new MockREIT();
        kycOracle = new KYCOracle();

        // Deploy Fauchet
        fauchet = new Fauchet(
            address(mockUSDY),
            address(mockREIT),
            address(kycOracle)
        );

        // Fund Fauchet (mint to faucet)
        // Since mint is public in Mock contracts, anyone can mint.
        // We mint to the faucet address so it has tokens to distribute.
        mockUSDY.mint(address(fauchet), 1_000_000 ether);
        mockREIT.mint(address(fauchet), 1_000 ether);

        vm.stopPrank();
    }

    function test_ClaimTokens() public {
        vm.startPrank(alice);

        // Initial check
        assertEq(mockUSDY.balanceOf(alice), 0);
        assertEq(mockREIT.balanceOf(alice), 0);
        assertFalse(kycOracle.isAccredited(alice));

        // Claim
        fauchet.claimTokens();

        // Verify balances
        assertEq(mockUSDY.balanceOf(alice), 1000 ether);
        assertEq(mockREIT.balanceOf(alice), 1 ether);
        assertTrue(kycOracle.isAccredited(alice));

        vm.stopPrank();
    }

    function test_Cooldown() public {
        vm.startPrank(alice);
        fauchet.claimTokens();

        // Try claim again immediately
        vm.expectRevert("Cooldown active");
        fauchet.claimTokens();

        // Propagate time
        vm.warp(block.timestamp + 24 hours);

        // Should succeed now
        fauchet.claimTokens();
        assertEq(mockUSDY.balanceOf(alice), 2000 ether);

        vm.stopPrank();
    }
}
