// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LendingPoolRouter} from "./LendingPoolRouter.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract LendingPoolRouterDeployer is Ownable {
    error OnlyFactoryCanCall();
    error InvalidFactoryAddress();
    // Factory address

    address public factory;

    constructor() Ownable(msg.sender) {}

    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    function _onlyFactory() internal view {
        if (msg.sender != factory) revert OnlyFactoryCanCall();
    }

    /**
     * @notice Deploys a new LendingPool contract with specified parameters
     * @param _collateralToken The address of the collateral token (e.g., WETH, WBTC)
     * @param _borrowToken The address of the borrow token (e.g., USDC, USDT)
     * @param _ltv The loan-to-value ratio as a percentage (e.g., 8e17 for 80%)
     * @return The address of the newly deployed LendingPool contract
     *
     * @dev This function creates a new LendingPool instance with the provided parameters.
     * The ltv parameter should be provided as a basis point value (e.g., 8e17 = 80%).
     * Only the factory contract should call this function to ensure proper pool management.
     *
     * Requirements:
     * - _collateralToken must be a valid ERC20 token address
     * - _borrowToken must be a valid ERC20 token address
     * - _ltv must be greater than 0 and less than or equal to 1e18 (100%)
     *
     * @custom:security This function should only be called by the factory contract
     */
    function deployLendingPoolRouter(
        address _lendingPool,
        address _factory,
        address _collateralToken,
        address _borrowToken,
        uint256 _ltv
    ) public onlyFactory returns (address) {
        LendingPoolRouter lendingPoolRouter =
            new LendingPoolRouter(_lendingPool, _factory, _collateralToken, _borrowToken, _ltv);
        return address(lendingPoolRouter);
    }

    function setFactory(address _factory) public onlyOwner {
        if (_factory == address(0)) revert InvalidFactoryAddress();
        factory = _factory;
    }
}
