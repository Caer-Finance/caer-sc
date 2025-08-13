// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBridgeRouter {
    // ** READ
    // function bridgeTokenSenders(address _token, uint256 _chainId) external view returns (address);
    // function getBridgeTokenSendersChainId(address _token, uint256 _chainId) external view returns (address);
    // function getBridgeTokenSendersLength(address _token) external view returns (uint256);
    // function getBridgeTokenSendersChainIdLength(address _token, uint256 _chainId) external view returns (uint256);
    // function bridgeTokenReceivers(address _token, uint256 _chainId) external view returns (address);
    // function getBridgeTokenReceiversChainId(address _token, uint256 _chainId) external view returns (address);
    // function getBridgeTokenReceiversLength(address _token) external view returns (uint256);
    // function getBridgeTokenReceiversChainIdLength(address _token, uint256 _chainId) external view returns (uint256);
    function originBridges(uint256 _chainId) external view returns (address);
    function receiverBridges(uint256 _chainId) external view returns (address);
    function configureBridges(uint256 _chainId) external view returns (address);
    function executeBridges(uint256 _chainId) external view returns (address);

    // ** WRITE
    function setBridgeTokenSender(address _token, uint256 _chainId, address _bridgeTokenSender) external;
    function setBridgeTokenReceiver(address _token, uint256 _chainId, address _bridgeTokenReceiver) external;
}