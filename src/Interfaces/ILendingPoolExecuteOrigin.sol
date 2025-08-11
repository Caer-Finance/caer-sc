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
        bytes memory _message,
        uint256[] memory _chainId,
        ExecuteType _executeType
    ) external payable;
}
