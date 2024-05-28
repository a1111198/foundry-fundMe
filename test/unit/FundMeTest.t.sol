// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant INITIAL_USER_BALANCE = 10 ether;
    uint256 constant SEND_AMOUNT = 0.1 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, INITIAL_USER_BALANCE);
    }

    function testMinimumFiveUSD() external view {
        uint256 expected = 5 * 10 ** 18;
        uint256 actual = fundMe.MINIMUM_USD();
        assertEq(actual, expected);
    }

    function testIsOnwerSameAsSender() external view {
        address expected = msg.sender;
        address actual = fundMe.getOwner();
        assertEq(actual, expected);
    }

    function testIsSamePriceFeedVersion() external view {
        uint256 expected = 4;
        uint256 actual = fundMe.getVersion();
        assertEq(actual, expected);
    }

    function testFail_FundLessThanMinimum() external {
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_AMOUNT}();
        _;
    }

    function testFundUpdatesFundedAmount() external funded {
        uint256 expected = SEND_AMOUNT;
        uint256 actual = fundMe.getFundedAmountFromAddress(USER);
        assertEq(actual, expected);
    }

    function testAddFundersToFundersArray() external funded {
        assertEq(fundMe.getFunder(0), USER);
    }

    function testFail_OnlyOwnerCanWithdraw() external funded {
        fundMe.withdraw();
    }

    function test_OnlyOwnerCanWithdraw() external funded {
        vm.prank(msg.sender);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() external funded {
        //Arrange
        uint256 ownerInitialBalance = fundMe.getOwner().balance;
        uint256 fundMeInitalBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 ownerAfterBalance = fundMe.getOwner().balance;
        uint256 fundMeAfterBalance = address(fundMe).balance;
        assertEq(fundMeAfterBalance, 0);
        assertEq(ownerAfterBalance, ownerInitialBalance + fundMeInitalBalance);
    }

    function testWithdrawWithMultipleFunder() external funded {
        //Arrange
        uint160 totalFunders = 10;
        uint160 initalIndex = 1;
        for (uint160 i = initalIndex; i < totalFunders; i++) {
            hoax(address(i), INITIAL_USER_BALANCE);
            fundMe.fund{value: SEND_AMOUNT}();
        }
        uint256 ownerInitialBalance = fundMe.getOwner().balance;
        uint256 fundMeInitalBalance = address(fundMe).balance;
        //Act

        vm.startPrank(fundMe.getOwner());
        uint256 startGas = gasleft();
        fundMe.withdraw();
        uint256 endGas = gasleft();
        uint256 gasUsed = (startGas - endGas);
        console.log("GAS USED");
        console.log(gasUsed);
        console.log("txPrice");
        uint256 gasPrice = tx.gasprice;
        console.log(gasPrice);
        vm.stopPrank();
        //Assert
        uint256 ownerAfterBalance = fundMe.getOwner().balance;
        uint256 fundMeAfterBalance = address(fundMe).balance;
        assertEq(fundMeAfterBalance, 0);
        assertEq(ownerAfterBalance, ownerInitialBalance + fundMeInitalBalance);
    }
}
