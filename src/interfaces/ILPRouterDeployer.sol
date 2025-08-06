// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILPRouterDeployer {
    // ** READ
    function factory() external view returns (address);

    // ** WRITE
    function deployLendingPoolRouter(
        address _lendingPool,
        address _factory,
        address _collateralToken,
        address _borrowToken,
        uint256 _ltv
    ) external returns (address);
    function setFactory(address factory) external;
}
