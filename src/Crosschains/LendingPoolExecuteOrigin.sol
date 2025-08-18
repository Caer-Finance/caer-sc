// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IHelperTestnet} from "../Interfaces/IHelperTestnet.sol";
import {IFactory} from "../Interfaces/IFactory.sol";
import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IBridgeRouter} from "../Interfaces/IBridgeRouter.sol";

contract LendingPoolExecuteOrigin is IMessageRecipient {
    error NotMailbox();
    error LendingPoolNotSet();
    error ExecuteBridgeNotSet();
    error ConfigureBridgeNotSet();

    event Execute(bytes messageId);
    event ReceivedMessage(uint32 origin, bytes32 sender, bytes messageBody);

    enum ExecuteType {
        CreateLendingPool,
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
        if (_executeType == ExecuteType.CreateLendingPool) {
            _createLendingPool(_message, _chainIds);
        } else if (_executeType == ExecuteType.SupplyLiquidity) {
            _supplyLiquidity(_message); // passing message that have supply liquidity
        } else if (_executeType == ExecuteType.WithdrawLiquidity) {
            _withdrawLiquidity(_message); // onlyone chainId allowed
        } else if (_executeType == ExecuteType.SupplyCollateral) {
            _supplyCollateral(_message);
        } else if (_executeType == ExecuteType.WithdrawCollateral) {
            _withdrawCollateral(_message);
        } else if (_executeType == ExecuteType.BorrowDebt) {
            _borrowDebt(_message);
        } else if (_executeType == ExecuteType.RepayDebt) {
            _repayWithSelectedToken(_message);
        }
    }

    function _createLendingPool(bytes memory _message, uint256[] memory _chainIds) internal {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            if (_chainIds[i] != 0 && _chainIds[i] != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainIds[i]); // ** OTHER CHAIN
                bytes memory message = abi.encode(_message, address(0), ExecuteType.CreateLendingPool);
                // uint256 gasAmount =
                //     IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                uint256 gasAmount = 0;
                address executeBridge = IBridgeRouter(IFactory(factory).bridgeRouter()).executeBridges(_chainIds[i]);
                if (executeBridge == address(0)) revert ExecuteBridgeNotSet();
                bytes32 executeAddress = bytes32(uint256(uint160(executeBridge)));
                IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, executeAddress, message
                );

                emit Execute(message);
            }
        }
    }

    function _supplyLiquidity(bytes memory _message) internal {
        (,,,,, address _lendingPoolOrigin, uint256[] memory _chainIds,) =
            abi.decode(_message, (uint256, uint256, uint256, uint256, address, address, uint256[], uint256));
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            if (_chainIds[i] != 0 && _chainIds[i] != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainIds[i]);
                address lendingPoolDestination =
                    IFactory(factory).getPoolOtherChainsByChainId(_lendingPoolOrigin, _chainIds[i]);
                bytes memory message = abi.encode(_message, lendingPoolDestination, ExecuteType.SupplyLiquidity);
                // uint256 gasAmount =
                // IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                uint256 gasAmount = 0;
                address executeBridge = IBridgeRouter(IFactory(factory).bridgeRouter()).executeBridges(_chainIds[i]);
                if (executeBridge == address(0)) revert ExecuteBridgeNotSet();
                bytes32 executeAddress = bytes32(uint256(uint160(executeBridge)));
                IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, executeAddress, message
                );
                emit Execute(message);
            }
        }
    }

    function _withdrawLiquidity(bytes memory _message) internal {
        address helperTestnet = IFactory(factory).helper();
        (,,,,,, address _lendingPoolOrigin, uint256[] memory _chainIds,) =
            abi.decode(_message, (uint256, uint256, uint256, uint256, uint256, address, address, uint256[], uint256));
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            if (_chainIds[i] != 0 && _chainIds[i] != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainIds[i]); // ** OTHER CHAIN
                address lendingPoolDestination =
                    IFactory(factory).getPoolOtherChainsByChainId(_lendingPoolOrigin, _chainIds[i]);
                if (lendingPoolDestination == address(0)) revert LendingPoolNotSet();
                bytes memory message = abi.encode(_message, lendingPoolDestination, ExecuteType.WithdrawLiquidity);
                // uint256 gasAmount =
                //     IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                uint256 gasAmount = 0;
                address executeBridge = IBridgeRouter(IFactory(factory).bridgeRouter()).executeBridges(_chainIds[i]);
                if (executeBridge == address(0)) revert ExecuteBridgeNotSet();
                bytes32 executeAddress = bytes32(uint256(uint160(executeBridge)));
                IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, executeAddress, message
                );
                emit Execute(message);
            }
        }
    }

    function _borrowDebt(bytes memory _message) internal {
        address helperTestnet = IFactory(factory).helper();
        (,,,,, address _lendingPoolOrigin, uint256[] memory _chainIds,) =
            abi.decode(_message, (uint256, uint256, uint256, uint256, address, address, uint256[], uint256));
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            if (_chainIds[i] != 0 && _chainIds[i] != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainIds[i]); // ** OTHER CHAIN
                address lendingPoolDestination =
                    IFactory(factory).getPoolOtherChainsByChainId(_lendingPoolOrigin, _chainIds[i]);
                bytes memory message = abi.encode(_message, lendingPoolDestination, ExecuteType.BorrowDebt);
                // uint256 gasAmount =
                //     IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                uint256 gasAmount = 0;
                address executeBridge = IBridgeRouter(IFactory(factory).bridgeRouter()).executeBridges(_chainIds[i]);
                if (executeBridge == address(0)) revert ExecuteBridgeNotSet();
                bytes32 executeAddress = bytes32(uint256(uint160(executeBridge)));

                IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, executeAddress, message
                );
                emit Execute(message);
            }
        }
    }

    function _supplyCollateral(bytes memory _message) internal {
        address helperTestnet = IFactory(factory).helper();
        (,,, address _lendingPoolOrigin, uint256[] memory _chainIds,) =
            abi.decode(_message, (uint256, uint256, address, address, uint256[], uint256));
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            if (_chainIds[i] != 0 && _chainIds[i] != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainIds[i]); // ** OTHER CHAIN
                address lendingPoolDestination =
                    IFactory(factory).getPoolOtherChainsByChainId(_lendingPoolOrigin, _chainIds[i]);
                if (lendingPoolDestination == address(0)) revert LendingPoolNotSet();
                bytes memory message = abi.encode(_message, lendingPoolDestination, ExecuteType.SupplyCollateral);
                // uint256 gasAmount =
                //     IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                uint256 gasAmount = 0;
                address executeBridge = IBridgeRouter(IFactory(factory).bridgeRouter()).executeBridges(_chainIds[i]);
                if (executeBridge == address(0)) revert ExecuteBridgeNotSet();
                bytes32 executeAddress = bytes32(uint256(uint160(executeBridge)));
                IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, executeAddress, message
                );
                emit Execute(message);
            }
        }
    }

    function _withdrawCollateral(bytes memory _message) internal {
        address helperTestnet = IFactory(factory).helper();
        (,,, address _lendingPoolOrigin, uint256[] memory _chainIds,) =
            abi.decode(_message, (uint256, uint256, address, address, uint256[], uint256));
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            if (_chainIds[i] != 0 && _chainIds[i] != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainIds[i]); // ** OTHER CHAIN
                address lendingPoolDestination =
                    IFactory(factory).getPoolOtherChainsByChainId(_lendingPoolOrigin, _chainIds[i]);
                if (lendingPoolDestination == address(0)) revert LendingPoolNotSet();
                bytes memory message = abi.encode(_message, lendingPoolDestination, ExecuteType.WithdrawCollateral);
                // uint256 gasAmount =
                //     IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                uint256 gasAmount = 0;
                address executeBridge = IBridgeRouter(IFactory(factory).bridgeRouter()).executeBridges(_chainIds[i]);
                if (executeBridge == address(0)) revert ExecuteBridgeNotSet();
                bytes32 executeAddress = bytes32(uint256(uint160(executeBridge)));
                IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, executeAddress, message
                );
                emit Execute(message);
            }
        }
    }

    function _repayWithSelectedToken(bytes memory _message) internal {
        address helperTestnet = IFactory(factory).helper();
        (,,,,, address _lendingPoolOrigin,, uint256[] memory _chainIds,) =
            abi.decode(_message, (uint256, uint256, uint256, uint256, address, address, address, uint256[], uint256));
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            if (_chainIds[i] != 0 && _chainIds[i] != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainIds[i]); // ** OTHER CHAIN
                address lendingPoolDestination =
                    IFactory(factory).getPoolOtherChainsByChainId(_lendingPoolOrigin, _chainIds[i]);
                if (lendingPoolDestination == address(0)) revert LendingPoolNotSet();
                bytes memory message = abi.encode(_message, lendingPoolDestination, ExecuteType.RepayDebt);
                // uint256 gasAmount =
                //     IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                uint256 gasAmount = 0;
                address executeBridge = IBridgeRouter(IFactory(factory).bridgeRouter()).executeBridges(_chainIds[i]);
                if (executeBridge == address(0)) revert ExecuteBridgeNotSet();
                bytes32 executeAddress = bytes32(uint256(uint160(executeBridge)));
                IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, executeAddress, message
                );
                emit Execute(message);
            }
        }
    }

    // *** SETTLEMENT
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        // TODO: standarize the bytes decoding
        (bytes memory _message, address _lendingPoolDestination, ExecuteType _executeType) =
            abi.decode(_messageBody, (bytes, address, ExecuteType));
        if (_executeType == ExecuteType.CreateLendingPool) {
            _handleCreateLendingPool(_message, uint256(_origin), _lendingPoolDestination);
        }
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }
    // *******************

    function _handleCreateLendingPool(bytes memory _message, uint256 _chainId, address _lendingPoolDestination)
        internal
    {
        (address _lendingPoolOrigin,,,, uint256[] memory _chainIds) =
            abi.decode(_message, (address, address, address, uint256, uint256[]));
        IFactory(factory).setPoolOtherChains(_lendingPoolOrigin, _chainId, _lendingPoolDestination);
        IFactory(factory).setLendingPoolInfo(_lendingPoolDestination, _chainId);
        if (IFactory(factory).getPoolOtherChainsLength(_lendingPoolOrigin) == _chainIds.length) {
            _bridgeSetPoolOtherChains(IFactory(factory).poolOtherChains(_lendingPoolOrigin));
        }
    }

    function _bridgeSetPoolOtherChains(IFactory.CrosschainPool[] memory _poolOtherChains) internal {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
        for (uint256 i = 0; i < _poolOtherChains.length; i++) {
            if (_poolOtherChains[i].chainId != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination =
                    IHelperTestnet(helperTestnet).chains(_poolOtherChains[i].chainId);
                bytes memory message = abi.encode(_poolOtherChains[i].lendingPoolAddress, _poolOtherChains);
                // uint256 gasAmount =
                //     IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                uint256 gasAmount = 0;
                address configureBridge =
                    IBridgeRouter(IFactory(factory).bridgeRouter()).configureBridges(_poolOtherChains[i].chainId);
                if (configureBridge == address(0)) revert ConfigureBridgeNotSet();
                bytes32 receiverConfigureBridgeAddress = bytes32(uint256(uint160(configureBridge)));
                IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, receiverConfigureBridgeAddress, message
                );
                emit Execute(message);
            }
        }
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }
}
