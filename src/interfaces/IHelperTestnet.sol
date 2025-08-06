// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IHelperTestnet {
    struct ChainInfo {
        address mailbox;
        address gasMaster;
        uint32 domainId;
    }

    // ** READ
    function chains(uint256 _chainId) external view returns (ChainInfo memory);
    function receiverBridge(uint256 _chainId) external view returns (address);
    function owner() external view returns (address);
    function chainId() external view returns (uint256);

    // ** WRITE
    function addChain(address _mailbox, address _gasMaster, uint32 _domainId, uint256 _chainId) external;
    function addReceiverBridge(uint256 _chainId, address _receiverBridge) external;
    function updateChain(uint256 _chainId, address _mailbox, address _gasMaster, uint32 _domainId) external;
}
