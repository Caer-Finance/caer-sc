// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITokenSwap {
    function mintMock(address _to, uint256 _amount) external;
    function burnMock(uint256 _amount) external;
}