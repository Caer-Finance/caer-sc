// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IBridgeTokenSender} from "../src/hyperlane/interfaces/IBridgeTokenSender.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";
import {IMailbox} from "@hyperlane-xyz/interfaces/IMailbox.sol";

contract ShortcutBridgeScript is Script {
    address public ARB_SEPOLIA_MAILBOX = 0x598facE78a4302f11E3de0bee1894Da0b2Cb71F8;
    address public ARB_SEPOLIA_TOKEN_USDC = 0xEB7262b444F450178D25A5690F49bE8E2Fe5A178;
    uint32 public ARB_SEPOLIA_DOMAIN = 421614;
    address public ARB_SEPOLIA_RECEIVER_BRIDGE = 0xC2F7546d6BB76AaA66f0770AeDf43Db4e9cd69c5;
    // address public ARB_SEPOLIA_SENDER_BRIDGE = 0xd23bB8F4A3541DaC762b139Cd7328376A0cd8288;
    // address public ARB_SEPOLIA_SENDER_BRIDGE =  0xD64eb4435076Ac37f3C43e777D7D7C6B7551f908;
    // address public ARB_SEPOLIA_SENDER_BRIDGE =  0x5454F732917D71984Cb32e192CAD1F3d1f392A62;
    // address public ARB_SEPOLIA_SENDER_BRIDGE =  0x146b1ED5140E08f0FC23D9fB2Dd5b6Ba8A0d573b;
    address public ARB_SEPOLIA_SENDER_BRIDGE =  0xce5A20045d83FcEBb009A6FF6D620E6Ef209177E;

    address public BASE_SEPOLIA_MAILBOX = 0x6966b0E55883d49BFB24539356a2f8A673E02039;
    address public BASE_SEPOLIA_TOKEN_USDC = 0x99B8B801Fb0f371d2B4D426a72bd019b00D6F2d0;
    uint32 public BASE_SEPOLIA_DOMAIN = 84532;

    address public ARB_SEPOLIA_GAS_PARAM = 0xc756cFc1b7d0d4646589EDf10eD54b201237F5e8;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
    }

    function run() public payable {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);


        uint256 gasAmount = IInterchainGasPaymaster(ARB_SEPOLIA_GAS_PARAM).quoteGasPayment(BASE_SEPOLIA_DOMAIN, 1000000);
        console.log("Gas amount", gasAmount);
        console.log("address", vm.envAddress("ADDRESS"));

        // 1_500_102_000_000

        // bytes32 messageId = IMailbox(ARB_SEPOLIA_MAILBOX).dispatch(
        //     BASE_SEPOLIA_DOMAIN,
        //     bytes32(uint256(uint160(vm.envAddress("ADDRESS")))),
        //     abi.encode(vm.envAddress("ADDRESS"))
        // );

        // transfer eth to arb_sepolia_gas_param
        // (bool success,) = ARB_SEPOLIA_SENDER_BRIDGE.call{value: 1}("");
        // require(success, "Transfer failed");
        // console.log("Transfer success");

        // IInterchainGasPaymaster(ARB_SEPOLIA_GAS_PARAM).payForGas{value: gasAmount}(
        //     messageId, BASE_SEPOLIA_DOMAIN, gasAmount, vm.envAddress("ADDRESS")
        // );

        IERC20(ARB_SEPOLIA_TOKEN_USDC).approve(ARB_SEPOLIA_SENDER_BRIDGE, 1e6);
        IBridgeTokenSender(ARB_SEPOLIA_SENDER_BRIDGE).bridge{value: gasAmount}(1e6, vm.envAddress("ADDRESS"));

        vm.stopBroadcast();
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    // RUN
    // forge script ShortcutBridgeScript --rpc-url arb_sepolia --broadcast -vvv
}
