// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockUSDY.sol";
import "./MockREIT.sol";
import "./KYCOracle.sol";
import {
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Swap {
    MockUSDY public usdy;
    MockREIT public reit;
    KYCOracle public kycOracle;

    uint256 public usdyReserve;
    uint256 public reitReserve;

    event SwapExecuted(
        address indexed user,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );
    event LiquidityAdded(uint256 usdyAmount, uint256 reitAmount);

    constructor(address _usdy, address _reit, address _kycOracle) {
        usdy = MockUSDY(_usdy);
        reit = MockREIT(_reit);
        kycOracle = KYCOracle(_kycOracle);
    }

    function addLiquidity(uint256 usdyAmount, uint256 reitAmount) external {
        usdy.transferFrom(msg.sender, address(this), usdyAmount);
        reit.transferFrom(msg.sender, address(this), reitAmount);

        usdyReserve += usdyAmount;
        reitReserve += reitAmount;

        emit LiquidityAdded(usdyAmount, reitAmount);
    }

    function swap(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut
    ) public returns (uint256 amountOut) {
        // 1. Compliance Check
        require(kycOracle.isAccredited(msg.sender), "NOT ACCREDITED");
        require(amountIn > 0, "Amount must be greater than 0");

        bool isUSDYtoREIT = (tokenIn == address(usdy));
        require(isUSDYtoREIT || tokenIn == address(reit), "Invalid token");

        // 2. Transfer In
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // 3. Calc Output (CPMM)
        uint256 reserveIn = isUSDYtoREIT ? usdyReserve : reitReserve;
        uint256 reserveOut = isUSDYtoREIT ? reitReserve : usdyReserve;

        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        // 0.3% fee
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;

        require(amountOut >= minAmountOut, "Slippage limit reached");
        require(amountOut > 0, "Output amount too small");

        // 4. NAV/Price Check
        // Target Price: 1 REIT = 1000 USDY
        // Allowed Range: [950, 1050]

        if (isUSDYtoREIT) {
            // In: USDY, Out: REIT
            // Price = USDY / REIT (should be ~1000)
            // 950 <= AmountIn / AmountOut <= 1050
            require(amountIn >= 950 * amountOut, "Price below 950");
            require(amountIn <= 1050 * amountOut, "Price above 1050");
        } else {
            // In: REIT, Out: USDY
            // Price = USDY / REIT (should be ~1000)
            // 950 <= AmountOut / AmountIn <= 1050
            require(amountOut >= 950 * amountIn, "Price below 950");
            require(amountOut <= 1050 * amountIn, "Price above 1050");
        }

        // 5. Update Reserves
        if (isUSDYtoREIT) {
            usdyReserve += amountIn;
            reitReserve -= amountOut;
        } else {
            reitReserve += amountIn;
            usdyReserve -= amountOut;
        }

        // 6. Transfer Out
        address tokenOut = isUSDYtoREIT ? address(reit) : address(usdy);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit SwapExecuted(msg.sender, tokenIn, amountIn, tokenOut, amountOut);
    }
}
