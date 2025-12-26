// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./MockUSDC.sol";
import "./MockREIT.sol";

contract Swap {
    MockUSDC public usdc;
    MockREIT public reit;

    constructor(address _usdc, address _reit) {
        usdc = MockUSDC(_usdc);
        reit = MockREIT(_reit);
    }

    function swapREITToUSDC(uint256 amount) external {
        // Burn REIT from the user
        // Note: usage of public burn relies on MockREIT allowing it
        reit.burn(msg.sender, amount);

        // Mint USDC to the user
        usdc.mint(msg.sender, amount);
    }
}
