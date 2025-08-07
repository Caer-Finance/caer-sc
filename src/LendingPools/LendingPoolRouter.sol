// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFactory} from "../Interfaces/IFactory.sol";
import {IIsHealthy} from "../Interfaces/IIsHealthy.sol";
import {Position} from "../Position.sol";

// TODO: Mint Token from total assets
contract LendingPoolRouter {
    error ZeroAmount();
    error InsufficientShares();
    error InsufficientLiquidity();
    error NotLendingPool();
    error PositionAlreadyCreated();

    uint256 public totalSupplyAssets;
    uint256 public totalSupplyShares;
    uint256 public totalBorrowAssets;
    uint256 public totalBorrowShares;

    uint256 public lastAccrued;

    mapping(address => uint256) public userSupplyShares;
    mapping(address => uint256) public userBorrowShares;
    mapping(address => address) public addressPositions;

    address public lendingPool;
    address public factory;

    address public collateralToken;
    address public borrowToken;
    uint256 public ltv;

    constructor(address _lendingPool, address _factory, address _collateralToken, address _borrowToken, uint256 _ltv) {
        lendingPool = _lendingPool;
        factory = _factory;
        collateralToken = _collateralToken;
        borrowToken = _borrowToken;
        ltv = _ltv;
        lastAccrued = block.timestamp;
    }

    modifier onlyLendingPool() {
        _onlyLendingPool();
        _;
    }

    function _onlyLendingPool() internal view {
        if (msg.sender != lendingPool) revert NotLendingPool();
    }

    function supplyLiquidity(uint256 _amount, address _user) public onlyLendingPool returns (uint256 shares) {
        if (_amount == 0) revert ZeroAmount();
        shares = 0;
        if (totalSupplyAssets == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupplyShares) / totalSupplyAssets;
        }

        userSupplyShares[_user] += shares;
        totalSupplyShares += shares;
        totalSupplyAssets += _amount;

        return shares;
    }

    function withdrawLiquidity(uint256 _shares, address _user) public onlyLendingPool returns (uint256 amount) {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > userSupplyShares[_user]) revert InsufficientShares();

        amount = ((_shares * totalSupplyAssets) / totalSupplyShares);

        userSupplyShares[_user] -= _shares;
        totalSupplyShares -= _shares;
        totalSupplyAssets -= amount;

        if (totalSupplyAssets < totalBorrowAssets) {
            revert InsufficientLiquidity();
        }

        return amount;
    }

    function withdrawCollateral(address _user) public onlyLendingPool view {
        address isHealthy = IFactory(factory).isHealthy();
        if (userBorrowShares[_user] > 0) {
            IIsHealthy(isHealthy)._isHealthy(
                borrowToken,
                factory,
                addressPositions[_user],
                ltv,
                totalBorrowAssets,
                totalBorrowShares,
                userBorrowShares[_user]
            );
        }
    }

    function accrueInterest() public {
        // TODO: Make it dynamic interest rate
        uint256 borrowRate = 10;

        uint256 interestPerYear = (totalBorrowAssets * borrowRate) / 100;
        uint256 elapsedTime = block.timestamp - lastAccrued;
        uint256 interest = (interestPerYear * elapsedTime) / 365 days;
        totalSupplyAssets += interest;
        totalBorrowAssets += interest;
        lastAccrued = block.timestamp;
    }

    function borrowDebt(uint256 _amount, address _user)
        public
        onlyLendingPool
        returns (uint256 protocolFee, uint256 userAmount, uint256 shares)
    {
        if (_amount == 0) revert ZeroAmount();

        shares = 0;
        if (totalBorrowShares == 0) {
            shares = _amount;
        } else {
            shares = ((_amount * totalBorrowShares) / totalBorrowAssets);
        }
        userBorrowShares[_user] += shares;
        totalBorrowShares += shares;
        totalBorrowAssets += _amount;

        protocolFee = (_amount * 1e15) / 1e18; // 0.1%
        userAmount = _amount - protocolFee;

        if (totalBorrowAssets > totalSupplyAssets) {
            revert InsufficientLiquidity();
        }
        address isHealthy = IFactory(factory).isHealthy();
        IIsHealthy(isHealthy)._isHealthy(
            borrowToken,
            factory,
            addressPositions[_user],
            ltv,
            totalBorrowAssets,
            totalBorrowShares,
            userBorrowShares[_user]
        );

        return (protocolFee, userAmount, shares);
    }

    function repayWithSelectedToken(uint256 _shares, address _user)
        public
        onlyLendingPool
        returns (uint256 borrowAmount)
    {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > userBorrowShares[_user]) revert InsufficientShares();

        borrowAmount = ((_shares * totalBorrowAssets) / totalBorrowShares);
        userBorrowShares[_user] -= _shares;
        totalBorrowShares -= _shares;
        totalBorrowAssets -= borrowAmount;

        return borrowAmount;
    }

    function createPosition(address _user) public onlyLendingPool returns (address) {
        if (addressPositions[_user] != address(0)) revert PositionAlreadyCreated();
        // TODO: change to use position deployer
        Position position = new Position(collateralToken, borrowToken, address(this), factory);
        addressPositions[_user] = address(position);
        return address(position);
    }
}
