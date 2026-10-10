// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ILiquidityPool} from "../../src/interfaces/ILiquidityPool.sol";
import {LiquidityPool} from "../../src/LiquidityPool.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

/**
 * @title FirstDepositAttackTest
 * @notice Fase 7: donation / inflation attack no drena depósitos posteriores.
 * @dev Referencia: `doc/SWC-AUDIT-ES.md` · MINIMUM_LIQUIDITY = 1000 wei a `address(0)`.
 */
contract FirstDepositAttackTest is Test {
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant LOCK_DURATION = 1 days;

    MockERC20 internal underlying;
    LiquidityPool internal pool;

    address internal attacker = makeAddr("attacker");
    address internal victim = makeAddr("victim");

    function setUp() public {
        underlying = new MockERC20("Underlying", "UND");
        pool = new LiquidityPool(address(underlying), LOCK_DURATION, "LP", "LP");

        underlying.mint(attacker, 1_000_000 ether);
        underlying.mint(victim, 1_000_000 ether);
    }

    /**
     * @notice Tras depósito mínimo + donación masiva, la víctima recibe shares > 0.
     */
    function test_Attack_inflation_victimStillReceivesShares() public {
        // Attacker: primer depósito justo por encima de MINIMUM_LIQUIDITY → 1 share.
        vm.startPrank(attacker);
        underlying.approve(address(pool), MINIMUM_LIQUIDITY + 1);
        uint256 attackerShares = pool.deposit(MINIMUM_LIQUIDITY + 1, attacker, 0);
        vm.stopPrank();
        assertEq(attackerShares, 1);
        assertEq(pool.balanceOf(address(0)), MINIMUM_LIQUIDITY);

        // Donación + sync para inflar share price.
        uint256 donation = 10_000 ether;
        vm.prank(attacker);
        underlying.transfer(address(pool), donation);
        pool.accrueFees(0);

        uint256 victimDeposit = 10_000 ether;
        uint256 preview = pool.previewDeposit(victimDeposit);
        assertGt(preview, 0, "victim must receive shares despite donation");

        vm.startPrank(victim);
        underlying.approve(address(pool), victimDeposit);
        uint256 victimShares = pool.deposit(victimDeposit, victim, 0);
        vm.stopPrank();

        assertEq(victimShares, preview);
        assertGt(victimShares, 0);
    }

    /**
     * @notice La víctima no pierde el depósito: withdraw ≈ deposit (menos dust de dead shares).
     */
    function test_Attack_inflation_victimCannotBeDrained() public {
        vm.startPrank(attacker);
        underlying.approve(address(pool), MINIMUM_LIQUIDITY + 1);
        pool.deposit(MINIMUM_LIQUIDITY + 1, attacker, 0);
        underlying.transfer(address(pool), 10_000 ether);
        vm.stopPrank();
        pool.accrueFees(0);

        uint256 victimDeposit = 10_000 ether;
        vm.startPrank(victim);
        underlying.approve(address(pool), victimDeposit);
        uint256 victimShares = pool.deposit(victimDeposit, victim, 0);
        vm.stopPrank();

        vm.warp(pool.lockUntil(victim) + 1);

        uint256 balBefore = underlying.balanceOf(victim);
        vm.prank(victim);
        uint256 assetsOut = pool.withdraw(victimShares, victim, 0);

        // Con MINIMUM_LIQUIDITY, la víctima recupera casi todo su depósito (no se drena a ~0).
        assertGt(assetsOut, victimDeposit * 90 / 100, "victim recovered >= 90% of deposit");
        assertEq(underlying.balanceOf(victim), balBefore + assetsOut);
    }

    /**
     * @notice Sin sync, donaciones no alteran `totalAssets` ni diluyen shares (contabilidad explícita).
     */
    function test_Attack_donationWithoutSync_doesNotInflateSharePrice() public {
        _deposit(attacker, 1_000 ether);

        uint256 assetsBefore = pool.totalAssets();
        uint256 previewBefore = pool.previewDeposit(500 ether);

        vm.prank(attacker);
        underlying.transfer(address(pool), 5_000 ether);

        assertEq(pool.totalAssets(), assetsBefore, "totalAssets unchanged without sync");
        assertEq(pool.previewDeposit(500 ether), previewBefore, "share price unchanged");
        assertGt(underlying.balanceOf(address(pool)), pool.totalAssets());
    }

    /**
     * @notice Primer depósito ≤ MINIMUM_LIQUIDITY no permite bootstrap del ataque.
     */
    function test_Attack_firstDepositTooSmall_revertsZeroLiquidity() public {
        vm.startPrank(attacker);
        underlying.approve(address(pool), MINIMUM_LIQUIDITY);
        vm.expectRevert(ILiquidityPool.ZeroLiquidity.selector);
        pool.deposit(MINIMUM_LIQUIDITY, attacker, 0);
        vm.stopPrank();
    }

    function _deposit(address user, uint256 assets) internal {
        vm.startPrank(user);
        underlying.approve(address(pool), assets);
        pool.deposit(assets, user, 0);
        vm.stopPrank();
    }
}
