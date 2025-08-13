// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMessageRecipient} from "@hyperlane-xyz/interfaces/IMessageRecipient.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";
import {IHelperTestnet} from "../interfaces/IHelperTestnet.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract CaerBridgeTokenReceiver is IMessageRecipient, Ownable {
    using SafeERC20 for IERC20;

    error MailboxNotSet();
    error NotMailbox();

    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

    address public token;
    address public helperTestnet;

    constructor(address _helperTestnet, address _token) Ownable(msg.sender) {
        helperTestnet = _helperTestnet;
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (helper.mailbox == address(0)) revert MailboxNotSet();
        token = _token;
    }

    modifier onlyMailbox() {
        _onlyMailbox();
        _;
    }

    function _onlyMailbox() internal view {
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        if (msg.sender != helper.mailbox) revert NotMailbox();
    }

    // Called by Hyperlane when message arrives
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external override onlyMailbox {
        IHelperTestnet.ChainInfo memory helper = IHelperTestnet(helperTestnet).chains(block.chainid);
        (uint256 amount,, address recipient,, address lendingPoolDestination) =
            abi.decode(_messageBody, (uint256, uint256, address, address, address));
        if (amount < IERC20(token).balanceOf(lendingPoolDestination)) {
            // TODO: hit via lendingPool && add user borrowshare
            IERC20(token).safeTransferFrom(lendingPoolDestination, recipient, amount);
        } else {
            IMailbox(helper.mailbox).dispatch{value: 0}(_origin, _sender, _messageBody);
        }
        emit ReceivedMessage(_origin, _sender, _messageBody);
    }

    function setHelperTestnet(address _helperTestnet) external onlyOwner {
        helperTestnet = _helperTestnet;
    }
}
