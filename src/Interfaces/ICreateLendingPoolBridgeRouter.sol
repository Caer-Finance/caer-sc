// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICreateLendingPoolBridgeRouter {
    function senderBridges(uint256 _chainId) external view returns (address);
    function receiverBridges(uint256 _chainId) external view returns (address);
    function configureBridges(uint256 _chainId) external view returns (address);

    function setSenderBridge(uint256 _chainId, address _senderBridge) external;
    function setReceiverBridge(uint256 _chainId, address _receiverBridge) external;
    function setConfiguredBridge(uint256 _chainId, address _configuredBridge) external;
}