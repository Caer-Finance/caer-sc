// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Helper} from "./Helper.sol";
import {HelperTestnet} from "../../src/hyperlane/HelperTestnet.sol";
import {CaerBridgeTokenReceiver} from "../../src/hyperlane/CaerBridgeTokenReceiver.sol";
import {CaerBridgeTokenSender} from "../../src/hyperlane/CaerBridgeTokenSender.sol";
import {MockWBTC} from "../../src/hyperlane/mocks/MockWBTC.sol";
import {MockWETH} from "../../src/hyperlane/mocks/MockWETH.sol";
import {MockUSDC} from "../../src/hyperlane/mocks/MockUSDC.sol";
import {MockUSDT} from "../../src/hyperlane/mocks/MockUSDT.sol";
import {MockWAVAX} from "../../src/hyperlane/mocks/MockWAVAX.sol";

contract DeployTokenNewChainScript is Script, Helper {
    HelperTestnet public helperTestnet;
    CaerBridgeTokenReceiver public caerBridgeTokenReceiver;
    CaerBridgeTokenSender public caerBridgeTokenSender;
    MockUSDC public mockUSDC;
    MockUSDT public mockUSDT;
    MockWAVAX public mockWAVAXMockWAVAX;
    MockWBTC public mockWBTC;
    MockWETH public mockWETH;

    function setUp() public {
        // host chain (etherlink)
        // vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
        // receiver chain
        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        // vm.createSelectFork(vm.rpcUrl("base_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        helperTestnet = new HelperTestnet();
        mockUSDC = new MockUSDC(address(helperTestnet));
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockUSDC));
        console.log("address public UsdcBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        mockUSDT = new MockUSDT(address(helperTestnet));
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockUSDT));
        console.log("address public UsdtBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        mockWAVAXMockWAVAX = new MockWAVAX(address(helperTestnet));
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockWAVAXMockWAVAX));
        console.log("address public WaVAXMockWAVAXBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        mockWBTC = new MockWBTC(address(helperTestnet));
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockWBTC));
        console.log("address public BtcBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");
        mockWETH = new MockWETH(address(helperTestnet));
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockWETH));
        console.log("address public EthBridgeTokenReceiver = ", address(caerBridgeTokenReceiver), ";");

        // **************** SOLIDITY ****************
        console.log("************ COPY DESTINATION ADDRESS **************");
        console.log("address public DESTINATION_helperTestnet = ", address(helperTestnet), ";");
        console.log("address public DESTINATION_mockUSDC = ", address(mockUSDC), ";");
        console.log("address public DESTINATION_mockUSDT = ", address(mockUSDT), ";");
        console.log("address public DESTINATION_mockWAVAXMockWAVAX = ", address(mockWAVAXMockWAVAX), ";");
        console.log("address public DESTINATION_mockWBTC = ", address(mockWBTC), ";");
        console.log("address public DESTINATION_mockWETH = ", address(mockWETH), ";");
        // **************** JAVASCRIPT ****************
        console.log("************ COPY DESTINATION ADDRESS **************");
        console.log("export const DESTINATION_helperTestnet = ", address(helperTestnet), ";");
        console.log("export const DESTINATION_mockWETH = ", address(mockWETH), ";");
        console.log("export const DESTINATION_mockUSDC = ", address(mockUSDC), ";");
        console.log("export const DESTINATION_mockUSDT = ", address(mockUSDT), ";");
        console.log("export const DESTINATION_mockWAVAXMockWAVAX = ", address(mockWAVAXMockWAVAX), ";");
        console.log("export const DESTINATION_mockWBTC = ", address(mockWBTC), ";");
        vm.stopBroadcast();
    }

    // RUN
    // forge script DeployTokenNewChainScript --verify --broadcast -vvv
}
