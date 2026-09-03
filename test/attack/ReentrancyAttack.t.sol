// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {LiquidityPool} from "../../src/LiquidityPool.sol";
import {MockERC20Reentrant} from "../mocks/MockERC20Reentrant.sol";

/**
 * @title ReentrancyAttackTest
 * @notice Fase 7 / SWC-107: callbacks ERC-20 maliciosos no reentran en deposit/withdraw/accrueFees.
 * @dev Referencia: `doc/SWC-AUDIT.md` · patrón monorepo módulo 06.
 */
contract ReentrancyAttackTest is Test {
    uint256 internal constant LOCK_DURATION = 1 days;

    MockERC20Reentrant internal underlying;
    LiquidityPool internal pool;

    address internal lp = makeAddr("lp");

    function setUp() public {
        underlying = new MockERC20Reentrant("Underlying", "UND");
        pool = new LiquidityPool(address(underlying), LOCK_DURATION, "LP", "LP");

        underlying.mint(lp, 10_000 ether);
        underlying.mint(address(this), 10_000 ether);
    }

    /**
     * @notice SWC-107: reentrada en `deposit` durante `transferFrom` revierte el guard.
     */
    function test_Attack_reenterDeposit_duringDeposit_revertsGuard() public {
        underlying.configure(pool, MockERC20Reentrant.Attack.ReenterDeposit, lp, 1 ether);

        vm.startPrank(lp);
        underlying.approve(address(pool), 1_000 ether);
        // Primera llamada: deposit inicia; en transferFrom reentra deposit → ReentrancyGuard.
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        pool.deposit(1_000 ether, lp, 0);
        vm.stopPrank();
    }

    /**
     * @notice SWC-107: reentrada en `withdraw` durante `transfer` de salida revierte el guard.
     */
    function test_Attack_reenterWithdraw_duringWithdraw_revertsGuard() public {
        // Depósito limpio (sin ataque).
        underlying.configure(pool, MockERC20Reentrant.Attack.None, address(0), 0);
        vm.startPrank(lp);
        underlying.approve(address(pool), 1_000 ether);
        pool.deposit(1_000 ether, lp, 0);
        vm.stopPrank();

        vm.warp(pool.lockUntil(lp) + 1);

        uint256 shares = pool.balanceOf(lp);
        underlying.configure(pool, MockERC20Reentrant.Attack.ReenterWithdraw, lp, shares / 2);

        vm.startPrank(lp);
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        pool.withdraw(shares, lp, 0);
        vm.stopPrank();
    }

    /**
     * @notice SWC-107: reentrada en `accrueFees` durante pull de fees revierte el guard.
     */
    function test_Attack_reenterAccrueFees_duringAccrue_revertsGuard() public {
        underlying.configure(pool, MockERC20Reentrant.Attack.None, address(0), 0);
        vm.startPrank(lp);
        underlying.approve(address(pool), 1_000 ether);
        pool.deposit(1_000 ether, lp, 0);
        vm.stopPrank();

        underlying.configure(pool, MockERC20Reentrant.Attack.ReenterAccrueFees, address(this), 0);
        underlying.approve(address(pool), 100 ether);

        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        pool.accrueFees(100 ether);
    }
}
