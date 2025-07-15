// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDC} from "../../src/hyperlane/mocks/MockUSDC.sol";
import {MockUSDT} from "../../src/hyperlane/mocks/MockUSDT.sol";
import {MockWAVAX} from "../../src/hyperlane/mocks/MockWAVAX.sol";
import {HelperTestnet} from "../../src/hyperlane/HelperTestnet.sol";
import {CaerBridgeTokenSender} from "../../src/hyperlane/CaerBridgeTokenSender.sol";
import {CaerBridgeTokenReceiver} from "../../src/hyperlane/CaerBridgeTokenReceiver.sol";
import {MockWBTC} from "../../src/hyperlane/mocks/MockWBTC.sol";
import {MockWETH} from "../../src/hyperlane/mocks/MockWETH.sol";
import {ITokenSwap} from "../../src/hyperlane/interfaces/ITokenSwap.sol";
import {Protocol} from "../../src/hyperlane/Protocol.sol";
import {IsHealthy} from "../../src/hyperlane/IsHealthy.sol";
import {LendingPoolDeployer} from "../../src/hyperlane/LendingPoolDeployer.sol";
import {LendingPoolFactory} from "../../src/hyperlane/LendingPoolFactory.sol";
import {LendingPool} from "../../src/hyperlane/LendingPool.sol";
import {Position} from "../../src/hyperlane/Position.sol";

