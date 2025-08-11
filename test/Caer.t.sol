// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LendingPoolDeployer} from "../src/LendingPools/LendingPoolDeployer.sol";
import {LendingPoolFactory} from "../src/LendingPools/LendingPoolFactory.sol";
import {LendingPool} from "../src/LendingPools/LendingPool.sol";
import {Position} from "../src/Position.sol";
import {MockUSDC} from "../src/Mocks/MockUSDC.sol";
import {MockUSDT} from "../src/Mocks/MockUSDT.sol";
import {MockWBTC} from "../src/Mocks/MockWBTC.sol";
import {MockWETH} from "../src/Mocks/MockWETH.sol";
import {MockWAVAX} from "../src/Mocks/MockWAVAX.sol";
import {HelperTestnet} from "../src/HelperTestnet.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {Protocol} from "../src/Protocol.sol";
import {LendingPoolRouterDeployer} from "../src/LendingPools/LendingPoolRouterDeployer.sol";
import {BridgeRouter} from "../src/Bridges/BridgeRouter.sol";
import {CreateLendingPoolBridgeRouter} from "../src/Crosschains/CreateLendingPoolBridgeRouter.sol";
import {IFactory} from "../src/Interfaces/IFactory.sol";
import {CreateLendingPoolOrigin} from "../src/Crosschains/CreateLendingPoolOrigin.sol";
import {CreateLendingPoolDestination} from "../src/Crosschains/CreateLendingPoolDestination.sol";
import {ConfigureLendingPool} from "../src/Crosschains/ConfigureLendingPool.sol";
import {ICreateLendingPoolBridgeRouter} from "../src/Interfaces/ICreateLendingPoolBridgeRouter.sol";
// import {IHelperTestnet} from "../src/Interfaces/IHelperTestnet.sol";
// import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";
import {ITokenSwap} from "../src/Interfaces/ITokenSwap.sol";
import {ILendingPool} from "../src/Interfaces/ILendingPool.sol";
import {ILPRouter} from "../src/Interfaces/ILPRouter.sol";

