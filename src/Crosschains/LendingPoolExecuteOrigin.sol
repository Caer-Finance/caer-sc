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
        bytes messageBody
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

    function execute(bytes memory _message, uint256[] memory _chainIds, ExecuteType _executeType) public payable {
        if (_executeType == ExecuteType.WithdrawLiquidity) {
            _withdrawLiquidity(_message, _chainIds[0]); // onlyone chainId allowed
        }
        // else if (_executeType == ExecuteType.BorrowDebt) {
        //     _borrowDebt(_message, _chainIds[0]);
        // }
    }

    function _withdrawLiquidity(bytes memory _message, uint256 _chainId) internal {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainId); // ** OTHER CHAIN
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);

        (,,,,,,, address _lendingPoolOrigin) =
            abi.decode(_message, (uint256, uint256, address, uint256, uint256, uint256, uint256, address));
        address lendingPoolDestination = IFactory(factory).getPoolOtherChainsByChainId(_lendingPoolOrigin, _chainId);
        if (lendingPoolDestination == address(0)) revert LendingPoolNotSet();

        bytes memory message = abi.encode(_message, lendingPoolDestination, ExecuteType.WithdrawLiquidity);

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
        (bytes memory _message,, ExecuteType _executeType) = abi.decode(_messageBody, (bytes, address, ExecuteType));
        if (_executeType == ExecuteType.WithdrawLiquidity) {
            _handleWithdrawLiquidity(_message);
        }
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }

    function _handleWithdrawLiquidity(bytes memory _message) internal {
        (
            ,
            ,
            address _user,
            uint256 _userSupplyShares,
            uint256 _totalSupplyShares,
            uint256 _totalSupplyAssets,
            address _lendingPoolOrigin
        ) = abi.decode(_message, (uint256, uint256, address, uint256, uint256, uint256, address));
        address router = ILendingPool(_lendingPoolOrigin).router();
        ILPRouter(router).settlementWithdrawLiquidity(_user, _userSupplyShares, _totalSupplyShares, _totalSupplyAssets);
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }
}
