// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {ITokenSwap} from "./interfaces/ITokenSwap.sol";
import {IHelperTestnet} from "./interfaces/IHelperTestnet.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract CaerBridgeTokenReceiver is IMessageRecipient, Ownable {
    error MailboxNotSet();
    error NotMailbox();

    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

    address public mailbox;
    address public token;
    address public helperTestnet;

    constructor(address _helperTestnet, address _token) Ownable(msg.sender) {
        helperTestnet = _helperTestnet;
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (helper.mailbox == address(0)) revert MailboxNotSet();
        mailbox = helper.mailbox;
        token = _token;
    }

    modifier onlyMailbox() {
        _onlyMailbox();
        _;
    }

    function _onlyMailbox() internal view {
        if (msg.sender != address(mailbox)) revert NotMailbox();
    }

    // Called by Hyperlane when message arrives
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        (address recipient, uint256 amount) = abi.decode(_messageBody, (address, uint256));
        // ITokenSwap(token).mint(recipient, amount);
        ITokenSwap(token).mint(recipient, amount);
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }

    function setHelperTestnet(address _helperTestnet) external onlyOwner {
        helperTestnet = _helperTestnet;
    }
}
