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
    function userBorrowShares(address user, uint256 chainId) external view returns (uint256);
    function addressPositions(address user) external view returns (address);
    function lendingPool() external view returns (address);
    function collateralToken() external view returns (address);
    function borrowToken() external view returns (address);
    function ltv() external view returns (uint256);

    // ** WRITE
    function supplyLiquidity(uint256 _amount, uint256 _chainId, address _user) external returns (uint256 shares);
    function withdrawLiquidity(uint256 _shares, address _user) external returns (uint256 amount);
    function supplyCollateral(uint256 _chainId, address _user, uint256 _amount) external;
    function withdrawCollateral(uint256 _amount, uint256 _chainId, address _user) external returns (uint256);
    function accrueInterest() external;
    function borrowDebt(uint256 _amount, address _user, uint256 _chainId)
        external
        returns (uint256 protocolFee, uint256 userAmount, uint256 shares);
    function repayWithSelectedToken(uint256 _shares, address _user)
        external
        returns (uint256 borrowAmount, uint256 userBorrowShares, uint256 totalBorrowShares, uint256 totalBorrowAssets);
    function createPosition(address _user) external returns (address);
    function settlementWithdrawLiquidity(
        address _user,
        uint256 _userSupplyShares,
        uint256 _totalSupplyShares,
        uint256 _totalSupplyAssets
    ) external;

    function settlementBorrowDebtSuccess(
        uint256 _userBorrowShare,
        uint256 _totalBorrowShares,
        uint256 _chainId,
        address _user
    ) external;
    function settlementRepayDebt(
        uint256 _userBorrowShare,
        uint256 _totalBorrowShares,
        uint256 _totalBorrowAssets,
        address _user,
        address _lendingPoolOrigin,
        uint256 _chainId
    ) external;
    function settlementWithdrawCollateral(uint256 _amount, address _user, uint256 _chainId) external;
}
