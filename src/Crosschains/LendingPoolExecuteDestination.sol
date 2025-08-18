// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILendingPool} from "../Interfaces/ILendingPool.sol";
import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";
import {ILPRouter} from "../Interfaces/ILPRouter.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract LendingPoolExecuteDestination is IMessageRecipient, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum ExecuteType {
        CreateLendingPool,
        WithdrawLiquidity,
        SupplyLiquidity,
        BorrowDebt,
        RepayDebt,
        SupplyCollateral,
        WithdrawCollateral
    }

    error NotMailbox();

    event ReceivedMessage(uint32 origin, bytes32 sender, bytes messageBody);

    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    modifier onlyMailbox() {
        _onlyMailbox();
        _;
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        (bytes memory _message, address _lendingPoolDestination, ExecuteType _executeType) =
            abi.decode(_messageBody, (bytes, address, ExecuteType));
        if (_executeType == ExecuteType.CreateLendingPool) {
            _createLendingPool(_origin, _sender, _message);
        } else if (_executeType == ExecuteType.SupplyLiquidity) {
            _supplyLiquidity(_message, _lendingPoolDestination);
        } else if (_executeType == ExecuteType.WithdrawLiquidity) {
            _withdrawLiquidity(_origin, _sender, _message, _lendingPoolDestination);
        } else if (_executeType == ExecuteType.SupplyCollateral) {
            _supplyCollateral(_message, _lendingPoolDestination);
        } else if (_executeType == ExecuteType.WithdrawCollateral) {
            _withdrawCollateral(_message, _lendingPoolDestination);
        } else if (_executeType == ExecuteType.BorrowDebt) {
            _borrowDebt(_origin, _sender, _message, _lendingPoolDestination);
        } else if (_executeType == ExecuteType.RepayDebt) {
            _repayWithSelectedToken(_message, _lendingPoolDestination);
        }
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }

    function _createLendingPool(uint32 _origin, bytes32 _sender, bytes memory _message) internal nonReentrant {
        (, address _collateralToken, address _borrowToken, uint256 _ltv, uint256[] memory _chainIds) =
            abi.decode(_message, (address, address, address, uint256, uint256[]));
        address lendingPool = IFactory(factory).createLendingPool(_collateralToken, _borrowToken, _ltv, _chainIds);
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(IFactory(factory).helper()).chains(block.chainid);
        IMailbox(helperOrigin.mailbox).dispatch{value: 0}(
            uint32(_origin), _sender, abi.encode(_message, lendingPool, ExecuteType.CreateLendingPool)
        );
    }

    function _supplyLiquidity(bytes memory _message, address _lendingPoolDestination) internal nonReentrant {
        (
            ,
            uint256 _userBorrowShares,
            uint256 _totalSupplyShares,
            uint256 _totalSupplyAssets,
            address _user,
            ,
            ,
            uint256 _chainId
        ) = abi.decode(_message, (uint256, uint256, uint256, uint256, address, address, uint256[], uint256));
        ILPRouter(ILendingPool(_lendingPoolDestination).router()).settlementSupplyLiquidity(
            _userBorrowShares, _totalSupplyShares, _totalSupplyAssets, _user, _chainId
        );
    }

    function _borrowDebt(uint32 _origin, bytes32 _sender, bytes memory _message, address _lendingPoolDestination)
        internal
        nonReentrant
    {
        (
            uint256 _amount,
            uint256 _userBorrowShares,
            uint256 _totalBorrowShares,
            uint256 _totalBorrowAssets,
            address _user,
            ,
            ,
            uint256 _chainId
        ) = abi.decode(_message, (uint256, uint256, uint256, uint256, address, address, uint256[], uint256));
        ILPRouter(ILendingPool(_lendingPoolDestination).router()).settlementBorrowDebt(
            _userBorrowShares, _totalBorrowShares, _totalBorrowAssets, _user, _chainId
        );
        if (block.chainid == _chainId) {
            ILendingPool(_lendingPoolDestination).borrowDebtByBridge(_amount, _user);
        }
    }

    function _withdrawLiquidity(uint32 _origin, bytes32 _sender, bytes memory _message, address _lendingPoolDestination)
        internal
        nonReentrant
    {
        (
            uint256 _amount,
            ,
            uint256 _userSupplyShares,
            uint256 _totalSupplyShares,
            uint256 _totalSupplyAssets,
            address _user,
            ,
            ,
            uint256 _chainId
        ) = abi.decode(_message, (uint256, uint256, uint256, uint256, uint256, address, address, uint256[], uint256));
        // TODO: if liquidity is not enough, back to origin chain
        ILPRouter(ILendingPool(_lendingPoolDestination).router()).settlementWithdrawLiquidity(
            _user, _chainId, _userSupplyShares, _totalSupplyShares, _totalSupplyAssets
        );
        if (_chainId == block.chainid) {
            ILendingPool(_lendingPoolDestination).withdrawLiquidityByBridge(_amount, _user);
        }
    }

    function _supplyCollateral(bytes memory _message, address _lendingPoolDestination) internal nonReentrant {
        (, uint256 _userCollateral, address _user,, uint256 _chainId) =
            abi.decode(_message, (uint256, uint256, address, address, uint256));
        ILPRouter(ILendingPool(_lendingPoolDestination).router()).settlementSupplyCollateral(
            _userCollateral, _user, _chainId
        );
    }

    function _withdrawCollateral(bytes memory _message, address _lendingPoolDestination) internal nonReentrant {
        (uint256 _userCollateral, uint256 _amount,, address _user,, uint256 _chainId) =
            abi.decode(_message, (uint256, uint256, uint256[], address, address, uint256));
        ILPRouter(ILendingPool(_lendingPoolDestination).router()).settlementWithdrawCollateral(
            _userCollateral, _user, _chainId
        );

        if (_chainId == block.chainid) {
            ILendingPool(_lendingPoolDestination).withdrawCollateralByBridge(_amount, _user);
        }
    }

    function _repayWithSelectedToken(bytes memory _message, address _lendingPoolDestination) internal nonReentrant {
        (
            ,
            uint256 _userBorrowShare,
            uint256 _totalBorrowShares,
            uint256 _totalBorrowAssets,
            address _user,
            address _lendingPoolOrigin,
            ,
            ,
            uint256 _chainId
        ) = abi.decode(_message, (uint256, uint256, uint256, uint256, address, address, address, uint256[], uint256));
        ILPRouter(ILendingPool(_lendingPoolDestination).router()).settlementRepayDebt(
            _userBorrowShare, _totalBorrowShares, _totalBorrowAssets, _user, _lendingPoolOrigin, _chainId
        );
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }
}
