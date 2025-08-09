// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFactory {
    struct Pool {
        address collateralToken;
        address borrowToken;
        address lendingPoolAddress;
    }
    struct CrosschainPool {
        uint256 chainId;
        address lendingPoolAddress;
    }
    // ** READ
    function owner() external view returns (address);
    function isHealthy() external view returns (address);
    function lendingPoolDeployer() external view returns (address);
    function lendingPoolRouterDeployer() external view returns (address);
    function protocol() external view returns (address);
    function helper() external view returns (address);
    function bridgeRouter() external view returns (address);
    function tokenDataStream(address _token) external view returns (address);
    function pools(uint256 _index) external view returns (Pool memory);
    function poolCount() external view returns (uint256);
    function poolOtherChains(address _originLendingPool) external view returns (CrosschainPool[] memory);
    function getPoolLength() external view returns (uint256);
    function getPoolOtherChainsLength(address _originLendingPool) external view returns (uint256);

    // ** WRITE
    function createLendingPool(address _collateralToken, address _borrowToken, uint256 _ltv, uint256[] memory _chainIds)
        external payable
        returns (address);
    function addTokenDataStream(address _token, address _dataStream) external;
    function updateLendingPoolRouterDeployer(address _lendingPoolRouterDeployer) external;
    function updateLendingPoolDeployer(address _lendingPoolDeployer) external;
    function updateIsHealthy(address _isHealthy) external;
    function updateProtocol(address _protocol) external;
    function updateHelper(address _helper) external;
    function updateBridgeRouter(address _bridgeRouter) external;
    function setPoolOtherChains(address _originLendingPool, uint256 _origin, address _destinationLendingPool)
        external;
}
