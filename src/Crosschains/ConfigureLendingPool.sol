// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";

contract ConfigureLendingPool is IMessageRecipient {
    error NotMailbox();

    event ReceivedMessage(uint32 indexed origin, bytes32 indexed sender, bytes messageBody);

    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    modifier onlyMailbox() {
        _onlyMailbox();
        _;
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        (address lendingPoolKey, IFactory.CrosschainPool[] memory poolOtherChains) =
            abi.decode(_messageBody, (address, IFactory.CrosschainPool[]));
        for (uint256 i = 0; i < poolOtherChains.length; i++) {
            IFactory.CrosschainPool memory poolOtherChain = poolOtherChains[i];
            IFactory(factory).setPoolOtherChains(
                lendingPoolKey, poolOtherChain.chainId, poolOtherChain.lendingPoolAddress
            );
        }
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }

    function _onlyMailbox() internal view {
        address helperTestnet = IFactory(factory).helper();
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }
}
