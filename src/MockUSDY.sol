// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockUSDY is ERC20, Ownable {
    constructor() ERC20("Mock USDY", "mUSDY") Ownable(msg.sender) {}

    // Mint (public for demo/faucet usage as requested)
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // Burn (anyone)
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
