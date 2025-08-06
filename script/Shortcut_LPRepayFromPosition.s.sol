// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Helper} from "./Helper.sol";
import {ILendingPool} from "../src/interfaces/ILendingPool.sol";
import {ILPRouter} from "../src/interfaces/ILPRouter.sol";

contract LPRepayFromPositionScript is Script, Helper {
    // --------- FILL THIS ----------
    address public yourWallet = vm.envAddress("ADDRESS");
    uint256 public amount = 1;
    // ----------------------------

    function setUp() public {
        // ***************** HOST CHAIN *****************
        vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
        // **********************************************
        // vm.createSelectFork(vm.rpcUrl("arb_sepolia"));
        // vm.createSelectFork(vm.rpcUrl("avalanche_fuji"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address LPRouter = ILendingPool(ORIGIN_lendingPool).router();
        address borrowToken = ILPRouter(LPRouter).borrowToken();
        uint256 decimals = 10 ** IERC20Metadata(borrowToken).decimals();
        uint256 amountToPay = amount * decimals;

        uint256 debtBefore = ILPRouter(LPRouter).userBorrowShares(yourWallet);
        console.log("debtBefore", debtBefore);
        vm.startBroadcast(privateKey);
        // approve
        uint256 shares =
            ((amountToPay * ILPRouter(LPRouter).totalBorrowShares()) / ILPRouter(LPRouter).totalBorrowAssets());
        IERC20(borrowToken).approve(ORIGIN_lendingPool, amountToPay + 1e6);
        ILendingPool(ORIGIN_lendingPool).repayWithSelectedToken(shares, address(ORIGIN_USDC), true);
        uint256 debtAfter = ILPRouter(LPRouter).userBorrowShares(yourWallet);
        console.log("-------------------------------- repay from position --------------------------------");
        console.log("debtAfter", debtAfter);
        vm.stopBroadcast();
    }

    // RUN
    // forge script LPRepayFromPositionScript -vvv --broadcast
}
