// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

contract Helper is Script {
    address public AVAX_USDC = 0xC014F158EbADce5a8e31f634c0eb062Ce8CDaeFe;
    address public AVAX_USDT = 0x1E713E704336094585c3e8228d5A8d82684e4Fb0;
    address public AVAX_WETH = 0x63CFd5c58332c38d89B231feDB5922f5817DF180;
    address public AVAX_WBTC = 0xa7A93C5F0691a5582BAB12C0dE7081C499aECE7f;
    address public AVAX_WAVAX = 0xA61Eb0D33B5d69DC0D0CE25058785796296b1FBd;

    address public ARB_USDC = 0x2BF6F2726A8fB77033cD5FCd30Bf56836B602a1F;
    address public ARB_USDT = 0xb76612Bf1C76b56f191f28eB7FDd37988d79E6bc;
    address public ARB_WAVAX = 0x7f6F9cca3AE061576091dF5830605E413549402f;
    address public ARB_WBTC = 0xE430Cfb554d6D9B27E5BcC61FdBEDbDD37749C73;
    address public ARB_WETH = 0xC8a00955106fC3cF2D932B4feCF25fa8cdF96174;

    address public ARB_deployer = 0x03F296A65d1dD4E009CD8F1b8f1aD2fCc6C876C1;
    address public ARB_factory = 0xA610d431d569fd19F725161c7F1C2C0c52Ad06F9;
    address public ARB_lp = 0xAc98a0f651C4F09e894aBDFCAbB0620895b30cD9;

    address public claimAddress = vm.envAddress("ADDRESS");

    // chain id
    uint256 public ETH_Sepolia = 11155111;
    uint256 public Avalanche_Fuji = 43113;
    uint256 public Arb_Sepolia = 421614;
    uint256 public Base_Sepolia = 84532;
}
