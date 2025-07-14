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

    address public baseHelper = 0xBFBf0284811C6016C7a3D58002c42A331F25c7E9;
    address public UsdcBridgeTokenReceiver = 0xbCB5804326A1DDe83fFEdE29095837cfDFae66e3;
    address public UsdtBridgeTokenReceiver = 0x2cDCD2b4AEe98d46bBF95E1e72d42d99D8Ddb334;
    address public WavaxBridgeTokenReceiver = 0x8C7eBB641777A9B84cEC73b94fa12E9dbE66a4CE;
    address public BtcBridgeTokenReceiver = 0xEd15F92c4DDc8e88D4d4a25DA8cF01303b4aa289;
    address public EthBridgeTokenReceiver = 0x4CBE9e7144B58F261f490B0eBEdFf4FDe91Ec369;
    //   export const BASE_mockWETH =  0x21cF2C6125939e0eCbf750309E32BAB3332240d8 ;
    //   export const BASE_mockUSDC =  0x86Ed7e036864163A76129C273Aa4DdffcAb4C289 ;
    //   export const BASE_mockUSDT =  0xF7f49fB0e729EC9dbb735772e81470822B0F3617 ;
    //   export const BASE_mockWAVAX =  0x9C53C78b369F1E5547888b3be29c9965762DcA52 ;
    //   export const BASE_mockWBTC =  0x3E33c712c3B259f61c19BE022824c030ed360F2a ;

    // address public arbHelper;
    address public arbHelper = 0x15257Ec35D606849D2DBC3ee3D49707D8b61E87D;

    address public ARB_mockUSDC = 0x2BF6F2726A8fB77033cD5FCd30Bf56836B602a1F;
    address public ARB_mockUSDT = 0xb76612Bf1C76b56f191f28eB7FDd37988d79E6bc;
    address public ARB_mockWAVAX = 0x7f6F9cca3AE061576091dF5830605E413549402f;
    address public ARB_mockWBTC = 0xE430Cfb554d6D9B27E5BcC61FdBEDbDD37749C73;
    address public ARB_mockWETH = 0xC8a00955106fC3cF2D932B4feCF25fa8cdF96174;

    //   address public arbHelper =  0x15257Ec35D606849D2DBC3ee3D49707D8b61E87D ;
    //   export const mockUSDC =  0x2BF6F2726A8fB77033cD5FCd30Bf56836B602a1F ;
    //   export const mockUSDT =  0xb76612Bf1C76b56f191f28eB7FDd37988d79E6bc ;
    //   export const mockWAVAX =  0x7f6F9cca3AE061576091dF5830605E413549402f ;
    //   export const mockWBTC =  0xE430Cfb554d6D9B27E5BcC61FdBEDbDD37749C73 ;
    //   export const mockWETH =  0xC8a00955106fC3cF2D932B4feCF25fa8cdF96174 ;
    //   export const protocol =  0xD8F3efDadFb57E2C2597cAd634DDBf08197a2085 ;
    //   export const isHealthy =  0xbF5d87C06d9928F7C26F8e2c4389Bc7C9aC87Da4 ;
    //   export const lendingPoolDeployer =  0x03F296A65d1dD4E009CD8F1b8f1aD2fCc6C876C1 ;
    //   export const lendingPoolFactory =  0xA610d431d569fd19F725161c7F1C2C0c52Ad06F9 ;
    //   export const lendingPool =  0xAc98a0f651C4F09e894aBDFCAbB0620895b30cD9 ;
    //   export const position =  0x0EDc826Bf5aDBD3A54925C34dF268786Ba4481cC ;

    function setUp() public {
        // host chain
        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        // vm.createSelectFork(vm.rpcUrl("base_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        // deployMockToken();
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
            // lendingPoolFactory = new LendingPoolFactory(
            //     address(isHealthy), address(lendingPoolDeployer), address(protocol), address(helperTestnet)
            // );
            lendingPoolFactory =
                new LendingPoolFactory(address(isHealthy), address(lendingPoolDeployer), address(protocol), arbHelper);

            // lendingPool = new LendingPool(address(mockWETH), address(mockUSDC), address(lendingPoolFactory), 7e17);
            // position = new Position(address(mockWETH), address(mockUSDC), address(lendingPool), address(lendingPoolFactory));

            lendingPool = new LendingPool(ARB_mockWETH, ARB_mockUSDC, address(lendingPoolFactory), 7e17);
            position = new Position(ARB_mockWETH, ARB_mockUSDC, address(lendingPool), address(lendingPoolFactory));
            lendingPoolDeployer.setFactory(address(lendingPoolFactory));

            // lendingPoolFactory.addTokenDataStream(address(mockWETH), ARB_EthUsd);
            // lendingPoolFactory.addTokenDataStream(address(mockWBTC), ARB_BtcUsd);
            // lendingPoolFactory.addTokenDataStream(address(mockWAVAX), ARB_AvaxUsd);
            // lendingPoolFactory.addTokenDataStream(address(mockUSDC), ARB_UsdcUsd);
            // lendingPoolFactory.addTokenDataStream(address(mockUSDT), ARB_UsdtUsd);

            lendingPoolFactory.addTokenDataStream(ARB_mockWETH, ARB_EthUsd);
            lendingPoolFactory.addTokenDataStream(ARB_mockWBTC, ARB_BtcUsd);
            lendingPoolFactory.addTokenDataStream(ARB_mockWAVAX, ARB_AvaxUsd);
            lendingPoolFactory.addTokenDataStream(ARB_mockUSDC, ARB_UsdcUsd);
            lendingPoolFactory.addTokenDataStream(ARB_mockUSDT, ARB_UsdtUsd);

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
