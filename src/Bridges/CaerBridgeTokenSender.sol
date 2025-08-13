// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBridgeRouter} from "../interfaces/IBridgeRouter.sol";

contract CaerBridgeTokenSender is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error SameChain();
    error TransferFailed();
    error MailboxNotSet();
    error InterchainGasPaymasterNotSet();
    error ReceiverBridgeNotSet();

    address public factory;
    address public token;
    // address public receiverBridge; // ** OTHER CHAIN
    uint256 public chainId; // ** OTHER CHAIN

    constructor(address _factory, address _token, uint256 _chainId) Ownable(msg.sender) {
        factory = _factory;
        // receiverBridge = _receiverBridge;
        chainId = _chainId;
        token = _token;

        _validateConstructorParams();
    }

    function _validateConstructorParams() private view {
        // if (receiverBridge == address(0)) revert ReceiverBridgeNotSet();
        if (block.chainid == chainId) revert SameChain();
    }

    // TODO: only lending pool allowed
    function bridge(
        uint256 _amount,
        address _recipient,
        uint256 _shares,
        address _lendingPoolOrigin,
        address _lendingPoolDestination,
        uint256 _chainId
    ) external payable nonReentrant returns (bytes32) {
        address receiverBridge = IBridgeRouter(IFactory(factory).bridgeRouter()).receiverBridges(_chainId);
        bytes32 recipientAddress = bytes32(uint256(uint160(receiverBridge)));
        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(IFactory(factory).helper()).chains(block.chainid);
        bytes memory message =
            abi.encode(_amount, _shares, _recipient, _lendingPoolOrigin, _lendingPoolDestination, _chainId);
        bytes32 messageId =
            IMailbox(helperOrigin.mailbox).dispatch{value: 0}(uint32(_chainId), recipientAddress, message);
        return messageId;
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }
}
