// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

// import {BurnMintERC677} from "@chainlink-evm/contracts/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
// import {IGetCCIPAdmin} from "@chainlink-ccip/chains/evm/contracts/interfaces/IGetCCIPAdmin.sol";
import {BurnMintERC677} from "../../../lib/chainlink-evm/contracts/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {IGetCCIPAdmin} from "../../../lib/chainlink-ccip/chains/evm/contracts/interfaces/IGetCCIPAdmin.sol";

contract MockWETH is BurnMintERC677, IGetCCIPAdmin {
    address public helperTestnet;
    address public bridgeTokenSender;

    constructor(address _helperTestnet) BurnMintERC677("Wrapped Ethereum", "WETH", 18, 0) {
        helperTestnet = _helperTestnet;
    }

    // this function for hackathon purposes
    function mintMock(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnMock(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function getCCIPAdmin() external view override returns (address) {
        return owner();
    }

    function addBridgeTokenSender(address _bridgeTokenSender) public onlyOwner {
        bridgeTokenSender = _bridgeTokenSender;
    }
}
