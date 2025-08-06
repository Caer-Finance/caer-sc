// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPriceFeed {
    // ** READ
    function token() external view returns (address);
    function roundId() external view returns (uint80);
    function price() external view returns (uint256);
    function startedAt() external view returns (uint256);
    function updatedAt() external view returns (uint256);
    function answeredInRound() external view returns (uint80);
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    // ** WRITE
    function setPrice(uint256 _price) external;
}
