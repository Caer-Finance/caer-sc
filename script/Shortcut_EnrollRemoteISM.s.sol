// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

interface IAccountRouter {
    function enrollRemoteRouterAndIsm(uint32 _destinationDomain, bytes32 _router, bytes32 _ism) external;
    function unenrollRemoteRouterAndIsm(uint32 _destinationDomain) external;
}

contract ShortcutEnrollRemoteISM is Script {
    address public baseSepoliaAccountRouter = 0x677a021bdf36a7409D02A974cb6E19EE4c2F0632;
    address public baseSepoliaIsm = 0x924fF8657070da8e038F0B5867e09aFd7c46D1A9;

    address public etherlinkTestnetAccountRouter = 0xC4c34aFF9f5dE4D9623349ce8EAc8589cE796fD7;
    address public etherlinkTestnetIsm = 0x8fe413C32a6A481f5926460E45d04D07d9Be2700;

    address public arbSepoliaAccountRouter = 0xdf2706AD5966ac71C9016b4a4F93c9054e48F54b;
    address public arbSepoliaIsm = 0x810bCA522337827fC846edd5d34020080Ecbfc0B;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        // vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        if (block.chainid == 128123) {
            IAccountRouter(etherlinkTestnetAccountRouter).enrollRemoteRouterAndIsm(
                uint32(84532),
                bytes32(uint256(uint160(baseSepoliaAccountRouter))),
                bytes32(uint256(uint160(baseSepoliaIsm)))
            );
        } else if (block.chainid == 84532) {
            // DONE
            // IAccountRouter(baseSepoliaAccountRouter).enrollRemoteRouterAndIsm(
            //     uint32(128123),
            //     bytes32(uint256(uint160(etherlinkTestnetAccountRouter))),
            //     bytes32(uint256(uint160(etherlinkTestnetIsm)))
            // );
            // // DONE
            // IAccountRouter(baseSepoliaAccountRouter).enrollRemoteRouterAndIsm(
            //     uint32(421614),
            //     bytes32(uint256(uint160(arbSepoliaAccountRouter))),
            //     bytes32(uint256(uint160(arbSepoliaIsm)))
            // );

            IAccountRouter(baseSepoliaAccountRouter).enrollRemoteRouterAndIsm(
                uint32(84532),
                bytes32(uint256(uint160(baseSepoliaAccountRouter))),
                bytes32(uint256(uint160(baseSepoliaIsm)))
            );
        } else if (block.chainid == 421614) {
            // DONE
            IAccountRouter(arbSepoliaAccountRouter).enrollRemoteRouterAndIsm(
                uint32(84532),
                bytes32(uint256(uint160(baseSepoliaAccountRouter))),
                bytes32(uint256(uint160(baseSepoliaIsm)))
            );
            // DONE
            IAccountRouter(arbSepoliaAccountRouter).enrollRemoteRouterAndIsm(
                uint32(128123),
                bytes32(uint256(uint160(etherlinkTestnetAccountRouter))),
                bytes32(uint256(uint160(etherlinkTestnetIsm)))
            );
        }

        vm.stopBroadcast();
    }

    // RUN
    // forge script ShortcutEnrollRemoteISM --broadcast -vvv
}
