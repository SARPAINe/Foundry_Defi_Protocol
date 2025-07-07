// Handler is going to narrow down the way we call function

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {console} from "forge-std/console.sol";

contract Handler is Test {
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 public timesMintIsCalled = 0;
    address[] public usersWithCollateralDeposited;

    uint256 constant MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dscEngine = _dscEngine;
        dsc = _dsc;
        address[] memory collateralTokens = dscEngine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // redeem collateral <-
    function depositCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) external {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dscEngine), amountCollateral);
        dscEngine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        // double push if same addresses deposit multiple times
        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) external {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dscEngine.getCollateralBalanceOfUser(
            msg.sender,
            address(collateral)
        );
        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);
        vm.startPrank(msg.sender);
        if (amountCollateral == 0) {
            // If no collateral to redeem, skip the redeem step
            vm.stopPrank();
            return;
        }
        dscEngine.redeemCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    // Helper functions
    function _getCollateralFromSeed(
        uint256 collateralSeed
    ) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else return wbtc;
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if (usersWithCollateralDeposited.length == 0) {
            return; // No users with collateral, cannot mint
        }
        address sender = usersWithCollateralDeposited[
            addressSeed % usersWithCollateralDeposited.length
        ];
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine
            .getAccountInformation(sender);
        int256 maxDscToMint = int256(collateralValueInUsd / 2) -
            int256(totalDscMinted);

        if (maxDscToMint < 0) {
            return;
        }
        uint256 amountToMint = bound(amount, 0, uint256(maxDscToMint));
        if (amountToMint == 0) {
            return; // No need to mint if amount is zero
        }
        vm.startPrank(sender);
        dscEngine.mintDsc(amountToMint);
        vm.stopPrank();
        timesMintIsCalled++;
    }
}
