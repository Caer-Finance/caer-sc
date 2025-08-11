// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILendingPool} from "../Interfaces/ILendingPool.sol";
import {IHelperTestnet} from "../Interfaces/IHelperTestnet.sol";
import {IFactory} from "../Interfaces/IFactory.sol";
import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {ICreateLendingPoolBridgeRouter} from "../Interfaces/ICreateLendingPoolBridgeRouter.sol";
import {ILPRouter} from "../Interfaces/ILPRouter.sol";

contract LendingPoolExecuteOrigin is IMessageRecipient {
    error NotMailbox();
    error LendingPoolNotSet();
    error ExecuteBridgeNotSet();

    event Execute(bytes32 messageId);
    event ReceivedMessage(
        uint32 origin,
        bytes32 sender,
        bytes messageBody,
        uint256 shares,
        address user,
        address lendingPool,
        address lendingPoolDestination,
        ExecuteType executeType
    );

    enum ExecuteType {
        WithdrawLiquidity,
        SupplyLiquidity,
        BorrowDebt,
        RepayDebt,
        SupplyCollateral,
        WithdrawCollateral
    }

    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    modifier onlyMailbox() {
        _onlyMailbox();
        _;
    }

    function execute(
        uint256 _shares,
        address _user,
        address _lendingPoolOrigin,
        uint256 _chainId,
        ExecuteType _executeType
    ) public payable {
        if (_executeType == ExecuteType.WithdrawLiquidity) {
            _withdrawLiquidity(_shares, _user, _lendingPoolOrigin, _chainId);
        }
    }

    function _withdrawLiquidity(uint256 _shares, address _user, address _lendingPoolOrigin, uint256 _chainId)
        internal
    {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainId); // ** OTHER CHAIN
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);

        address lendingPoolDestination;

        for (uint256 i = 0; i < IFactory(factory).poolOtherChains(_lendingPoolOrigin).length; i++) {
            if (IFactory(factory).poolOtherChains(_lendingPoolOrigin)[i].chainId == _chainId) {
                lendingPoolDestination = IFactory(factory).poolOtherChains(_lendingPoolOrigin)[i].lendingPoolAddress;
            }
        }
        if (lendingPoolDestination == address(0)) revert LendingPoolNotSet();

        bytes memory message =
            abi.encode(_shares, _user, _lendingPoolOrigin, lendingPoolDestination, ExecuteType.WithdrawLiquidity);

        uint256 gasAmount =
            IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
        address executeBridge = ICreateLendingPoolBridgeRouter(factory).executeBridges(_chainId);
        if (executeBridge == address(0)) revert ExecuteBridgeNotSet();
        bytes32 executeAddress = bytes32(uint256(uint160(executeBridge)));
        bytes32 messageId = IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
            helperDestination.domainId, executeAddress, message
        );
        emit Execute(messageId);
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        // TODO: standarize the bytes decoding
        (
            uint256 _shares,
            address _user,
            address _lendingPoolOrigin,
            address _lendingPoolDestination,
            ExecuteType _executeType
        ) = abi.decode(_messageBody, (uint256, address, address, address, ExecuteType));
        if (_executeType == ExecuteType.WithdrawLiquidity) {
            address router = ILendingPool(_lendingPoolOrigin).router();
            ILPRouter(router).refundWithdrawLiquidity(_shares, _user);
            emit ReceivedMessage(
                _origin,
                _sender,
                _messageBody,
                _shares,
                _user,
                _lendingPoolOrigin,
                _lendingPoolDestination,
                _executeType
            );
        }
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }
}
