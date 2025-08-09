// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {HelperTestnet} from "../../src/HelperTestnet.sol";
import {LendingPoolFactory} from "../../src/LendingPools/LendingPoolFactory.sol";
import {CreateLendingPoolBridgeRouter} from "../../src/Crosschains/CreateLendingPoolBridgeRouter.sol";
import {CreateLendingPoolOrigin} from "../../src/Crosschains/CreateLendingPoolOrigin.sol";
import {CreateLendingPoolDestination} from "../../src/Crosschains/CreateLendingPoolDestination.sol";
import {ICreateLendingPoolBridgeRouter} from "../../src/interfaces/ICreateLendingPoolBridgeRouter.sol";
import {IsHealthy} from "../../src/IsHealthy.sol";
import {LendingPoolRouterDeployer} from "../../src/LendingPools/LendingPoolRouterDeployer.sol";
import {LendingPoolDeployer} from "../../src/LendingPools/LendingPoolDeployer.sol";
import {Protocol} from "../../src/Protocol.sol";
import {BridgeRouter} from "../../src/Bridges/BridgeRouter.sol";
import {ConfigureLendingPool} from "../../src/Crosschains/ConfigureLendingPool.sol";
import {ILPDeployer} from "../../src/interfaces/ILPDeployer.sol";

contract LendingPoolFactoryScript is Script {
    IsHealthy public isHealthy;
    HelperTestnet public helperTestnet;
    LendingPoolFactory public lendingPoolFactory;
    CreateLendingPoolBridgeRouter public createLendingPoolBridgeRouter;
    CreateLendingPoolOrigin public createLendingPoolOrigin;
    LendingPoolRouterDeployer public lendingPoolRouterDeployer;
    LendingPoolDeployer public lendingPoolDeployer;
    Protocol public protocol;
    BridgeRouter public bridgeRouter;
    ConfigureLendingPool public configureLendingPool;
    CreateLendingPoolDestination public createLendingPoolDestination;

    function setUp() public {
        // host chain (etherlink)
        // vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
        // receiver chain
        // vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        isHealthy = new IsHealthy();
        lendingPoolRouterDeployer = new LendingPoolRouterDeployer();
        lendingPoolDeployer = new LendingPoolDeployer();
        protocol = new Protocol();
        helperTestnet = new HelperTestnet();
        bridgeRouter = new BridgeRouter();
        createLendingPoolBridgeRouter = new CreateLendingPoolBridgeRouter();
        lendingPoolFactory = new LendingPoolFactory(
            address(isHealthy),
            address(lendingPoolDeployer),
            address(lendingPoolRouterDeployer),
            address(protocol),
            address(helperTestnet),
            address(bridgeRouter),
            address(createLendingPoolBridgeRouter)
        );
        ILPDeployer(address(lendingPoolDeployer)).setFactory(address(lendingPoolFactory));
        createLendingPoolOrigin = new CreateLendingPoolOrigin(address(lendingPoolFactory));
        createLendingPoolDestination = new CreateLendingPoolDestination(address(lendingPoolFactory));
        configureLendingPool = new ConfigureLendingPool(address(lendingPoolFactory));

        ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).setSenderBridge(
            block.chainid, address(createLendingPoolOrigin)
        );

        ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).setReceiverBridge(
            block.chainid, address(createLendingPoolDestination)
        );

        ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).setConfiguredBridge(
            block.chainid, address(configureLendingPool)
        );
        console.log("ishealthy", address(isHealthy));
        console.log("lendingPoolDeployer", address(lendingPoolDeployer));
        console.log("lendingPoolRouterDeployer", address(lendingPoolRouterDeployer));
        console.log("protocol", address(protocol));
        console.log("helperTestnet", address(helperTestnet));
        console.log("bridgeRouter", address(bridgeRouter));
        console.log("createLendingPoolBridgeRouter", address(createLendingPoolBridgeRouter));
        console.log("lendingPoolFactory", address(lendingPoolFactory));
        console.log("createLendingPoolDestination", address(createLendingPoolDestination));
        console.log(
            "read receiver bridge",
            ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).receiverBridges(block.chainid)
        );
        console.log("createLendingPoolOrigin", address(createLendingPoolOrigin));
        console.log(
            "read sender bridge",
            ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).senderBridges(block.chainid)
        );
        console.log("configureLendingPool", address(configureLendingPool));
        console.log(
            "read configure bridge",
            ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).configureBridges(block.chainid)
        );
        vm.stopBroadcast();
    }
    // forge script LendingPoolFactoryScript --broadcast -vvv --verify

    // BASE
    //   helperTestnet 0xEb106f667a95b3377fA9C66B3D9c92C665408a01
    //   createLendingPoolBridgeRouter 0x4CE760CcD533eeaFDBDf821f7dc390243bdef74d
    //   lendingPoolFactory 0x82EFAac5a7Efab5f1Db76cD932802067e8e8e1a7
    //   createLendingPoolOrigin 0x45115b5A7631491DD2Fa3e9109898aBf936956AE
    //   read sender bridge 0x45115b5A7631491DD2Fa3e9109898aBf936956AE

    // ARB
    //   helperTestnet 0xb4F8A55030a9e2b3B52d6267223915846eB2d3EC
    //   createLendingPoolBridgeRouter 0x2e373EcA4A1d1647694B3722656D16156cbB5750
    //   lendingPoolFactory 0x1F24E44Dd63c3fc1953b12De683ceBDC05F14717
    //   createLendingPoolOrigin 0x08F26e6C5919035fce98a2275c3CcEA09ac9029a
    //   read sender bridge 0x08F26e6C5919035fce98a2275c3CcEA09ac9029a

    // TODO:
    // - set configure bridge both origin / destination to lpbridgerouter
    // - deploy receiver bridge
    // - pair  to lpbridgerouter (ICreateLendingPoolBridgeRouter)
    // configure token
}
