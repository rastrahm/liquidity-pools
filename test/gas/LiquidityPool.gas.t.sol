// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {LiquidityPool} from "../../src/LiquidityPool.sol";
import {LiquidityPoolFactory} from "../../src/LiquidityPoolFactory.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

/**
 * @title LiquidityPoolGasTest
 * @notice Baseline de gas para `forge snapshot` y `doc/GAS-ES.md` (Fase 8).
 */
contract LiquidityPoolGasTest is Test {
    uint256 internal constant LOCK_DURATION = 1 days;

    LiquidityPoolFactory internal factory;
    MockERC20 internal underlying;
    LiquidityPool internal pool;

    address internal lp = makeAddr("lp");
    address internal feePayer = makeAddr("feePayer");

    function setUp() public {
        underlying = new MockERC20("Underlying", "UND");
        factory = new LiquidityPoolFactory(LOCK_DURATION);
        pool = LiquidityPool(factory.createPool(address(underlying)));

        underlying.mint(lp, 100_000 ether);
        underlying.mint(feePayer, 100_000 ether);
    }

    function testGas_createPool() public {
        MockERC20 token = new MockERC20("Other", "OTH");
        factory.createPool(address(token));
    }

    function testGas_firstDeposit() public {
        vm.startPrank(lp);
        underlying.approve(address(pool), 1_000 ether);
        pool.deposit(1_000 ether, lp, 0);
        vm.stopPrank();
    }

    function testGas_subsequentDeposit() public {
        _seedDeposit();
        vm.startPrank(lp);
        underlying.approve(address(pool), 100 ether);
        pool.deposit(100 ether, lp, 0);
        vm.stopPrank();
    }

    function testGas_withdraw() public {
        _seedDeposit();
        uint256 shares = pool.balanceOf(lp) / 2;
        vm.warp(pool.lockUntil(lp) + 1);

        vm.prank(lp);
        pool.withdraw(shares, lp, 0);
    }

    function testGas_accrueFees() public {
        _seedDeposit();
        vm.startPrank(feePayer);
        underlying.approve(address(pool), 50 ether);
        pool.accrueFees(50 ether);
        vm.stopPrank();
    }

    function testGas_previewDeposit() public view {
        pool.previewDeposit(100 ether);
    }

    function testGas_previewWithdraw() public {
        _seedDeposit();
        pool.previewWithdraw(pool.balanceOf(lp));
    }

    function _seedDeposit() internal {
        vm.startPrank(lp);
        underlying.approve(address(pool), 1_000 ether);
        pool.deposit(1_000 ether, lp, 0);
        vm.stopPrank();
    }
}
