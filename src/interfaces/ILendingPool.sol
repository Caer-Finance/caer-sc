// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILendingPool {
    // ** READ
    function factory() external view returns (address);
    function protocol() external view returns (address);
    function router() external view returns (address);

    // ** WRITE
    function createPosition() external;
    function supplyLiquidity(uint256 _amount) external;
    function withdrawLiquidity(uint256 _shares) external;
    function supplyCollateral(uint256 _amount) external;
    function withdrawCollateral(uint256 _amount) external;
    function borrowDebt(uint256 _amount, uint256 _chainId) external payable;
    function repayWithSelectedToken(uint256 _shares, address _token, bool _fromPosition) external;
    function swapTokenByPosition(address _tokenFrom, address _tokenTo, uint256 _amountIn)
        external
        returns (uint256 _amountOut);
}
