// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract BridgeRouter is Ownable {
    // chainId => address
    mapping(uint256 => address) public originBridges;
    mapping(uint256 => address) public receiverBridges;
    mapping(uint256 => address) public configureBridges;
    mapping(uint256 => address) public executeBridges;

    constructor() Ownable(msg.sender) {}

    function setOriginBridge(uint256 _chainId, address _originBridge) public onlyOwner {
        originBridges[_chainId] = _originBridge;
    }

    function setReceiverBridge(uint256 _chainId, address _receiverBridge) public onlyOwner {
        receiverBridges[_chainId] = _receiverBridge;
    }

    function setConfiguredBridge(uint256 _chainId, address _configuredBridge) public onlyOwner {
        configureBridges[_chainId] = _configuredBridge;
    }

    function setExecuteBridge(uint256 _chainId, address _executeBridge) public onlyOwner {
        executeBridges[_chainId] = _executeBridge;
    }
}
