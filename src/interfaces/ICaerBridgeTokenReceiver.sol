// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICaerBridgeTokenReceiver {
    // ** READ
    function mailbox() external view returns (address);
    function token() external view returns (address);
    function helperTestnet() external view returns (address);

    // ** WRITE
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _messageBody) external;
    function setHelperTestnet(address _helperTestnet) external;
}
