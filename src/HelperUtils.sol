// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {IPosition} from "./interfaces/IPosition.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {ILPRouter} from "./interfaces/ILPRouter.sol";

contract HelperUtils {
    address public factory;

    // Struct to group related lending pool data
    struct PoolData {
        uint256 ltv;
        address borrowToken;
        address collateralToken;
        uint256 totalLiquidity;
        address userPosition;
    }

    // Struct to group borrow calculation data
    struct BorrowData {
        uint256 totalBorrowAssets;
        uint256 totalBorrowShares;
        uint256 userBorrowShares;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    function setFactory(address _factory) public {
        factory = _factory;
    }

    function getMaxBorrowAmount(address _lendingPool, address _user) public view returns (uint256) {
        ILendingPool lendingPool = ILendingPool(_lendingPool);

        // Get pool data in one struct
        PoolData memory poolData = PoolData({
            ltv: ILPRouter(lendingPool.router()).ltv(),
            borrowToken: ILPRouter(lendingPool.router()).borrowToken(),
            collateralToken: ILPRouter(lendingPool.router()).collateralToken(),
            totalLiquidity: 0, // Will be set below
            userPosition: ILPRouter(lendingPool.router()).addressPositions(_user)
        });

        poolData.totalLiquidity = IERC20(poolData.borrowToken).balanceOf(_lendingPool);

        // Calculate collateral value
        uint256 tokenValue = _getCollateralValue(poolData, _user);

        // Get borrow data and calculate current borrow amount
        uint256 borrowAmount = _getCurrentBorrowAmount(lendingPool, _user);

        // Calculate max borrow amount
        uint256 maxBorrowAmount = ((tokenValue * poolData.ltv) / 1e18) - borrowAmount;

        return maxBorrowAmount < poolData.totalLiquidity ? maxBorrowAmount : poolData.totalLiquidity;
    }

    // Internal function to calculate collateral value
    function _getCollateralValue(PoolData memory poolData, address /* _user */ ) internal view returns (uint256) {
        address _tokenInPrice = IFactory(factory).tokenDataStream(poolData.collateralToken);
        address _tokenOutPrice = IFactory(factory).tokenDataStream(poolData.borrowToken);
        uint256 collateralBalance = IERC20(poolData.collateralToken).balanceOf(poolData.userPosition);

        return IPosition(poolData.userPosition).tokenCalculator(
            poolData.collateralToken, poolData.borrowToken, collateralBalance, _tokenInPrice, _tokenOutPrice
        );
    }

    // Internal function to get current borrow amount
    function _getCurrentBorrowAmount(ILendingPool lendingPool, address _user) internal view returns (uint256) {
        BorrowData memory borrowData = BorrowData({
            totalBorrowAssets: ILPRouter(lendingPool.router()).totalBorrowAssets(),
            totalBorrowShares: ILPRouter(lendingPool.router()).totalBorrowShares(),
            userBorrowShares: ILPRouter(lendingPool.router()).userBorrowShares(_user)
        });

        return borrowData.totalBorrowAssets == 0
            ? 0
            : (borrowData.userBorrowShares * borrowData.totalBorrowAssets) / borrowData.totalBorrowShares;
    }

    function getExchangeRate(address _tokenIn, address _tokenOut, uint256 _amountIn, address _position)
        public
        view
        returns (uint256)
    {
        address _tokenInPrice = IFactory(factory).tokenDataStream(_tokenIn);
        address _tokenOutPrice = IFactory(factory).tokenDataStream(_tokenOut);
        uint256 tokenValue =
            IPosition(_position).tokenCalculator(_tokenIn, _tokenOut, _amountIn, _tokenInPrice, _tokenOutPrice);

        return tokenValue;
    }

    function getTokenValue(address _token) public view returns (uint256) {
        address tokenDataStream = IFactory(factory).tokenDataStream(_token);
        (, int256 tokenPrice,,,) = IPriceFeed(tokenDataStream).latestRoundData();
        return uint256(tokenPrice);
    }

    function getHealthFactor(address _lendingPool, address _user) public view returns (uint256) {
        ILendingPool lendingPool = ILendingPool(_lendingPool);

        // Get basic user data
        address userPosition = ILPRouter(lendingPool.router()).addressPositions(_user);
        uint256 userBorrowShares = ILPRouter(lendingPool.router()).userBorrowShares(_user);

        if (userBorrowShares == 0) {
            return 69; // No debt = infinite health factor
        }
        if (userPosition == address(0)) {
            return 6969;
        }

        // Calculate collateral and borrow values using internal functions
        uint256 collateralValue = _calculateCollateralValue(userPosition);
        uint256 borrowValue = _calculateBorrowValue(lendingPool, _user);

        // Calculate health factor
        uint256 ltv = ILPRouter(lendingPool.router()).ltv();
        uint256 healthFactor = (collateralValue * (ltv * 1e8 / 1e18)) / borrowValue;

        return healthFactor; // >1e8 is healthy, <1e8 is unhealthy
    }

    // Internal function to calculate total collateral value
    function _calculateCollateralValue(address userPosition) internal view returns (uint256) {
        uint256 collateralValue = 0;
        uint256 counter = IPosition(userPosition).counter();

        for (uint256 i = 1; i <= counter; i++) {
            address token = IPosition(userPosition).tokenLists(i);
            if (token != address(0)) {
                uint256 tokenBalance = IERC20(token).balanceOf(userPosition);
                uint256 tokenDecimals = IERC20Metadata(token).decimals();
                collateralValue += (getTokenValue(token) * tokenBalance / 10 ** tokenDecimals);
            }
        }

        return collateralValue;
    }

    // Internal function to calculate total borrow value
    function _calculateBorrowValue(ILendingPool lendingPool, address _user) internal view returns (uint256) {
        // Reuse BorrowData struct to group variables
        BorrowData memory borrowData = BorrowData({
            totalBorrowAssets: ILPRouter(lendingPool.router()).totalBorrowAssets(),
            totalBorrowShares: ILPRouter(lendingPool.router()).totalBorrowShares(),
            userBorrowShares: ILPRouter(lendingPool.router()).userBorrowShares(_user)
        });

        address borrowToken = ILPRouter(lendingPool.router()).borrowToken();
        uint256 borrowAssets =
            (borrowData.userBorrowShares * borrowData.totalBorrowAssets) / borrowData.totalBorrowShares;
        uint256 borrowDecimals = IERC20Metadata(borrowToken).decimals();

        return getTokenValue(borrowToken) * borrowAssets / 10 ** borrowDecimals;
    }
}
