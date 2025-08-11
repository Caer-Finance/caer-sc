// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingPoolExecuteOrigin {
    enum ExecuteType {
        WithdrawLiquidity,
        SupplyLiquidity,
        BorrowDebt,
        RepayDebt,
        SupplyCollateral,
        WithdrawCollateral
    }

    function execute(
        uint256 _shares,
        address _user,
        address _lendingPoolOrigin,
        uint256 _chainId,
        ExecuteType _executeType
    ) external payable;
}
