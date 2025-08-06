// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IProtocol {
    // ** WRITE
    function withdraw(address token, uint256 amount) external;
}