// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBridgeRouter {
    // ** READ
    function bridgeTokenSenders(address _token, uint256 _chainId) external view returns (address);
    function getBridgeTokenSendersChainId(address _token, uint256 _chainId) external view returns (address);
    function getBridgeTokenSendersLength(address _token) external view returns (uint256);
    function getBridgeTokenSendersChainIdLength(address _token, uint256 _chainId) external view returns (uint256);

    // ** WRITE
    function setBridgeTokenSender(address _token, uint256 _chainId, address _bridgeTokenSender) external;
}