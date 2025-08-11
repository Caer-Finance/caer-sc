// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILendingPool} from "../Interfaces/ILendingPool.sol";
import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";
import {ILPRouter} from "../Interfaces/ILPRouter.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LendingPoolExecuteDestination is IMessageRecipient {
    enum ExecuteType {
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
        if (_executeType == ExecuteType.WithdrawLiquidity) {
            withdrawLiquidity(_origin, _sender, _message, _lendingPoolDestination);
        }
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }

    function withdrawLiquidity(uint32 _origin, bytes32 _sender, bytes memory _message, address _lendingPoolDestination)
        public
    {
        address router = ILendingPool(_lendingPoolDestination).router();
        (
            uint256 _amount,
            ,
            address _user,
            uint256 _userSupplyShares,
            uint256 _totalSupplyShares,
            uint256 _totalSupplyAssets,
        ) = abi.decode(_message, (uint256, uint256, address, uint256, uint256, uint256, address));
        if (_amount > IERC20(ILPRouter(router).borrowToken()).balanceOf(address(this))) {
            IHelperTestnet.ChainInfo memory helperOrigin =
                IHelperTestnet(IFactory(factory).helper()).chains(block.chainid);
            IMailbox(helperOrigin.mailbox).dispatch{value: 0}(
                uint32(_origin), _sender, abi.encode(_message, _lendingPoolDestination, ExecuteType.WithdrawLiquidity)
            );
        } else {
            ILPRouter(router).settlementWithdrawLiquidity(
                _user, _userSupplyShares, _totalSupplyShares, _totalSupplyAssets
            );
            ILendingPool(_lendingPoolDestination).withdrawLiquidity(_amount, _user, uint256(_origin), true);
        }
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }
}
