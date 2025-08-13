// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract BridgeRouter is Ownable {
    struct BridgeInfo {
        uint256 chainId;
        address bridgeAddress;
    }

    mapping(address => BridgeInfo[]) public bridgeTokenSenders;
    mapping(address => BridgeInfo[]) public bridgeTokenReceivers;

    constructor() Ownable(msg.sender) {}

    function setBridgeTokenSender(address _token, uint256 _chainId, address _bridgeTokenSender) public onlyOwner {
        if (getBridgeTokenSendersChainIdLength(_token, _chainId) > 0) {
            bridgeTokenSenders[_token][getBridgeTokenSendersChainIdLength(_token, _chainId) - 1].bridgeAddress =
                _bridgeTokenSender;
        }
        bridgeTokenSenders[_token].push(BridgeInfo({chainId: _chainId, bridgeAddress: _bridgeTokenSender}));
    }

    function getBridgeTokenSendersChainId(address _token, uint256 _chainId) public view returns (address) {
        uint256 length = getBridgeTokenSendersLength(_token);
        for (uint256 i = 0; i < length; i++) {
            if (bridgeTokenSenders[_token][i].chainId == _chainId) {
                return bridgeTokenSenders[_token][i].bridgeAddress;
            }
        }
        return address(0);
    }

    function getBridgeTokenSendersLength(address _token) public view returns (uint256) {
        return bridgeTokenSenders[_token].length;
    }

    function getBridgeTokenSendersChainIdLength(address _token, uint256 _chainId) public view returns (uint256) {
        uint256 length = getBridgeTokenSendersLength(_token);

        uint256 count = 0;
        for (uint256 i = 0; i < length; i++) {
            if (bridgeTokenSenders[_token][i].chainId == _chainId) {
                count++;
            }
        }
        return count;
    }

    function setBridgeTokenReceiver(address _token, uint256 _chainId, address _bridgeTokenReceiver) public onlyOwner {
        if (getBridgeTokenReceiversChainIdLength(_token, _chainId) > 0) {
            bridgeTokenReceivers[_token][getBridgeTokenReceiversChainIdLength(_token, _chainId) - 1].bridgeAddress =
                _bridgeTokenReceiver;
        }
        bridgeTokenReceivers[_token].push(BridgeInfo({chainId: _chainId, bridgeAddress: _bridgeTokenReceiver}));
    }

    function getBridgeTokenReceiversChainId(address _token, uint256 _chainId) public view returns (address) {
        uint256 length = getBridgeTokenReceiversLength(_token);
        for (uint256 i = 0; i < length; i++) {
            if (bridgeTokenReceivers[_token][i].chainId == _chainId) {
                return bridgeTokenReceivers[_token][i].bridgeAddress;
            }
        }
        return address(0);
    }

    function getBridgeTokenReceiversLength(address _token) public view returns (uint256) {
        return bridgeTokenReceivers[_token].length;
    }

    function getBridgeTokenReceiversChainIdLength(address _token, uint256 _chainId) public view returns (uint256) {
        uint256 length = getBridgeTokenReceiversLength(_token);
        uint256 count = 0;
        for (uint256 i = 0; i < length; i++) {
            if (bridgeTokenReceivers[_token][i].chainId == _chainId) {
                count++;
            }
        }
        return count;
    }
}
