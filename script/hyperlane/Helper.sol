// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

contract Helper is Script {
    address public AVAX_USDC = 0xC014F158EbADce5a8e31f634c0eb062Ce8CDaeFe;
    address public AVAX_USDT = 0x1E713E704336094585c3e8228d5A8d82684e4Fb0;
    address public AVAX_WETH = 0x63CFd5c58332c38d89B231feDB5922f5817DF180;
    address public AVAX_WBTC = 0xa7A93C5F0691a5582BAB12C0dE7081C499aECE7f;
    address public AVAX_WAVAX = 0xA61Eb0D33B5d69DC0D0CE25058785796296b1FBd;

    address public ARB_USDC = 0xCB1cE7974cb8566711775e1cb2D04FaF1293d082;
    address public ARB_USDT = 0x4E64400D95663F1900459C3c46f3667C363Ed33b;
    address public ARB_WAVAX = 0x33925aE397E2688D92c3fc837c5E015DfA73D996;
    address public ARB_WBTC = 0x6234F07ad85805D01446BB7D8e1f8E5e2018cEB1;
    address public ARB_WETH = 0xAeb1279d0BCa98819bb25D76e54d49c221AB5656;

    address public ARB_deployer = 0xF2Ae7B9a7DB2EF7ed435e6bc1ebC2f3822f4028E;
    address public ARB_factory = 0xf51d621dD942697E013086ecE5Fb4fe59Aa5512f;
    address public ARB_lp = 0x06Ce4E2c536dDa1fa00c6715411Fb5B319EAA139;

    address public claimAddress = vm.envAddress("ADDRESS");

    // chain id
    uint256 public ETH_Sepolia = 11155111;
    uint256 public Avalanche_Fuji = 43113;
    uint256 public Arb_Sepolia = 421614;
    uint256 public Base_Sepolia = 84532;
}
