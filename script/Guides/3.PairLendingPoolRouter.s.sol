// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ICreateLendingPoolBridgeRouter} from "../../src/interfaces/ICreateLendingPoolBridgeRouter.sol";
import {ILPDeployer} from "../../src/interfaces/ILPDeployer.sol";

contract PairLendingPoolRouterScript is Script {
    // ARB -> RPC (BASE) - Using ARB addresses since we're connecting to ARB
    uint256 chainId = 421614;
    address public ishealthy = 0x4197B744c329807B1D84Ee954b3e39D069Ead026;
    address public lendingPoolDeployer = 0x6d4a75Ec6E8C1Cb1c18d37C0094cAFE26c1E3c13;
    address public lendingPoolRouterDeployer = 0xff4F8e7FfF0266d12FE739c259C93c9e875Ed1E9;
    address public protocol = 0x5f57FAc2019492c2C576C97fdf15B075517628b3;
    address public helperTestnet = 0x8785962Fe6bd232d9940F1fb93E8EBEEf8E40d66;
    address public bridgeRouter = 0xf9AB27080bEa600C82F8f69E2D3f2f928A5B8580;

    address public createLendingPoolBridgeRouter = 0xf5407Af2548070FDC0ABD0487f8C19F2848741D6;

    address public lendingPoolFactory = 0x5db7C42dEaa6cd61238118783096522f9B148Bb1;
    address public createLendingPoolDestination = 0x569597F8a90472d162bE12497EfED538Bd8CC78D;

    address public createLendingPoolOrigin = 0xe1d17c0d1AAd41D82E9c2c7A12E55EF8ac76eBF2;

    address public configureLendingPool = 0xF0beF44f695e21708599F2d42f6336B693F6C05f;

    // BASE -> RPC (ARB) - Base addresses for reference
    // uint256 chainId = 84532;
    //  address public ishealthy = 0x6aB3c2dBfc43d84795803f29Ce41C095721C4DB0;
    //  address public lendingPoolDeployer = 0x4001908b9C6d7162Ce3284C43067c685Fd3D1f47;
    //  address public lendingPoolRouterDeployer = 0x1FD805E53f81f0FB03b9843FE3D0120B9F47f7C9;
    //  address public protocol = 0x8Fc10d02EF381aA658D7c5Fb6A5298Fd6596fe5b;
    //  address public helperTestnet = 0xEa69E445d88458D28752f1E3dac2f9257F5FAfA6;
    //  address public bridgeRouter = 0x8E82dA69D9f0bEA75a4c5E9Be1e9E2BA82E0728B;
    //  address public lendingPoolFactory = 0xbE19a593Fb843499995AdD4869e1C9a7507dAAa0;
    //  address public createLendingPoolDestination = 0xC1A1DF5bB6084808106288C5819697CD2DD87C08;

    //  address public createLendingPoolBridgeRouter = 0x456AE45cDc62Aa8aF055c228b6693dE91603D478;

    //  address public createLendingPoolOrigin = 0x62315594b532D9331867E58ED6C375dF924b1E1e;
    //  address public configureLendingPool = 0xF623810935d65665b0Bd72d44ACe9D3025292100;

    function setUp() public {
        // host chain (etherlink)
        // vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
        // receiver chain
        // vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // Validate that addresses are not zero
        require(createLendingPoolBridgeRouter != address(0), "Invalid bridge router address");
        require(configureLendingPool != address(0), "Invalid configure pool address");

        console.log("Setting up cross-chain bridge configuration...");
        console.log("Target chain ID:", chainId);
        console.log("Bridge router:", createLendingPoolBridgeRouter);
        console.log("Configure pool address:", configureLendingPool);

        vm.startBroadcast(privateKey);

        // Set the configured bridge for the target chain
        ICreateLendingPoolBridgeRouter(createLendingPoolBridgeRouter).setConfiguredBridge(chainId, configureLendingPool);
        ICreateLendingPoolBridgeRouter(createLendingPoolBridgeRouter).setReceiverBridge(
            chainId, createLendingPoolDestination
        );
        ICreateLendingPoolBridgeRouter(createLendingPoolBridgeRouter).setSenderBridge(chainId, createLendingPoolOrigin);

        console.log("Successfully configured bridge for chain:", chainId);

        vm.stopBroadcast();
    }

    // RUN
    // forge script PairLendingPoolRouterScript -vvv --broadcast
}
