// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDC} from "../src/Mocks/MockUSDC.sol";
import {MockUSDT} from "../src/Mocks/MockUSDT.sol";
import {MockWAVAX} from "../src/Mocks/MockWAVAX.sol";
import {HelperTestnet} from "../src/HelperTestnet.sol";
import {CaerBridgeTokenSender} from "../src/Bridges/CaerBridgeTokenSender.sol";
import {CaerBridgeTokenReceiver} from "../src/Bridges/CaerBridgeTokenReceiver.sol";
import {MockWBTC} from "../src/Mocks/MockWBTC.sol";
import {MockWETH} from "../src/Mocks/MockWETH.sol";

import {Protocol} from "../src/Protocol.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {LendingPoolDeployer} from "../src/LendingPools/LendingPoolDeployer.sol";
import {LendingPoolFactory} from "../src/LendingPools/LendingPoolFactory.sol";
import {LendingPool} from "../src/LendingPools/LendingPool.sol";
import {Position} from "../src/Position.sol";
import {Pricefeed} from "../src/Pricefeed.sol";

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
    Pricefeed public pricefeed;

    // ****************************************************************************
    //************** DEPLOYED TOKEN ************** (ORIGIN CHAIN)
    address public ORIGIN_helperTestnet = 0xe9d03184A57aC9ffc937b29d466D04bf0E7836C4;
    address public ORIGIN_mockUSDC = 0xB8DB4FcdD486a031a3B2CA27B588C015CB99F5F0;
    address public ORIGIN_mockUSDT = 0x2761372682FE39A53A5b1576467a66b258C3fec2;
    address public ORIGIN_mockWAVAX = 0x0320aC8A299b3da6469bE3Da9ED6c84D09309418;
    address public ORIGIN_mockWBTC = 0x50df5e25AB60e150f753B9444D160a80f0279559;
    address public ORIGIN_mockWETH = 0x0355360B7F943974404277936a5C7536B51B9A77;

    //************** Price feed ************** (ORIGIN CHAIN)
    address public BtcUsd = 0xfe66A25096128f57D3876D42cD2B4347a77784c2;
    address public EthUsd = 0xb31D94df41ccc22b46fd2Ae4eA2a6D6eB9c23bfb;
    address public AvaxUsd = 0xE06FE39f066562DBfE390167AE49D8Cb66e1F887;
    // ****************************************************************************

    uint32 public ORIGIN_chainId = 128123;

    //************** Receiver chain **************
    //************** Base Sepolia **************
    address public UsdcBridgeTokenReceiver = 0x4F10564D41097e0Ae49b073cd7Fb689c74e0F81b;
    address public UsdtBridgeTokenReceiver = 0xaaD746aBb9Cd39D745212B80702aFc6e911F3543;
    address public WavaxBridgeTokenReceiver = 0x8dF619bcd1A9F4D33fF283a165F1eEFFE69dF1D4;
    address public BtcBridgeTokenReceiver = 0x246706f939Ee1c50754A060Ec80fD52Ea79022Cc;
    address public EthBridgeTokenReceiver = 0x8BDa1a549676B056A84b37F17739614b2F41Dd02;

    address public DESTINATION_helperTestnet = 0xd579D691CEa9F6999CE652c5827E38E6B7B8FEDd;
    address public DESTINATION_mockUSDC = 0xdfd290562Ce8aB4A4CCBfF3FC459D504a628f8eD;
    address public DESTINATION_mockUSDT = 0xF597525130e6295CFA0C75EA968FBf89D486c528;
    address public DESTINATION_mockWAVAX = 0x10d3743F6A987082CB7B0680cA2283F5839e77CD;
    address public DESTINATION_mockWBTC = 0x11603bf689910b9312bd0915749095C12cc92ac1;
    address public DESTINATION_mockWETH = 0x9A2Da2FA519AFCcCc6B33CA48dFa07fE3a9887eF;
    // ****************************************************************************
    //************** Arbitrum Sepolia **************
    // address public UsdcBridgeTokenReceiver = 0xf9E52b9986Dc95e252473CA9E90DF898c99DbCF9;
    // address public UsdtBridgeTokenReceiver = 0x391aF0bBB3185C29a1f98332898f4b630A5dEc54;
    // address public WavaxBridgeTokenReceiver = 0x0c9A9cAf650FD808ed7b442FD641f12734bEc09f;
    // address public BtcBridgeTokenReceiver = 0x8AD1E2AFC696fAd8A7B376410581e9C69Ab6807B;
    // address public EthBridgeTokenReceiver = 0x9677AB9177b2810b6F6dF9A90BC74E8Cf0618818;

    // address public DESTINATION_helperTestnet = 0x86a421040047dD254B1468a573eDB4F4C931781b;
    // address public DESTINATION_mockUSDC = 0x93Abc28490836C3f50eF44ee7B300E62f4bda8ab;
    // address public DESTINATION_mockUSDT = 0x8B34f890d496Ff9FCdcDb113d3d464Ee54c35623;
    // address public DESTINATION_mockWAVAX = 0x64D3ee701c5d649a8a1582f19812416c132c9700;
    // address public DESTINATION_mockWBTC = 0xa998cBD0798F827a5Ed40A5c461E5052c06ff7C6;
    // address public DESTINATION_mockWETH = 0x9eCee5E6a7D23703Ae46bEA8c293Fa63954E8525;
    // ****************************************************************************

    // ****************************************************************************
    // ********** FILL THIS
    bool public isDeployed = true;
    uint32 public DESTINATION_chainId = 84532;
    // uint32 public DESTINATION_chainId = 421614;

    function setUp() public {
        // host chain (etherlink)
        vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
        // receiver chain
        // vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        // vm.createSelectFork(vm.rpcUrl("base_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        if (block.chainid == DESTINATION_chainId) {
            // ** RECEIVER AND TOKEN
            helperTestnet = new HelperTestnet();
            mockUSDC = new MockUSDC();
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockUSDC));
            console.log("address public UsdcBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
            mockUSDT = new MockUSDT();
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockUSDT));
            console.log("address public UsdtBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
            mockWAVAX = new MockWAVAX();
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockWAVAX));
            console.log("address public WavaxBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
            mockWBTC = new MockWBTC();
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockWBTC));
            console.log("address public BtcBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
            mockWETH = new MockWETH();
            caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockWETH));
            console.log("address public EthBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");

            // **************** SOLIDITY ****************
            console.log("************ COPY DESTINATION ADDRESS **************");
            console.log("address public DESTINATION_helperTestnet = ", address(helperTestnet), ";");
            console.log("address public DESTINATION_mockUSDC = ", address(mockUSDC), ";");
            console.log("address public DESTINATION_mockUSDT = ", address(mockUSDT), ";");
            console.log("address public DESTINATION_mockWAVAX = ", address(mockWAVAX), ";");
            console.log("address public DESTINATION_mockWBTC = ", address(mockWBTC), ";");
            console.log("address public DESTINATION_mockWETH = ", address(mockWETH), ";");
            // **************** JAVASCRIPT ****************
            console.log("************ COPY DESTINATION ADDRESS **************");
            console.log("export const DESTINATION_helperTestnet = ", address(helperTestnet), ";");
            console.log("export const DESTINATION_mockWETH = ", address(mockWETH), ";");
            console.log("export const DESTINATION_mockUSDC = ", address(mockUSDC), ";");
            console.log("export const DESTINATION_mockUSDT = ", address(mockUSDT), ";");
            console.log("export const DESTINATION_mockWAVAX = ", address(mockWAVAX), ";");
            console.log("export const DESTINATION_mockWBTC = ", address(mockWBTC), ";");
            // *************************************************
        } else if (block.chainid == ORIGIN_chainId && !isDeployed) {
            // **************** DEPLOY PROTOCOL ******************
            protocol = new Protocol();
            isHealthy = new IsHealthy();
            lendingPoolDeployer = new LendingPoolDeployer();
            helperTestnet = new HelperTestnet();
            // *************************************************

            // **************** DEPLOY TOKEN ******************
            deployMockToken();
            // *************************************************

            // **************** CORE CONTRACT ******************
            lendingPoolFactory = new LendingPoolFactory(
                address(isHealthy),
                address(lendingPoolDeployer),
                address(0),
                address(protocol),
                address(helperTestnet),
                address(0)
            );
            lendingPool = new LendingPool(
                address(mockWETH), address(mockUSDC), address(lendingPoolFactory), address(protocol), 7e17
            );
            position =
                new Position(address(mockWETH), address(mockUSDC), address(lendingPool), address(lendingPoolFactory));
            lendingPoolDeployer.setFactory(address(lendingPoolFactory));
            // *************************************************

            // **************** PRICE FEED ******************
            pricefeed = new Pricefeed(address(mockUSDC));
            pricefeed.setPrice(1e8);
            lendingPoolFactory.addTokenDataStream(address(mockUSDC), address(pricefeed));

            pricefeed = new Pricefeed(address(mockUSDT));
            pricefeed.setPrice(1e8);
            lendingPoolFactory.addTokenDataStream(address(mockUSDT), address(pricefeed));

            lendingPoolFactory.addTokenDataStream(address(mockWETH), EthUsd);
            lendingPoolFactory.addTokenDataStream(address(mockWBTC), BtcUsd);
            lendingPoolFactory.addTokenDataStream(address(mockWAVAX), AvaxUsd);
            // *************************************************

            // **************** SOLIDITY ****************
            console.log("************ COPY ORIGIN ADDRESS **************");
            console.log("address public protocol = ", address(protocol), ";");
            console.log("address public isHealthy = ", address(isHealthy), ";");
            console.log("address public lendingPoolDeployer = ", address(lendingPoolDeployer), ";");
            console.log("address public lendingPoolFactory = ", address(lendingPoolFactory), ";");
            console.log("address public lendingPool = ", address(lendingPool), ";");
            console.log("address public position = ", address(position), ";");
            // **************** JAVASCRIPT ****************
            console.log("************ COPY ORIGIN ADDRESS **************");
            console.log("export const protocol = ", address(protocol), ";");
            console.log("export const isHealthy = ", address(isHealthy), ";");
            console.log("export const lendingPoolDeployer = ", address(lendingPoolDeployer), ";");
            console.log("export const lendingPoolFactory = ", address(lendingPoolFactory), ";");
            console.log("export const lendingPool = ", address(lendingPool), ";");
            console.log("export const position = ", address(position), ";");
        } else if (block.chainid == ORIGIN_chainId && isDeployed) {
            ///* 1.DEPLOY HYPERLANE TO DESTINATION CHAIN
            ///* 2.DEPLOY RECEIVER
            if (DESTINATION_chainId == 421614 || DESTINATION_chainId == 128123 || DESTINATION_chainId == 84532) {
                revert("Deployed");
            }
            pairBridgeToToken(ORIGIN_helperTestnet, ORIGIN_mockUSDC, UsdcBridgeTokenReceiver, DESTINATION_chainId);
            pairBridgeToToken(ORIGIN_helperTestnet, ORIGIN_mockUSDT, UsdtBridgeTokenReceiver, DESTINATION_chainId);
            pairBridgeToToken(ORIGIN_helperTestnet, ORIGIN_mockWAVAX, WavaxBridgeTokenReceiver, DESTINATION_chainId);
            pairBridgeToToken(ORIGIN_helperTestnet, ORIGIN_mockWBTC, BtcBridgeTokenReceiver, DESTINATION_chainId);
            pairBridgeToToken(ORIGIN_helperTestnet, ORIGIN_mockWETH, EthBridgeTokenReceiver, DESTINATION_chainId);
            ///* DONE
            ///**** ETHERLINK
            ///**** BASE
            ///**** ARBITRUM
        }

        vm.stopBroadcast();
    }

    function deployMockToken() public {
        if (UsdcBridgeTokenReceiver == address(0)) revert("UsdcBridgeTokenReceiver is not set");
        mockUSDC = new MockUSDC();
        pairBridgeToToken(address(helperTestnet), address(mockUSDC), UsdcBridgeTokenReceiver, DESTINATION_chainId);

        if (UsdtBridgeTokenReceiver == address(0)) revert("UsdtBridgeTokenReceiver is not set");
        mockUSDT = new MockUSDT();
        pairBridgeToToken(address(helperTestnet), address(mockUSDT), UsdtBridgeTokenReceiver, DESTINATION_chainId);

        if (WavaxBridgeTokenReceiver == address(0)) revert("WavaxBridgeTokenReceiver is not set");
        mockWAVAX = new MockWAVAX();
        pairBridgeToToken(address(helperTestnet), address(mockWAVAX), WavaxBridgeTokenReceiver, DESTINATION_chainId);

        if (BtcBridgeTokenReceiver == address(0)) revert("BtcBridgeTokenReceiver is not set");
        mockWBTC = new MockWBTC();
        pairBridgeToToken(address(helperTestnet), address(mockWBTC), BtcBridgeTokenReceiver, DESTINATION_chainId);

        if (EthBridgeTokenReceiver == address(0)) revert("EthBridgeTokenReceiver is not set");
        mockWETH = new MockWETH();
        pairBridgeToToken(address(helperTestnet), address(mockWETH), EthBridgeTokenReceiver, DESTINATION_chainId);
        // **************** SOLIDITY ****************
        console.log("************ COPY ORIGIN ADDRESS **************");
        console.log("address public ORIGIN_helperTestnet = ", address(helperTestnet), ";");
        console.log("address public ORIGIN_mockUSDC = ", address(mockUSDC), ";");
        console.log("address public ORIGIN_mockUSDT = ", address(mockUSDT), ";");
        console.log("address public ORIGIN_mockWAVAX = ", address(mockWAVAX), ";");
        console.log("address public ORIGIN_mockWBTC = ", address(mockWBTC), ";");
        console.log("address public ORIGIN_mockWETH = ", address(mockWETH), ";");
        // **************** JAVASCRIPT ****************
        console.log("************ COPY ORIGIN ADDRESS **************");
        console.log("export const ORIGIN_helperTestnet = ", address(helperTestnet), ";");
        console.log("export const ORIGIN_mockUSDC = ", address(mockUSDC), ";");
        console.log("export const ORIGIN_mockUSDT = ", address(mockUSDT), ";");
        console.log("export const ORIGIN_mockWAVAX = ", address(mockWAVAX), ";");
        console.log("export const ORIGIN_mockWBTC = ", address(mockWBTC), ";");
        console.log("export const ORIGIN_mockWETH = ", address(mockWETH), ";");
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
        // TODO: add to BridgeRouter
        // ITokenSwap(_mockToken).addBridgeTokenSender(address(caerBridgeTokenSender));
    }

    // RUN
    // forge script CaerScript --broadcast -vvv --verify
}
