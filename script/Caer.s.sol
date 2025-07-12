// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import {Script} from "forge-std/src/Script.sol";
// import {console} from "forge-std/src/console.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
// import {console} from "../lib/forge-std/src/console.sol";
import {MockUSDC} from "../src/hyperlane/mocks/MockUSDC.sol";
import {HelperTestnet} from "../src/hyperlane/HelperTestnet.sol";
import {CaerBridgeTokenSender} from "../src/hyperlane/CaerBridgeTokenSender.sol";
import {CaerBridgeTokenReceiver} from "../src/hyperlane/CaerBridgeTokenReceiver.sol";

contract CaerScript is Script {
    IHelperTestnet public helperTestnet;
    CaerBridgeTokenReceiver public caerBridgeTokenReceiver;
    CaerBridgeTokenSender public caerBridgeTokenSender;
    MockUSDC public mockUSDC;

    uint32 public chainId;

    function setUp() public {
        // host chain
        // vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        uint256 chainId = block.chainId;
        helperTestnet = new HelperTestnet();
        mockUSDC = new MockUSDC(address(helperTestnet));
        caerBridgeTokenReceiver = new CaerBridgeTokenReceiver(address(helperTestnet), address(mockUSDC));

        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        helperTestnet = new HelperTestnet();
        mockUSDC = new MockUSDC(address(helperTestnet));

        vm.stopBroadcast();
    }

    function pairBridgeToToken() public {
        caerBridgeTokenSender = new CaerBridgeTokenSender(
            address(helperTestnet),
            address(mockUSDC),
            address(caerBridgeTokenReceiver), // ** otherchain ** RECEIVER BRIDGE
            chainId // ** otherchain ** CHAIN ID
        );
        mockUSDC.addBridgeTokenSender(address(caerBridgeTokenSender));

        // .. add another bridge token sender
    }
}
