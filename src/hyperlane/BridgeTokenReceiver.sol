// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IInterchainSecurityModule} from "@hyperlane-xyz/interfaces/IInterchainSecurityModule.sol";
import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
// import {ITokenSwap} from "./interfaces/ITokenSwap.sol";
import {IWrappedToken} from "./interfaces/IWrappedToken.sol";

contract BridgeTokenReceiver is IMessageRecipient {
    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

    address public mailbox;
    address public token;

    constructor(address _mailbox, address _token) {
        mailbox = _mailbox;
        token = _token;
    }

    modifier onlyMailbox() {
        require(msg.sender == address(mailbox), "MailboxClient: sender not mailbox");
        _;
    }

    // Fungsi ini dipanggil oleh Hyperlane saat pesan datang
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        (address recipient, uint256 amount) = abi.decode(_messageBody, (address, uint256));
        // Mint wrapped token
        // ITokenSwap(token).mintMock(recipient, amount);
        IWrappedToken(token).mint(recipient, amount);
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }
}
