// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";
import {ICreateLendingPoolBridgeRouter} from "../interfaces/ICreateLendingPoolBridgeRouter.sol";

contract CreateLendingPoolOrigin is IMessageRecipient, Ownable {
    error NotFactory();
    error NotMailbox();
    error ReceiverBridgeNotSet();
    error ConfigureBridgeNotSet();

    event CreateLendingPool(bytes32 messageId);
    event CrosschainLendingPoolConfigured(bytes32 messageId);
    event ReceivedMessage(uint32 indexed origin, bytes32 indexed sender, bytes indexed message);
    event CrosschainLendingPoolCreated(
        uint256 indexed origin, address indexed destinationLendingPool, bytes32 indexed sender
    );

    address public factory;

    constructor(address _factory) Ownable(msg.sender) {
        factory = _factory;
    }

    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    modifier onlyMailbox() {
        _onlyMailbox();
        _;
    }

    function createLendingPool(
        address _originLendingPool,
        address _collateralToken,
        address _borrowToken,
        uint256 _ltv,
        uint256[] memory _destinationChainIds
    ) external payable onlyFactory {
        address helperTestnet = IFactory(factory).helper();
        for (uint256 i = 0; i < _destinationChainIds.length; i++) {
            if (_destinationChainIds[i] != 0) {
                IHelperTestnet.ChainInfo memory helperDestination =
                    IHelperTestnet(helperTestnet).chains(_destinationChainIds[i]); // ** OTHER CHAIN
                IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);
                bytes memory message =
                    abi.encode(_originLendingPool, _collateralToken, _borrowToken, _ltv, _destinationChainIds.length);

                uint256 gasAmount =
                    IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);

                address receiverBridge =
                    ICreateLendingPoolBridgeRouter(factory).receiverBridges(_destinationChainIds[i]);
                if (receiverBridge == address(0)) revert ReceiverBridgeNotSet();
                bytes32 receiverAddress = bytes32(uint256(uint160(receiverBridge)));
                bytes32 messageId = IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, receiverAddress, message
                );

                emit CreateLendingPool(messageId);
            }
        }
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        (uint256 _destinationChainIdsLength, address _originLendingPool, address _destinationLendingPool) =
            abi.decode(_messageBody, (uint256, address, address));
        IFactory(factory).setPoolOtherChains(_originLendingPool, uint256(_origin), _destinationLendingPool);
        if (IFactory(factory).getPoolOtherChainsLength(_originLendingPool) == _destinationChainIdsLength) {
            IFactory.CrosschainPool[] memory poolOtherChains = IFactory(factory).poolOtherChains(_originLendingPool);
            bridgeSetPoolOtherChains(poolOtherChains);
        }
        emit CrosschainLendingPoolCreated(uint256(_origin), _destinationLendingPool, _sender);
    }

    function bridgeSetPoolOtherChains(IFactory.CrosschainPool[] memory _poolOtherChains) public onlyMailbox {
        address helperTestnet = IFactory(factory).helper();
        for (uint256 i = 0; i < _poolOtherChains.length; i++) {
            if (_poolOtherChains[i].chainId != block.chainid) {
                IHelperTestnet.ChainInfo memory helperDestination =
                    IHelperTestnet(helperTestnet).chains(_poolOtherChains[i].chainId);
                IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);

                bytes memory message = abi.encode(_poolOtherChains[i].lendingPoolAddress, _poolOtherChains);

                uint256 gasAmount =
                    IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);
                address configureBridge =
                    ICreateLendingPoolBridgeRouter(factory).configureBridges(_poolOtherChains[i].chainId);
                if (configureBridge == address(0)) revert ConfigureBridgeNotSet();
                bytes32 receiverConfigureBridgeAddress = bytes32(uint256(uint160(configureBridge)));
                bytes32 messageId = IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
                    helperDestination.domainId, receiverConfigureBridgeAddress, message
                );
                emit CrosschainLendingPoolConfigured(messageId);
            }
        }
    }

    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }

    function _onlyFactory() internal view {
        if (msg.sender != factory) revert NotFactory();
    }
}