contract CaerTest is Test {
    IsHealthy public isHealthy;
    LendingPoolDeployer public lendingPoolDeployer;
    LendingPoolRouterDeployer public lendingPoolRouterDeployer;
    LendingPoolFactory public lendingPoolFactory;
    LendingPool public lendingPool;
    Position public position;
    MockUSDC public usdc;
    MockWBTC public wbtc;
    MockWETH public weth;
    MockUSDT public usdt;
    MockWAVAX public wavax;
    Protocol public protocol;
    HelperTestnet public helperTestnet;
    BridgeRouter public bridgeRouter;
    CreateLendingPoolBridgeRouter public createLendingPoolBridgeRouter;
    CreateLendingPoolOrigin public createLendingPoolOrigin;
    CreateLendingPoolDestination public createLendingPoolDestination;
    ConfigureLendingPool public configureLendingPool;

    address public owner = makeAddr("owner");

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    address public BaseBtcUsd = 0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298;
    address public BaseEthUsd = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;
    address public BaseUsdcUsd = 0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165;
    address public BaseUsdtUsd = 0x3ec8593F930EA45ea58c968260e6e9FF53FC934f;

    uint256 public chainId = 84532;

    bool priceFeedIsActive = false;

    // RUN
    // forge test --match-contract LendingPoolFactoryHyperlaneTest

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_sepolia"), 29499654);
        // vm.createSelectFork(vm.rpcUrl("base_sepolia"));

        // vm.createSelectFork("https://api.avax-test.network/ext/bc/C/rpc");
        // vm.createSelectFork(vm.rpcUrl("arb_sepolia"));

        vm.startPrank(alice);

        isHealthy = new IsHealthy();
        lendingPoolDeployer = new LendingPoolDeployer();
        lendingPoolRouterDeployer = new LendingPoolRouterDeployer();
        protocol = new Protocol();
        helperTestnet = new HelperTestnet();
        bridgeRouter = new BridgeRouter();
        createLendingPoolBridgeRouter = new CreateLendingPoolBridgeRouter();

        usdc = new MockUSDC();
        usdt = new MockUSDT();
        wbtc = new MockWBTC();
        weth = new MockWETH();
        wavax = new MockWAVAX();

        lendingPoolFactory = new LendingPoolFactory(
            address(isHealthy),
            address(lendingPoolDeployer),
            address(lendingPoolRouterDeployer),
            address(protocol),
            address(helperTestnet),
            address(bridgeRouter),
            address(createLendingPoolBridgeRouter)
        );

        lendingPoolDeployer.setFactory(address(lendingPoolFactory));
        lendingPoolRouterDeployer.setFactory(address(lendingPoolFactory));

        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 84532;
        lendingPool = new LendingPool(address(weth), address(usdc), address(lendingPoolFactory), 7e17, chainIds);

        position = new Position(address(weth), address(usdc), address(lendingPool), address(lendingPoolFactory));

        createLendingPoolOrigin = new CreateLendingPoolOrigin(address(lendingPoolFactory));
        createLendingPoolDestination = new CreateLendingPoolDestination(address(lendingPoolFactory));
        configureLendingPool = new ConfigureLendingPool(address(lendingPoolFactory));

        IFactory(address(lendingPoolFactory)).addTokenDataStream(address(wbtc), BaseBtcUsd);
        IFactory(address(lendingPoolFactory)).addTokenDataStream(address(weth), BaseEthUsd);
        IFactory(address(lendingPoolFactory)).addTokenDataStream(address(usdc), BaseUsdcUsd);
        IFactory(address(lendingPoolFactory)).addTokenDataStream(address(usdt), BaseUsdtUsd);

        ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).setOriginBridge(
            block.chainid, address(createLendingPoolOrigin)
        );
        ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).setReceiverBridge(
            block.chainid, address(createLendingPoolDestination)
        );
        ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).setConfiguredBridge(
            block.chainid, address(configureLendingPool)
        );

        // ** OTHER CHAIN **
        ICreateLendingPoolBridgeRouter(address(createLendingPoolBridgeRouter)).setReceiverBridge(
            421614, address(0x569597F8a90472d162bE12497EfED538Bd8CC78D)
        );

        ITokenSwap(address(usdc)).mint(alice, 100_000e6);
        ITokenSwap(address(weth)).mint(alice, 100e18);

        vm.stopPrank();
    }

    function helper_supply_liquidity(address _user, uint256 _amount) public {
        vm.startPrank(_user);
        IERC20(address(usdc)).approve(address(lendingPool), _amount);
        ILendingPool(address(lendingPool)).supplyLiquidity(_amount);
        vm.stopPrank();
    }

    // RUN
    // forge test --match-test test_create_lending_pool -vvv
    function test_create_lending_pool() public {
        vm.startPrank(alice);
        console.log("pool count before", IFactory(address(lendingPoolFactory)).poolCount());
        assertEq(IFactory(address(lendingPoolFactory)).poolCount(), 0);

        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 84532;
        // TODO: add gas amount
        IFactory(address(lendingPoolFactory)).createLendingPool{value: 0}(address(weth), address(usdc), 7e17, chainIds);

        assertEq(IFactory(address(lendingPoolFactory)).poolCount(), 1);
        console.log("pool count after", IFactory(address(lendingPoolFactory)).poolCount());
        vm.stopPrank();
    }

    // RUN
    // forge test --match-test test_crosschain_create_lending_pool -vvv
    // function test_crosschain_create_lending_pool() public {
    //     vm.startPrank(alice);
    //     console.log("pool count before", IFactory(address(lendingPoolFactory)).poolCount());
    //     uint256[] memory chainIds = new uint256[](1);
    //     chainIds[0] = 421614;
    //     // TODO: add gas amount
    //     IFactory(address(lendingPoolFactory)).createLendingPool{value: 0}(address(weth), address(usdc), 7e17, chainIds);
    //     console.log("pool count after", IFactory(address(lendingPoolFactory)).poolCount());
    //     vm.stopPrank();
    // }

    // RUN
    // forge test --match-test test_supply_liquidity -vvv
    function test_supply_liquidity() public {
        vm.startPrank(alice);

        IERC20(address(usdc)).approve(address(lendingPool), 10_000e6);
        ILendingPool(address(lendingPool)).supplyLiquidity(10_000e6);
        address router = ILendingPool(address(lendingPool)).router();
        console.log("supplyLiquidity", IERC20(address(usdc)).balanceOf(address(lendingPool)));
        console.log("userSupplyShares", ILPRouter(router).userSupplyShares(alice));
        console.log("totalSupplyShares", ILPRouter(router).totalSupplyShares());
        console.log("totalSupplyAssets", ILPRouter(router).totalSupplyAssets());
        assertEq(ILPRouter(router).userSupplyShares(alice), 10_000e6);
        assertEq(ILPRouter(router).totalSupplyAssets(), 10_000e6);
        assertEq(ILPRouter(router).totalSupplyShares(), 10_000e6);
        assertEq(IERC20(address(usdc)).balanceOf(address(lendingPool)), 10_000e6);

        vm.stopPrank();
    }

    // RUN
    // forge test --match-test test_withdraw_liquidity -vvv
    // TODO: crosschain
    function test_withdraw_liquidity() public {
        uint256 amount = 10_000e6;
        helper_supply_liquidity(alice, amount);
        uint256 aliceBalance = IERC20(address(usdc)).balanceOf(alice);
        vm.startPrank(alice);
        ILendingPool(address(lendingPool)).withdrawLiquidity(amount, alice, 84532, false);
        console.log("withdrawLiquidity: lendingPool balance", IERC20(address(usdc)).balanceOf(address(lendingPool)));
        console.log("withdrawLiquidity: user balance", IERC20(address(usdc)).balanceOf(alice));
        assertEq(IERC20(address(usdc)).balanceOf(address(lendingPool)), 0);
        assertEq(IERC20(address(usdc)).balanceOf(alice), aliceBalance + amount);
        vm.stopPrank();
    }
}
