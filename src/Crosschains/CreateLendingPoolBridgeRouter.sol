// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract CreateLendingPoolBridgeRouter is Ownable {
    // chainId => address
    mapping(uint256 => address) public senderBridges;
    mapping(uint256 => address) public receiverBridges;
    mapping(uint256 => address) public configureBridges;

    constructor() Ownable(msg.sender) {}

    function setSenderBridge(uint256 _chainId, address _senderBridge) public onlyOwner {
        senderBridges[_chainId] = _senderBridge;
    }

    function setReceiverBridge(uint256 _chainId, address _receiverBridge) public onlyOwner {
        receiverBridges[_chainId] = _receiverBridge;
    }

    function setConfiguredBridge(uint256 _chainId, address _configuredBridge) public onlyOwner {
        configureBridges[_chainId] = _configuredBridge;
    }
}
