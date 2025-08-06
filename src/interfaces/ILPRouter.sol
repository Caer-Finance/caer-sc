// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILPRouter {
    // ** READ
    function totalSupplyAssets() external view returns (uint256);
    function totalSupplyShares() external view returns (uint256);
    function totalBorrowAssets() external view returns (uint256);
    function totalBorrowShares() external view returns (uint256);
    function lastAccrued() external view returns (uint256);
    function userSupplyShares(address user) external view returns (uint256);
    function userBorrowShares(address user) external view returns (uint256);
    function addressPositions(address user) external view returns (address);
    function lendingPool() external view returns (address);
    function collateralToken() external view returns (address);
    function borrowToken() external view returns (address);
    function ltv() external view returns (uint256);

    // ** WRITE
    function supplyLiquidity(uint256 amount, address user) external returns (uint256 shares);
    function withdrawLiquidity(uint256 shares, address user) external returns (uint256 amount);
    function withdrawCollateral(address user) external;
    function accrueInterest() external;
    function borrowDebt(uint256 amount, address user)
        external
        returns (uint256 protocolFee, uint256 userAmount, uint256 shares);
    function repayWithSelectedToken(uint256 shares, address user) external returns (uint256 borrowAmount);
    function createPosition(address user) external returns (address);
}
