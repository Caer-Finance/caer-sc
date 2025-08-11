// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILendingPool} from "../Interfaces/ILendingPool.sol";
import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";
import {ILPRouter} from "../Interfaces/ILPRouter.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";

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

    event ReceivedMessage(
        uint32 origin,
        bytes32 sender,
        bytes messageBody,
        uint256 shares,
        address user,
        address lendingPoolOrigin,
        address lendingPoolDestination,
        ExecuteType executeType
    );

    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    modifier onlyMailbox() {
        _onlyMailbox();
        _;
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        (
            uint256 _shares,
            address _user,
            address _lendingPoolOrigin,
            address _lendingPoolDestination,
            ExecuteType _executeType
        ) = abi.decode(_messageBody, (uint256, address, address, address, ExecuteType));
        if (_executeType == ExecuteType.WithdrawLiquidity) {
            withdrawLiquidity(_origin, _sender, _messageBody, _shares, _lendingPoolDestination, _user);
        }
        emit ReceivedMessage(
            _origin, _sender, _messageBody, _shares, _user, _lendingPoolOrigin, _lendingPoolDestination, _executeType
        );
    }

    function withdrawLiquidity(
        uint256 _chainId,
        bytes32 _sender,
        bytes calldata _messageBody,
        uint256 _shares,
        address _lendingPoolDestination,
        address _user
    ) public returns (uint256 amount) {
        address router = ILendingPool(_lendingPoolDestination).router();
        if (
            _shares > ILPRouter(router).totalSupplyShares()
                || ILPRouter(router).totalSupplyAssets() < ILPRouter(router).totalBorrowAssets()
        ) {
            // balikin ke origin
            address helperTestnet = IFactory(factory).helper();
            IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
            uint256 gasAmount = IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(uint32(_chainId), 0);
            IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(uint32(_chainId), _sender, _messageBody);
        } else {
            amount = ((_shares * ILPRouter(router).totalSupplyAssets()) / ILPRouter(router).totalSupplyShares());
            ILendingPool(_lendingPoolDestination).withdrawLiquidity(_shares, _user, _chainId, true);
        }
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }
}
