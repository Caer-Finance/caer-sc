// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICreateLendingPoolBridgeRouter {
    function originBridges(uint256 _chainId) external view returns (address);
    function receiverBridges(uint256 _chainId) external view returns (address);
    function configureBridges(uint256 _chainId) external view returns (address);
    function executeBridges(uint256 _chainId) external view returns (address);

    function setOriginBridge(uint256 _chainId, address _originBridge) external;
    function setReceiverBridge(uint256 _chainId, address _receiverBridge) external;
    function setConfiguredBridge(uint256 _chainId, address _configuredBridge) external;
    function setExecuteBridge(uint256 _chainId, address _executeBridge) external;
}