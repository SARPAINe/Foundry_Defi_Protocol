// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (ethUsdPriceFeed, , weth, , ) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    ////////////////////////////////
    // Constructor tests ///////////
    ////////////////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeedLength() external {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed); // Two price feeds
        vm.expectRevert(
            DSCEngine
                .DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeEqualLength
                .selector
        );
        new DSCEngine(
            tokenAddresses,
            priceFeedAddresses, // Only one price feed
            address(dsc)
        );
    }

    //////////////////////////
    // Price tests ///////////
    //////////////////////////
    function testGetUsdValue() external view {
        uint256 ethAmount = 15e18;

        uint256 expectedUsdValue = 15e18 * 2500; // Assuming ETH price is $2500
        uint256 actualUsdValue = dscEngine.getUsdValue(weth, ethAmount);
        assertEq(
            actualUsdValue,
            expectedUsdValue,
            "USD value calculation is incorrect"
        );
    }

    function testGetTokenAmountFromUsd() external view {
        uint256 usdAmount = 100 ether; // $100
        uint256 expectedTokenAmount = 0.04e18; // Assuming ETH price is $2500
        uint256 actualTokenAmount = dscEngine.getTokenAmountFromUsd(
            weth,
            usdAmount
        );
        assertEq(
            actualTokenAmount,
            expectedTokenAmount,
            "Token amount from USD calculation is incorrect"
        );
    }

    //////////////////////////
    // Deposit Collateral tests /////
    //////////////////////////
    function testRevertsIfCollateralZero() external {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__MustBeMoreThanZero.selector
            )
        );
        dscEngine.depositCollateral(weth, 0);
    }

    function testRevertsWithUnapprovedCollateral() external {
        ERC20Mock ranToken = new ERC20Mock(
            "RAN",
            "RAN",
            USER,
            AMOUNT_COLLATERAL
        );
        vm.startPrank(USER);
        ranToken.approve(address(dscEngine), AMOUNT_COLLATERAL);
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__TokenNotAllowed.selector,
                address(ranToken)
            )
        );
        dscEngine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositedCollateralAndGetAccountInfo()
        public
        depositedCollateral
    {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine
            .getAccountInformation(USER);
        uint256 expectedDepositedAmount = dscEngine.getTokenAmountFromUsd(
            weth,
            collateralValueInUsd
        );
        assertEq(totalDscMinted, 0);
        assertEq(expectedDepositedAmount, AMOUNT_COLLATERAL);
    }
}