contract CaerScript is Script {
    HelperTestnet public helperTestnet;
    CaerBridgeTokenReceiver public caerBridgeTokenReceiver;
    CaerBridgeTokenSender public caerBridgeTokenSender;
    MockUSDC public mockUSDC;
    MockUSDT public mockUSDT;
    MockWAVAX public mockWAVAX;
    MockWBTC public mockWBTC;
    MockWETH public mockWETH;

    Protocol public protocol;
    IsHealthy public isHealthy;
    LendingPoolDeployer public lendingPoolDeployer;
    LendingPoolFactory public lendingPoolFactory;
    LendingPool public lendingPool;
    Position public position;

    uint32 public chainId = 84532;

    address public ARB_BtcUsd = 0x56a43EB56Da12C0dc1D972ACb089c06a5dEF8e69;
    address public ARB_EthUsd = 0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165;
    address public ARB_AvaxUsd = 0xe27498c9Cc8541033F265E63c8C29A97CfF9aC6D;
    address public ARB_UsdcUsd = 0x0153002d20B96532C639313c2d54c3dA09109309;
    address public ARB_UsdtUsd = 0x80EDee6f667eCc9f63a0a6f55578F870651f06A4;

    address public baseHelper = 0x9644888dDfa19626350f9Ab7D72025092aead844;
    address public UsdcBridgeTokenReceiver = 0xe9E12229A1f1ff7B36B5128aCEBcb1A9947A45AB;
    address public UsdtBridgeTokenReceiver = 0x6b8b6FDC5208c72CC011e8E76C5eD062abDdaF62;
    address public WavaxBridgeTokenReceiver = 0xFAE5d1499879Aee7EA96e3D8Cd15Bb7a39479D4a;
    address public BtcBridgeTokenReceiver = 0x1A15C13e64f4Dc2746644E303d230157640E340F;
    address public EthBridgeTokenReceiver = 0xC4ECE4a5cD5296a884835338d131429445de3bFC;
    //   export const BASE_mockWETH =  0x70F98aaCEd0f8176efcD5B082f39432793A48912 ;
    //   export const BASE_mockUSDC =  0xd1f1aF4A99760cB68e436bAb147c4F066E8f6283 ;
    //   export const BASE_mockUSDT =  0x5e63B7550eC070C46046BdA7Fd26AE795Ae2F368 ;
    //   export const BASE_mockWAVAX =  0x4740e13b74c7b278A36bb1b8889aB9198e6f4c49 ;
    //   export const BASE_mockWBTC =  0x77Ce0D597216065133803B651160A2B609829041 ;

    bool public isDeployed = false;
    address public arbHelper = isDeployed ? 0x15257Ec35D606849D2DBC3ee3D49707D8b61E87D : address(0);

    address public ARB_mockUSDC = 0x2BF6F2726A8fB77033cD5FCd30Bf56836B602a1F;
    address public ARB_mockUSDT = 0xb76612Bf1C76b56f191f28eB7FDd37988d79E6bc;
    address public ARB_mockWAVAX = 0x7f6F9cca3AE061576091dF5830605E413549402f;
    address public ARB_mockWBTC = 0xE430Cfb554d6D9B27E5BcC61FdBEDbDD37749C73;
    address public ARB_mockWETH = 0xC8a00955106fC3cF2D932B4feCF25fa8cdF96174;

    //   address public arbHelper =  0x7C1A494ED22eAFC04e314c79Fc81AD11386f63a1 ;
    //   export const mockUSDC =  0xCB1cE7974cb8566711775e1cb2D04FaF1293d082 ;
    //   export const mockUSDT =  0x4E64400D95663F1900459C3c46f3667C363Ed33b ;
    //   export const mockWAVAX =  0x33925aE397E2688D92c3fc837c5E015DfA73D996 ;
    //   export const mockWBTC =  0x6234F07ad85805D01446BB7D8e1f8E5e2018cEB1 ;
    //   export const mockWETH =  0xAeb1279d0BCa98819bb25D76e54d49c221AB5656 ;
    //   export const protocol =  0x07695F590c73824f6d8285DAedF8B0C4EfE748cF ;
    //   export const isHealthy =  0x4DB881b3f4C5e2Fa6e5ad01af5aB3fd942534b9A ;
    //   export const lendingPoolDeployer =  0xF2Ae7B9a7DB2EF7ed435e6bc1ebC2f3822f4028E ;
    //   export const lendingPoolFactory =  0xf51d621dD942697E013086ecE5Fb4fe59Aa5512f ;
    //   export const lendingPool =  0x06Ce4E2c536dDa1fa00c6715411Fb5B319EAA139 ;
    //   export const position =  0x9F58Fdb2f132c4586DcA6465b9E12140bE67cabE ;

    function setUp() public {
        // host chain
        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        // vm.createSelectFork(vm.rpcUrl("base_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        if (!isDeployed) {
            deployMockToken();
        }

        if (block.chainid == 84532) {
            console.log("export const BASE_mockWETH = ", address(mockWETH), ";");
            console.log("export const BASE_mockUSDC = ", address(mockUSDC), ";");
            console.log("export const BASE_mockUSDT = ", address(mockUSDT), ";");
            console.log("export const BASE_mockWAVAX = ", address(mockWAVAX), ";");
            console.log("export const BASE_mockWBTC = ", address(mockWBTC), ";");
        } else {
            protocol = new Protocol();
            isHealthy = new IsHealthy();
            lendingPoolDeployer = new LendingPoolDeployer();
            if (!isDeployed) {
                lendingPoolFactory = new LendingPoolFactory(
                    address(isHealthy), address(lendingPoolDeployer), address(protocol), address(helperTestnet)
                );
            } else {
                lendingPoolFactory = new LendingPoolFactory(
                    address(isHealthy), address(lendingPoolDeployer), address(protocol), arbHelper
                );
            }
            if (!isDeployed) {
                lendingPool = new LendingPool(address(mockWETH), address(mockUSDC), address(lendingPoolFactory), 7e17);
                position = new Position(
                    address(mockWETH), address(mockUSDC), address(lendingPool), address(lendingPoolFactory)
                );
            } else {
                lendingPool = new LendingPool(ARB_mockWETH, ARB_mockUSDC, address(lendingPoolFactory), 7e17);
                position = new Position(ARB_mockWETH, ARB_mockUSDC, address(lendingPool), address(lendingPoolFactory));
            }

            lendingPoolDeployer.setFactory(address(lendingPoolFactory));

            if (!isDeployed) {
                lendingPoolFactory.addTokenDataStream(address(mockWETH), ARB_EthUsd);
                lendingPoolFactory.addTokenDataStream(address(mockWBTC), ARB_BtcUsd);
                lendingPoolFactory.addTokenDataStream(address(mockWAVAX), ARB_AvaxUsd);
                lendingPoolFactory.addTokenDataStream(address(mockUSDC), ARB_UsdcUsd);
                lendingPoolFactory.addTokenDataStream(address(mockUSDT), ARB_UsdtUsd);
            } else {
                lendingPoolFactory.addTokenDataStream(ARB_mockWETH, ARB_EthUsd);
                lendingPoolFactory.addTokenDataStream(ARB_mockWBTC, ARB_BtcUsd);
                lendingPoolFactory.addTokenDataStream(ARB_mockWAVAX, ARB_AvaxUsd);
                lendingPoolFactory.addTokenDataStream(ARB_mockUSDC, ARB_UsdcUsd);
                lendingPoolFactory.addTokenDataStream(ARB_mockUSDT, ARB_UsdtUsd);
            }

            console.log("export const protocol = ", address(protocol), ";");
            console.log("export const isHealthy = ", address(isHealthy), ";");
            console.log("export const lendingPoolDeployer = ", address(lendingPoolDeployer), ";");
            console.log("export const lendingPoolFactory = ", address(lendingPoolFactory), ";");
            console.log("export const lendingPool = ", address(lendingPool), ";");
            console.log("export const position = ", address(position), ";");
        }

        vm.stopBroadcast();
    }

    function deployMockToken() public {
        if (block.chainid == 84532) {
            helperTestnet = new HelperTestnet();
            baseHelper = address(helperTestnet);
            console.log("address public baseHelper = ", baseHelper, ";");
        }

        if (block.chainid == 421614) {
            helperTestnet = new HelperTestnet();
            arbHelper = address(helperTestnet);
            console.log("address public arbHelper = ", arbHelper, ";");
        }

        if (block.chainid == 84532) {
            mockUSDC = new MockUSDC(baseHelper);
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(baseHelper, address(mockUSDC));
            console.log("address public UsdcBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        }

        if (block.chainid == 421614) {
            mockUSDC = new MockUSDC(arbHelper);
            pairBridgeToToken(arbHelper, address(mockUSDC), UsdcBridgeTokenReceiver, chainId);
            console.log("export const mockUSDC = ", address(mockUSDC), ";");
        }

        if (block.chainid == 84532) {
            chainId = uint32(block.chainid);
            mockUSDT = new MockUSDT(baseHelper);
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(baseHelper, address(mockUSDT));
            console.log("address public UsdtBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        }

        if (block.chainid == 421614) {
            mockUSDT = new MockUSDT(arbHelper);
            pairBridgeToToken(arbHelper, address(mockUSDT), UsdtBridgeTokenReceiver, chainId);
            console.log("export const mockUSDT = ", address(mockUSDT), ";");
        }

        if (block.chainid == 84532) {
            chainId = uint32(block.chainid);
            mockWAVAX = new MockWAVAX(address(helperTestnet));
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockWAVAX));
            console.log("address public WavaxBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        }

        if (block.chainid == 421614) {
            mockWAVAX = new MockWAVAX(address(helperTestnet));
            pairBridgeToToken(address(helperTestnet), address(mockWAVAX), WavaxBridgeTokenReceiver, chainId);
            console.log("export const mockWAVAX = ", address(mockWAVAX), ";");
        }

        if (block.chainid == 84532) {
            chainId = uint32(block.chainid);
            mockWBTC = new MockWBTC(baseHelper);
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(baseHelper, address(mockWBTC));
            console.log("address public BtcBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        }
        if (block.chainid == 421614) {
            mockWBTC = new MockWBTC(arbHelper);
            pairBridgeToToken(arbHelper, address(mockWBTC), BtcBridgeTokenReceiver, chainId);
            console.log("export const mockWBTC = ", address(mockWBTC), ";");
        }

        if (block.chainid == 84532) {
            chainId = uint32(block.chainid);
            mockWETH = new MockWETH(baseHelper);
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(baseHelper, address(mockWETH));
            console.log("address public EthBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        }

        if (block.chainid == 421614) {
            mockWETH = new MockWETH(arbHelper);
            pairBridgeToToken(arbHelper, address(mockWETH), EthBridgeTokenReceiver, chainId);
            console.log("export const mockWETH = ", address(mockWETH), ";");
        }
    }

    function pairBridgeToToken(
        address _helperTestnet,
        address _mockToken,
        address _caerBridgeTokenReceiver,
        uint32 _chainId
    ) public {
        caerBridgeTokenSender = new CaerBridgeTokenSender(
            _helperTestnet,
            _mockToken,
            _caerBridgeTokenReceiver, // ** otherchain ** RECEIVER BRIDGE
            _chainId // ** otherchain ** CHAIN ID
        );
        ITokenSwap(_mockToken).addBridgeTokenSender(address(caerBridgeTokenSender));
    }

    // RUN
    // forge script CaerScript --broadcast --verify
}
