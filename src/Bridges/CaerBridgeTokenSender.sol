// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";
import {ITokenSwap} from "../interfaces/ITokenSwap.sol";
import {IFactory} from "../interfaces/IFactory.sol";

contract CaerBridgeTokenSender is Ownable {
    error SameChain();
    error TransferFailed();
    error MailboxNotSet();
    error InterchainGasPaymasterNotSet();
    error ReceiverBridgeNotSet();

    address public factory;
    address public token;
    address public receiverBridge; // ** OTHER CHAIN
    uint256 public chainId; // ** OTHER CHAIN

    constructor(address _factory, address _token, address _receiverBridge, uint256 _chainId) Ownable(msg.sender) {
        factory = _factory;
        receiverBridge = _receiverBridge;
        chainId = _chainId;
        token = _token;

        _validateConstructorParams();
    }

    function _validateConstructorParams() private view {
        if (receiverBridge == address(0)) revert ReceiverBridgeNotSet();
        if (block.chainid == chainId) revert SameChain();
    }

    // TODO: only lending pool allowed
    function bridge(uint256 _amount, address _recipient, address _token) external payable returns (bytes32) {
        address helperTestnet = IFactory(factory).helper();
        
        IHelperTestnet.ChainInfo memory helperDestination = IHelperTestnet(helperTestnet).chains(chainId); // ** OTHER CHAIN
        if (receiverBridge == address(0)) revert ReceiverBridgeNotSet();
        // TODO: Solver
        if (!IERC20(_token).transferFrom(msg.sender, address(this), _amount)) revert TransferFailed(); // TODO: BURN
        ITokenSwap(token).burn(_amount);

        // Encode payload
        bytes memory message = abi.encode(_recipient, _amount);

        IHelperTestnet.ChainInfo memory helperOrigin = IHelperTestnet(helperTestnet).chains(block.chainid);

        uint256 gasAmount =
            IInterchainGasPaymaster(helperOrigin.gasMaster).quoteGasPayment(helperDestination.domainId, _amount);
        bytes32 recipientAddress = bytes32(uint256(uint160(receiverBridge)));
        bytes32 messageId = IMailbox(helperOrigin.mailbox).dispatch{value: gasAmount}(
            helperDestination.domainId, recipientAddress, message
        );
        return messageId;
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }
}
