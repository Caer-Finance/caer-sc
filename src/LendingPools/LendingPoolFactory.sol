// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ILPDeployer} from "../interfaces/ILPDeployer.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {ICreateLendingPoolBridgeRouter} from "../interfaces/ICreateLendingPoolBridgeRouter.sol";
import {ICreateLendingPoolOrigin} from "../interfaces/ICreateLendingPoolOrigin.sol";

/**
 * @title LendingPoolFactory
 * @author Caer Protocol
 * @notice Factory contract for creating and managing lending pools
 * @dev This contract serves as the main entry point for creating new lending pools.
 * It maintains a registry of all created pools and manages token data streams
 * and cross-chain token senders.
 */
contract LendingPoolFactory is Ownable {
    error OnlyOwner();

    /**
     * @notice Emitted when a new lending pool is created
     * @param collateralToken The address of the collateral token
     * @param borrowToken The address of the borrow token
     * @param lendingPool The address of the created lending pool
     * @param ltv The Loan-to-Value ratio for the pool
     */
    event LendingPoolCreated(
        address indexed collateralToken, address indexed borrowToken, address indexed lendingPool, uint256 ltv
    );

    /**
     * @notice Emitted when a token data stream is added
     * @param token The address of the token
     * @param dataStream The address of the data stream contract
     */
    event TokenDataStreamAdded(address indexed token, address indexed dataStream);

    /**
     * @notice Emitted when a basic token sender is added for a specific chain
     * @param chainId The chain ID where the token sender operates
     * @param basicTokenSender The address of the basic token sender contract
     */
    event BasicTokenSenderAdded(uint256 indexed chainId, address indexed basicTokenSender);

    /**
     * @notice Emitted when a pool is set for other chains
     * @param originPool The address of the origin pool
     * @param chainId The chain ID where the pool is set
     * @param lendingPoolAddress The address of the lending pool
     */
    event PoolOtherChainsSet(address indexed originPool, uint256 indexed chainId, address indexed lendingPoolAddress);

    /**
     * @notice Structure representing a lending pool
     * @param collateralToken The address of the collateral token
     * @param borrowToken The address of the borrow token
     * @param lendingPoolAddress The address of the lending pool contract
     */
    // solhint-disable-next-line gas-struct-packing
    struct Pool {
        address collateralToken;
        address borrowToken;
        address lendingPoolAddress;
    }

    struct CrosschainPool {
        uint256 chainId;
        address lendingPoolAddress;
    }

    /// @notice The address of the IsHealthy contract for health checks
    address public isHealthy;

    /// @notice The address of the lending pool deployer contract
    address public lendingPoolDeployer;

    /// @notice The address of the lending pool router deployer contract
    address public lendingPoolRouterDeployer;

    /// @notice The address of the protocol contract
    address public protocol;

    /// @notice The address of the bridge router contract
    address public helper;

    /// @notice The address of the bridge router contract
    address public tokenBridgeRouter;

    /// @notice The address of the lp bridge router contract
    address public lpBridgeRouter;

    /// @notice Array of all created pools
    Pool[] public pools;

    /// @notice Mapping from token address to its data stream address
    mapping(address => address) public tokenDataStream;

    mapping(address => CrosschainPool[]) public poolOtherChains;

    /// @notice Total number of pools created
    uint256 public poolCount;

    /**
     * @notice Constructor for the LendingPoolFactory
     * @param _isHealthy The address of the IsHealthy contract
     * @param _lendingPoolDeployer The address of the lending pool deployer contract
     */
    constructor(
        address _isHealthy,
        address _lendingPoolDeployer,
        address _lendingPoolRouterDeployer,
        address _protocol,
        address _helper,
        address _tokenBridgeRouter,
        address _lpBridgeRouter
    ) Ownable(msg.sender) {
        isHealthy = _isHealthy;
        lendingPoolDeployer = _lendingPoolDeployer;
        lendingPoolRouterDeployer = _lendingPoolRouterDeployer;
        protocol = _protocol;
        helper = _helper;
        tokenBridgeRouter = _tokenBridgeRouter;
        lpBridgeRouter = _lpBridgeRouter;
    }

    /**
     * @notice Modifier to restrict function access to the owner only
     */

    /**
     * @notice Creates a new lending pool with the specified parameters
     * @param collateralToken The address of the collateral token
     * @param borrowToken The address of the borrow token
     * @param ltv The Loan-to-Value ratio for the pool (in basis points)
     * @return The address of the newly created lending pool
     * @dev This function deploys a new lending pool using the lending pool deployer
     * and adds it to the pools registry
     */
    function createLendingPool(address collateralToken, address borrowToken, uint256 ltv, uint256[] memory _chainIds)
        public
        payable
        returns (address)
    {
        address lendingPool = ILPDeployer(lendingPoolDeployer).deployLendingPool(collateralToken, borrowToken, ltv);

        pools.push(Pool(collateralToken, borrowToken, address(lendingPool)));
        poolCount++;

        setPoolOtherChains(address(lendingPool), block.chainid, address(lendingPool));

        address senderBridge = ICreateLendingPoolBridgeRouter(tokenBridgeRouter).senderBridges(block.chainid);

        ICreateLendingPoolOrigin(senderBridge).createLendingPool{value: msg.value}(
            address(lendingPool), collateralToken, borrowToken, ltv, _chainIds
        );

        emit LendingPoolCreated(collateralToken, borrowToken, address(lendingPool), ltv);
        return address(lendingPool);
    }

    function getPoolLength() public view returns (uint256) {
        return pools.length;
    }

    // ****************** OWNER AREA ******************
    /**
     * @notice Adds a token data stream for price feeds and other data
     * @param _token The address of the token
     * @param _dataStream The address of the data stream contract
     * @dev Only callable by the owner
     */
    function addTokenDataStream(address _token, address _dataStream) public onlyOwner {
        tokenDataStream[_token] = _dataStream;
        emit TokenDataStreamAdded(_token, _dataStream);
    }

    function updateLendingPoolRouterDeployer(address _lendingPoolRouterDeployer) public onlyOwner {
        lendingPoolRouterDeployer = _lendingPoolRouterDeployer;
    }

    function updateLendingPoolDeployer(address _lendingPoolDeployer) public onlyOwner {
        lendingPoolDeployer = _lendingPoolDeployer;
    }

    function updateIsHealthy(address _isHealthy) public onlyOwner {
        isHealthy = _isHealthy;
    }

    function updateProtocol(address _protocol) public onlyOwner {
        protocol = _protocol;
    }

    function updateHelper(address _helper) public onlyOwner {
        helper = _helper;
    }

    function updateTokenBridgeRouter(address _tokenBridgeRouter) public onlyOwner {
        tokenBridgeRouter = _tokenBridgeRouter;
    }

    function updateLpBridgeRouter(address _lpBridgeRouter) public onlyOwner {
        lpBridgeRouter = _lpBridgeRouter;
    }
    // ************************************************

    function setPoolOtherChains(address _originPool, uint256 _chainId, address _lendingPoolAddress) public {
        if (poolOtherChains[_originPool].length == 0) {
            poolOtherChains[_originPool].push(CrosschainPool(_chainId, _lendingPoolAddress));
        } else {
            for (uint256 i = 0; i < poolOtherChains[_originPool].length; i++) {
                if (poolOtherChains[_originPool][i].chainId != _chainId) {
                    poolOtherChains[_originPool].push(CrosschainPool(_chainId, _lendingPoolAddress));
                    break;
                }
            }
        }
        emit PoolOtherChainsSet(_originPool, _chainId, _lendingPoolAddress);
    }

    function getPoolOtherChainsLength(address _originPool) public view returns (uint256) {
        return poolOtherChains[_originPool].length;
    }
}
