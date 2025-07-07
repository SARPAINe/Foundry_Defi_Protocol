// // Have our invariants aka properties that should always hold true

// // What are our invariants?

// // 1. The total supply of DSC should be less than the total value of collateral

// // 2. Getter view functions should never revert <- evergreen invariant

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {Test} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DeployDSC} from "../../script/DeployDSC.s.sol";
// import {DSCEngine} from "../../src/DSCEngine.sol";
// import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract OpenInvariantsTest is StdInvariant, Test {
//     DeployDSC deployer;
//     DSCEngine dscEngine;
//     DecentralizedStableCoin dsc;
//     HelperConfig config;
//     address weth;
//     address wbtc;

//     function setUp() public {
//         deployer = new DeployDSC();
//         (dsc, dscEngine, config) = deployer.run();
//         (, , weth, wbtc, ) = config.activeNetworkConfig();
//         targetContract(address(dscEngine));
//     }

//     // We are going to use the invariant macro to define our invariants
//     // The invariant macro will automatically generate a test for us
//     // The test will check if the invariant holds true for all possible states of the contract

//     // Invariant 1: Total supply of DSC should be less than the total value of collateral
//     function invariant_totalSupplyLessThanCollateral() public view {
//         // get the value of all the collateral in the protocol
//         // compare it to all the debt
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethValue = dscEngine.getUsdValue(
//             weth,
//             IERC20(weth).balanceOf(address(dscEngine))
//         );
//         uint256 totalBtcDeposited = dscEngine.getUsdValue(
//             wbtc,
//             IERC20(wbtc).balanceOf(address(dscEngine))
//         );
//         uint256 totalCollateralValue = totalWethValue + totalBtcDeposited;
//         // assert that the total supply of DSC is less than the total value of collateral
//         assert(totalCollateralValue >= totalSupply);
//     }

//     // Invariant 2: Getter view functions should never revert
//     function invariant_getterViewFunctions() public view {
//         // Implement the logic to check the invariant
//         // assert(getterViewFunction() != 0);
//     }
// }
