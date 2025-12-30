// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockUSDY.sol";
import "./MockREIT.sol";
import "./KYCOracle.sol";

contract Fauchet {
    MockUSDY public usdy;
    MockREIT public reit;
    KYCOracle public kycOracle;

    mapping(address => uint256) public lastClaimTime;
    uint256 public constant CLAIM_COOLDOWN = 24 hours;

    event TokensClaimed(
        address indexed user,
        uint256 usdyAmount,
        uint256 reitAmount
    );

    constructor(address _usdy, address _reit, address _kycOracle) {
        usdy = MockUSDY(_usdy);
        reit = MockREIT(_reit);
        kycOracle = KYCOracle(_kycOracle);
    }

    function claimTokens() public {
        // 1. Check cooldown
        if (lastClaimTime[msg.sender] != 0) {
            require(
                block.timestamp >= lastClaimTime[msg.sender] + CLAIM_COOLDOWN,
                "Cooldown active"
            );
        }

        // 2. Mint tokens
        usdy.mint(msg.sender, 1000e18); // 1000 USDY
        reit.mint(msg.sender, 1e18); // 1 REIT

        // 3. Mark as accredited
        kycOracle.setAccredited(msg.sender, true);

        // 4. Record claim time
        lastClaimTime[msg.sender] = block.timestamp;

        emit TokensClaimed(msg.sender, 1000e18, 1e18);
    }
}
