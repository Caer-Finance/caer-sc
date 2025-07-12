// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import {Script} from "forge-std/src/Script.sol";
// import {console} from "forge-std/src/console.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
// import {console} from "../lib/forge-std/src/console.sol";
import {MockUSDC} from "../src/hyperlane/mocks/MockUSDC.sol";
import {MockUSDT} from "../src/hyperlane/mocks/MockUSDT.sol";
import {MockWAVAX} from "../src/hyperlane/mocks/MockWAVAX.sol";
import {HelperTestnet} from "../src/hyperlane/HelperTestnet.sol";
import {CaerBridgeTokenSender} from "../src/hyperlane/CaerBridgeTokenSender.sol";
import {CaerBridgeTokenReceiver} from "../src/hyperlane/CaerBridgeTokenReceiver.sol";
import {MockWBTC} from "../src/hyperlane/mocks/MockWBTC.sol";
import {MockWETH} from "../src/hyperlane/mocks/MockWETH.sol";
import {ITokenSwap} from "../src/hyperlane/interfaces/ITokenSwap.sol";

contract CaerScript is Script {
    HelperTestnet public helperTestnet;
    CaerBridgeTokenReceiver public caerBridgeTokenReceiver;
    CaerBridgeTokenSender public caerBridgeTokenSender;
    MockUSDC public mockUSDC;
    MockUSDT public mockUSDT;
    MockWAVAX public mockWAVAX;
    MockWBTC public mockWBTC;
    MockWETH public mockWETH;
    uint32 public chainId;

    function setUp() public {
        // host chain
        // vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        helperTestnet = new HelperTestnet();
        address baseHelper = address(helperTestnet);

        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        helperTestnet = new HelperTestnet();
        address arbHelper = address(helperTestnet);

        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        chainId = uint32(block.chainid);
        mockUSDC = new MockUSDC(baseHelper);
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(baseHelper, address(mockUSDC));

        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        mockUSDC = new MockUSDC(arbHelper);

        pairBridgeToToken(arbHelper, address(mockUSDC), address(caerBridgeTokenReceiver), chainId);

        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        chainId = uint32(block.chainid);
        mockUSDT = new MockUSDT(baseHelper);
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(baseHelper, address(mockUSDT));

        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        mockUSDT = new MockUSDT(arbHelper);

        pairBridgeToToken(arbHelper, address(mockUSDT), address(caerBridgeTokenReceiver), chainId);

        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        chainId = uint32(block.chainid);
        mockWAVAX = new MockWAVAX(address(helperTestnet));
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockWAVAX));

        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        mockWAVAX = new MockWAVAX(address(helperTestnet));

        pairBridgeToToken(address(helperTestnet), address(mockWAVAX), address(caerBridgeTokenReceiver), chainId);

        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        chainId = uint32(block.chainid);
        mockWBTC = new MockWBTC(baseHelper);
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(baseHelper, address(mockWBTC));

        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        mockWBTC = new MockWBTC(arbHelper);

        pairBridgeToToken(arbHelper, address(mockWBTC), address(caerBridgeTokenReceiver), chainId);

        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        chainId = uint32(block.chainid);
        mockWETH = new MockWETH(baseHelper);
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(baseHelper, address(mockWETH));

        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        mockWETH = new MockWETH(arbHelper);

        pairBridgeToToken(arbHelper, address(mockWETH), address(caerBridgeTokenReceiver), chainId);

        vm.stopBroadcast();
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
}
