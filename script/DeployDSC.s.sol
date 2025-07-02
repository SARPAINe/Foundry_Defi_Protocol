// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralizedStableCoin dsc, DSCEngine dscEngine, HelperConfig config) {
        config = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            config.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        vm.startBroadcast(deployerKey);
        // Deploy the DecentralizedStableCoin contract
        dsc = new DecentralizedStableCoin();
        console.log("DecentralizedStableCoin deployed at:", address(dsc));

        // Deploy the DSCEngine contract
        dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        console.log("DSCEngine deployed at:", address(dscEngine));

        dsc.transferOwnership(address(dscEngine));

        vm.stopBroadcast();

        return (dsc, dscEngine, config);
    }
}
