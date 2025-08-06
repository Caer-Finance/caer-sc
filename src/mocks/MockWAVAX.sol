// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockWAVAX is ERC20 {
    constructor() ERC20("Wrapped Avalanche", "WAVAX") {
    }

    // this function for hackathon purposes
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
