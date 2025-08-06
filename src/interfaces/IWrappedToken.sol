// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWrappedToken {
    function mint(address _to, uint256 _amount) external;
}