// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";

contract CreateLendingPoolDestination is IMessageRecipient, Ownable {
    error NotFactory();
    error NotMailbox();

    event ReceivedMessage(uint32 indexed origin, bytes32 indexed sender, bytes indexed message);

    address public factory;

    constructor(address _factory) Ownable(msg.sender) {
        factory = _factory;
    }

    modifier onlyMailbox() {
        _onlyMailbox();
        _;
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        (
            address _originLendingPool,
            address _collateralToken,
            address _borrowToken,
            uint256 _ltv,
            uint256 _destinationChainIdsLength
        ) = abi.decode(_messageBody, (address, address, address, uint256, uint256));
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 0;
        address lendingPool = IFactory(factory).createLendingPool{value: 0}(_collateralToken, _borrowToken, _ltv, chainIds);
        sendToOrigin(uint256(_origin), _destinationChainIdsLength, _originLendingPool, lendingPool, _sender);
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }

    function sendToOrigin(
        uint256 _chainId,
        uint256 _destinationChainIdsLength,
        address _originLendingPool,
        address _lendingPool,
        bytes32 _sender
    ) public payable onlyMailbox returns (bytes32) {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(_chainId); // ** OTHER CHAIN
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);

        bytes memory message = abi.encode(_destinationChainIdsLength, _originLendingPool, _lendingPool);

        uint256 gasAmount =
            IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, 0);

        bytes32 messageId =
            IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(helperDestination.domainId, _sender, message);
        return messageId;
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }
}
