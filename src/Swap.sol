// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./MockUSDC.sol";
import "./MockREIT.sol";

contract Swap {
    MockUSDC public usdc;
    MockREIT public reit;

    uint256 public constant RATE = 1000; // 1000 REIT = 1 USDC

    constructor(address _usdc, address _reit) {
        usdc = MockUSDC(_usdc);
        reit = MockREIT(_reit);
    }

    function swapREITToUSDC(uint256 amount) external {
        // Burn REIT from the user
        // Note: usage of public burn relies on MockREIT allowing it
        reit.burn(msg.sender, amount);

        // Convert REIT to USDC with ratio 1:1000
        // 1 REIT = 1000 USDC => USDC = REIT * 1000
        uint256 usdcAmount = amount * RATE;

        // Mint USDC to the user
        usdc.mint(msg.sender, usdcAmount);
    }
}
