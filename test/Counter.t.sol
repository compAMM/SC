// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RWAExchange} from "../src/RWAExchange.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract CounterTest is Test {
    RWAExchange public exchange;
    MockERC20 public xStocks;
    MockERC20 public paymentToken;

    address buyer = address(1);

    function setUp() public {
        // Deploy mock tokens
        xStocks = new MockERC20("xSTOCKS", "XST");
        paymentToken = new MockERC20("USDC", "USDC");

        // Initial reserves
        uint256 initialX = 1000;
        uint256 initialY = 2000;

        // Deploy exchange
        exchange = new RWAExchange(address(xStocks), address(paymentToken), initialX, initialY);

        // Fund exchange contract with tokens matching reserves
        xStocks.mint(address(this), initialX);
        paymentToken.mint(address(this), initialY);

        xStocks.transfer(address(exchange), initialX);
        paymentToken.transfer(address(exchange), initialY);
    }

    function test_initialReserves() public {
        assertEq(exchange.reserveX(), 1000);
        assertEq(exchange.reserveY(), 2000);
    }

    function test_buyXStocks_success() public {
        uint256 paymentAmount = 100;

        // Set compliance for buyer
        exchange.setAccredited(buyer, true);
        exchange.setKYC(buyer, true);
        exchange.setJurisdiction(buyer, true);

        // Mint payment tokens to buyer and approve exchange
        paymentToken.mint(buyer, paymentAmount);
        vm.prank(buyer);
        paymentToken.approve(address(exchange), paymentAmount);

        // Compute expected output using same math as contract
        uint256 reserveX = exchange.reserveX();
        uint256 reserveY = exchange.reserveY();
        uint256 k = reserveX * reserveY;
        uint256 newReserveY = reserveY + paymentAmount;
        uint256 newReserveX = k / newReserveY;
        uint256 expectedXOut = reserveX - newReserveX;

        // Buyer performs swap
        vm.prank(buyer);
        exchange.buyXStocks(paymentAmount);

        // Assertions: buyer received xStocks and reserves updated
        assertEq(xStocks.balanceOf(buyer), expectedXOut);
        assertEq(exchange.reserveX(), newReserveX);
        assertEq(exchange.reserveY(), newReserveY);
    }

    function test_buyXStocks_revert_if_not_accredited() public {
        uint256 paymentAmount = 10;

        // buyer has tokens but not accredited
        paymentToken.mint(buyer, paymentAmount);
        vm.prank(buyer);
        paymentToken.approve(address(exchange), paymentAmount);

        vm.prank(buyer);
        vm.expectRevert(bytes("Not accredited"));
        exchange.buyXStocks(paymentAmount);
    }
}
