// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICreateLendingPoolOrigin {
    function createLendingPool(
        address _originLendingPool,
        address _collateralToken,
        address _borrowToken,
        uint256 _ltv,
        uint256[] memory _destinationChainIds
    ) external payable;
}
