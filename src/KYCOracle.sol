// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract KYCOracle is Ownable {
    // Database: Who is accredited?
    mapping(address => bool) public accredited;

    constructor() Ownable(msg.sender) {}

    // Check: Is user accredited?
    function isAccredited(address user) public view returns (bool) {
        return accredited[user];
    }

    // Set: Mark user as accredited
    // Public for demo/faucet usage
    function setAccredited(address user, bool status) public {
        accredited[user] = status;
    }
}
