// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILendingPool {
    // ** READ
    function factory() external view returns (address);
    function protocol() external view returns (address);
    function router() external view returns (address);

    // ** WRITE
    function createPosition() external;
    function supplyLiquidity(uint256 _amount, uint256 _chainId, address _user) external;
    function withdrawLiquidity(uint256 _shares, address _user, uint256 _chainId) external;
    function withdrawLiquidityByBridge(uint256 _amount, address _user) external;
    function supplyCollateral(uint256 _amount, uint256 _chainId, address _user) external;
    function withdrawCollateral(uint256 _amount, uint256 _chainId, address _user) external;
    function withdrawCollateralByBridge(uint256 _amount, address _user) external;
    function borrowDebt(uint256 _amount, address _user, uint256 _chainId) external payable;
    function borrowDebtByBridge(uint256 _amount, address _user) external;
    function repayWithSelectedToken(uint256 _shares, address _token, bool _fromPosition) external;
    function swapTokenByPosition(address _tokenFrom, address _tokenTo, uint256 _amountIn)
        external
        returns (uint256 _amountOut);
}
