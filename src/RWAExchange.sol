// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RWAExchange is Ownable {
    IERC20 public xStocks;        // Token RWA
    IERC20 public paymentToken;   // USDC / stablecoin

    using SafeERC20 for IERC20;

    uint256 public reserveX; // xSTOCKS reserve
    uint256 public reserveY; // paymentToken reserve

    // --- Compliance ---
    mapping(address => bool) public isAccredited;
    mapping(address => bool) public isKYCVerified;  
    mapping(address => bool) public isJurisdictionAllowed;

    // --- Events ---
    event SwapExecuted(
        address indexed buyer,
        uint256 paymentIn,
        uint256 xStocksOut
    );

    constructor(
        address _xStocks,
        address _paymentToken,
        uint256 _initialX,
        uint256 _initialY
    ){
        xStocks = IERC20(_xStocks);
        paymentToken = IERC20(_paymentToken);

        reserveX = _initialX;
        reserveY = _initialY;
    }

    // =========================
    // Compliance Management
    // =========================

    function setAccredited(address user, bool status) external onlyOwner {
        isAccredited[user] = status;
    }

    function setKYC(address user, bool status) external onlyOwner {
        isKYCVerified[user] = status;
    }

    function setJurisdiction(address user, bool status) external onlyOwner {
        isJurisdictionAllowed[user] = status;
    }

    // =========================
    // Swap Logic (x * y = k)
    // =========================

    function buyXStocks(uint256 paymentAmount) external {
        require(isAccredited[msg.sender], "Not accredited");
        require(isKYCVerified[msg.sender], "KYC not verified");
        require(isJurisdictionAllowed[msg.sender], "Jurisdiction blocked");
        require(paymentAmount > 0, "Invalid amount");

        // Constant product formula
        uint256 k = reserveX * reserveY;
        uint256 newReserveY = reserveY + paymentAmount;
        uint256 newReserveX = k / newReserveY;

        uint256 xStocksOut = reserveX - newReserveX;
        require(xStocksOut > 0, "Insufficient output");

        // Transfer payment token from buyer
        paymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            paymentAmount
        );

        // Ensure contract has enough xSTOCKS to fulfill swap
        require(xStocks.balanceOf(address(this)) >= xStocksOut, "Contract xStocks insufficient");

        // Transfer xSTOCKS to buyer
        xStocks.safeTransfer(msg.sender, xStocksOut);

        // Update reserves
        reserveX = newReserveX;
        reserveY = newReserveY;

        emit SwapExecuted(msg.sender, paymentAmount, xStocksOut);
    }

    // =========================
    // Admin Liquidity Control
    // =========================

    function addLiquidity(uint256 xAmount, uint256 yAmount) external onlyOwner {
        xStocks.safeTransferFrom(msg.sender, address(this), xAmount);
        paymentToken.safeTransferFrom(msg.sender, address(this), yAmount);

        reserveX += xAmount;
        reserveY += yAmount;
    }
}

