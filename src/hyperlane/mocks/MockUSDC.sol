// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    mapping(address => bool) public isMinterBurner;

    constructor() ERC20("USDC", "USDC") {
        isMinterBurner[msg.sender] = true;
    }

    modifier onlyMinterBurner() {
        require(isMinterBurner[msg.sender], "Only minter burner");
        _;
    }
    // this function for hackathon purposes
    function mint(address to, uint256 amount) public onlyMinterBurner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public onlyMinterBurner {
        _burn(msg.sender, amount);
    }
}
