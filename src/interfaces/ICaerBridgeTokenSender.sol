// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICaerBridgeTokenSender {
    // ** READ
    function factory() external view returns (address);
    function token() external view returns (address);
    function receiverBridge() external view returns (address);
    function chainId() external view returns (uint256);

    // ** WRITE
    function bridge(uint256 _amount, address _recipient, uint256 _shares, address _lendingPoolOrigin, address _lendingPoolDestination)
        external
        payable
        returns (bytes32);
    function setFactory(address _factory) external;
}
