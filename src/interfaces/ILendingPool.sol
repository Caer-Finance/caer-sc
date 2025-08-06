// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILendingPool {
    function createPosition() external;
    function supplyLiquidity(uint256 amount) external;
    function withdrawLiquidity(uint256 shares) external;
    function supplyCollateral(uint256 amount) external;
    function withdrawCollateral(address _user) external;
    function borrowDebt(uint256 amount, uint256 _chainId, uint256 _bridgeTokenSender) external payable;
    function repayWithSelectedToken(uint256 shares, address _token, bool _fromPosition) external;
    function swapTokenByPosition(address _tokenFrom, address _tokenTo, uint256 amountIn) external returns (uint256 amountOut);
    function accrueInterest() external;
    function router() external view returns (address);
}