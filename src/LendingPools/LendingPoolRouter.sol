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
    error InsufficientCollateral();

    uint256 public totalSupplyAssets;
    uint256 public totalSupplyShares;
    uint256 public totalBorrowAssets;
    uint256 public totalBorrowShares;

    uint256 public lastAccrued;

    mapping(address => mapping(uint256 => uint256)) public userSupplyShares;
    mapping(address => mapping(uint256 => uint256)) public userBorrowShares;
    mapping(address => mapping(uint256 => uint256)) public userCollateral;

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

    function supplyLiquidity(uint256 _amount, uint256 _chainId, address _user)
        public
        onlyLendingPool
        returns (uint256 shares)
    {
        if (_amount == 0) revert ZeroAmount();
        shares = 0;
        if (totalSupplyAssets == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupplyShares) / totalSupplyAssets;
        }

        userSupplyShares[_user][_chainId] += shares;
        totalSupplyShares += shares;
        totalSupplyAssets += _amount;

        return shares;
    }

    function withdrawLiquidity(uint256 _shares, address _user) public onlyLendingPool returns (uint256 amount) {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > userSupplyShares[_user][block.chainid]) revert InsufficientShares();

        amount = ((_shares * totalSupplyAssets) / totalSupplyShares);

        userSupplyShares[_user][block.chainid] -= _shares;
        totalSupplyShares -= _shares;
        totalSupplyAssets -= amount;

        if (totalSupplyAssets < totalBorrowAssets) {
            revert InsufficientLiquidity();
        }

        return amount;
    }

    function supplyCollateral(uint256 _chainId, address _user, uint256 _amount) public onlyLendingPool {
        userCollateral[_user][_chainId] += _amount;
    }

    function withdrawCollateral(uint256 _amount, uint256 _chainId, address _user)
        public
        onlyLendingPool
        returns (uint256)
    {
        if (userCollateral[_user][_chainId] < _amount) revert InsufficientCollateral();

        userCollateral[_user][_chainId] -= _amount;

        if (userBorrowShares[_user][block.chainid] > 0) {
            address isHealthy = IFactory(factory).isHealthy();
            // ishealthy supply collateral
            IIsHealthy(isHealthy)._isHealthy(
                borrowToken,
                factory,
                addressPositions[_user],
                ltv,
                totalBorrowAssets,
                totalBorrowShares,
                userBorrowShares[_user][block.chainid]
            );
        }
        return userCollateral[_user][_chainId];
    }

    /**
     * @dev Calculate dynamic borrow rate based on utilization rate
     * Similar to AAVE's interest rate model
     * @return borrowRate The annual borrow rate in percentage (scaled by 100)
     */
    function calculateBorrowRate() public view returns (uint256 borrowRate) {
        if (totalSupplyAssets == 0) {
            return 500; // 5% base rate when no supply (scaled by 100)
        }

        // Calculate utilization rate (scaled by 10000 for precision)
        uint256 utilizationRate = (totalBorrowAssets * 10000) / totalSupplyAssets;

        // Interest rate model parameters
        uint256 baseRate = 200; // 2% base rate (scaled by 100)
        uint256 optimalUtilization = 8000; // 80% optimal utilization (scaled by 10000)
        uint256 rateAtOptimal = 1000; // 10% rate at optimal utilization (scaled by 100)
        uint256 maxRate = 5000; // 50% maximum rate (scaled by 100)

        if (utilizationRate <= optimalUtilization) {
            // Linear increase from base rate to optimal rate
            // Rate = baseRate + (utilizationRate * (rateAtOptimal - baseRate)) / optimalUtilization
            borrowRate = baseRate + ((utilizationRate * (rateAtOptimal - baseRate)) / optimalUtilization);
        } else {
            // Sharp increase after optimal utilization to discourage over-borrowing
            uint256 excessUtilization = utilizationRate - optimalUtilization;
            uint256 maxExcessUtilization = 10000 - optimalUtilization; // 20% (scaled by 10000)

            // Rate = rateAtOptimal + (excessUtilization * (maxRate - rateAtOptimal)) / maxExcessUtilization
            borrowRate = rateAtOptimal + ((excessUtilization * (maxRate - rateAtOptimal)) / maxExcessUtilization);
        }

        return borrowRate;
    }

    /**
     * @dev Get current utilization rate
     * @return utilizationRate The utilization rate in percentage (scaled by 100)
     */
    function getUtilizationRate() public view returns (uint256 utilizationRate) {
        if (totalSupplyAssets == 0) {
            return 0;
        }

        // Return utilization rate scaled by 100 (e.g., 8000 = 80.00%)
        utilizationRate = (totalBorrowAssets * 10000) / totalSupplyAssets;
        return utilizationRate;
    }

    /**
     * @dev Calculate supply rate based on borrow rate and utilization
     * Supply rate = Borrow rate * Utilization rate * (1 - reserve factor)
     * @return supplyRate The annual supply rate in percentage (scaled by 100)
     */
    function calculateSupplyRate() public view returns (uint256 supplyRate) {
        if (totalSupplyAssets == 0) {
            return 0;
        }

        uint256 borrowRate = calculateBorrowRate();
        uint256 utilizationRate = (totalBorrowAssets * 10000) / totalSupplyAssets;
        uint256 reserveFactor = 1000; // 10% reserve factor (scaled by 10000)

        // supplyRate = borrowRate * utilizationRate * (1 - reserveFactor) / 10000
        supplyRate = (borrowRate * utilizationRate * (10000 - reserveFactor)) / (10000 * 10000);

        return supplyRate;
    }

    function accrueInterest() public {
        // Use dynamic interest rate based on utilization
        uint256 borrowRate = calculateBorrowRate();

        uint256 interestPerYear = (totalBorrowAssets * borrowRate) / 10000; // borrowRate is scaled by 100
        uint256 elapsedTime = block.timestamp - lastAccrued;
        uint256 interest = (interestPerYear * elapsedTime) / 365 days;

        // Reserve factor - portion of interest that goes to protocol
        uint256 reserveFactor = 1000; // 10% (scaled by 10000)
        uint256 reserveInterest = (interest * reserveFactor) / 10000;
        uint256 supplierInterest = interest - reserveInterest;

        totalSupplyAssets += supplierInterest;
        totalBorrowAssets += interest;
        lastAccrued = block.timestamp;
    }

    function borrowDebt(uint256 _amount, address _user, uint256 _chainId)
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
        userBorrowShares[_user][_chainId] += shares;
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
            addressPositions[_user], // check position from other chain
            ltv,
            totalBorrowAssets,
            totalBorrowShares,
            userBorrowShares[_user][_chainId]
        );

        return (protocolFee, userAmount, shares);
    }

    function repayWithSelectedToken(uint256 _shares, address _user)
        public
        onlyLendingPool
        returns (uint256, uint256, uint256, uint256)
    {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > userBorrowShares[_user][block.chainid]) revert InsufficientShares();

        uint256 borrowAmount = ((_shares * totalBorrowAssets) / totalBorrowShares);
        userBorrowShares[_user][block.chainid] -= _shares;
        totalBorrowShares -= _shares;
        totalBorrowAssets -= borrowAmount;

        return (borrowAmount, userBorrowShares[_user][block.chainid], totalBorrowShares, totalBorrowAssets);
    }

    function createPosition(address _user) public onlyLendingPool returns (address) {
        if (addressPositions[_user] != address(0)) revert PositionAlreadyCreated();
        // TODO: change to use position deployer
        Position position = new Position(collateralToken, borrowToken, address(this), factory);
        addressPositions[_user] = address(position);
        return address(position);
    }

    function settlementWithdrawLiquidity(
        address _user,
        uint256 _chainId,
        uint256 _userSupplyShares,
        uint256 _totalSupplyShares,
        uint256 _totalSupplyAssets
    ) public {
        userSupplyShares[_user][_chainId] = _userSupplyShares;
        totalSupplyShares = _totalSupplyShares;
        totalSupplyAssets = _totalSupplyAssets;
    }

    function settlementSupplyLiquidity(
        uint256 _userSupplyShares,
        uint256 _totalSupplyShares,
        uint256 _totalSupplyAssets,
        address _user,
        uint256 _chainId
    ) public {
        userSupplyShares[_user][_chainId] = _userSupplyShares;
        totalSupplyShares = _totalSupplyShares;
        totalSupplyAssets = _totalSupplyAssets;
    }

    function settlementBorrowDebt(
        uint256 _userBorrowShares,
        uint256 _totalBorrowShares,
        uint256 _totalBorrowAssets,
        address _user,
        uint256 _chainId
    ) public {
        userBorrowShares[_user][_chainId] = _userBorrowShares;
        totalBorrowShares = _totalBorrowShares;
        totalBorrowAssets = _totalBorrowAssets;
    }

    function settlementBorrowDebtSuccess(
        uint256 _userBorrowShare,
        uint256 _totalBorrowShares,
        uint256 _chainId,
        address _user
    ) public {
        userBorrowShares[_user][_chainId] = _userBorrowShare;
        totalBorrowShares = _totalBorrowShares;
    }

    function settlementRepayDebt(
        uint256 _userBorrowShare,
        uint256 _totalBorrowShares,
        uint256 _totalBorrowAssets,
        address _user,
        address _lendingPoolOrigin,
        uint256 _chainId
    ) public {
        userBorrowShares[_user][_chainId] = _userBorrowShare;
        totalBorrowShares = _totalBorrowShares;
        totalBorrowAssets = _totalBorrowAssets;
    }

    function settlementSupplyCollateral(uint256 _userCollateral, address _user, uint256 _chainId) public {
        userCollateral[_user][_chainId] = _userCollateral;
    }

    function settlementWithdrawCollateral(uint256 _amount, address _user, uint256 _chainId) public {
        userCollateral[_user][_chainId] = _amount;
    }
}
