// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenAllowance {
    function setAllowance(address _token, address _spender, uint256 _amount) public {
        IERC20(_token).approve(_spender, _amount);
    }
}