// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RWAExchange} from "../src/RWAExchange.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract CounterScript is Script {
    RWAExchange public exchange;
    MockERC20 public xStocks;
    MockERC20 public paymentToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address deployer = msg.sender;

        // Deploy mock tokens
        xStocks = new MockERC20("xSTOCKS", "XST");
        paymentToken = new MockERC20("USDC", "USDC");

        // Initial reserves
        uint256 initialX = 1000;
        uint256 initialY = 2000;

        // Deploy exchange
        exchange = new RWAExchange(address(xStocks), address(paymentToken), initialX, initialY);

        // Mint tokens to owner (script caller) and fund the exchange to match reserves
        xStocks.mint(deployer, initialX);
        paymentToken.mint(deployer, initialY);

        xStocks.transfer(address(exchange), initialX);
        paymentToken.transfer(address(exchange), initialY);

        vm.stopBroadcast();
    }
}
