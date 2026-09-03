// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ILiquidityPool} from "../../src/interfaces/ILiquidityPool.sol";
import {LiquidityPool} from "../../src/LiquidityPool.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

/**
 * @title LiquidityPoolFuzzTest
 * @notice Fase 7: fuzz de amounts y slippage con `bound()` (SWC-101 / SWC-123).
 */
contract LiquidityPoolFuzzTest is Test {
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant LOCK_DURATION = 1 days;

    MockERC20 internal underlying;
    LiquidityPool internal pool;

    address internal lp = makeAddr("lp");
    address internal lp2 = makeAddr("lp2");

    function setUp() public {
        underlying = new MockERC20("Underlying", "UND");
        pool = new LiquidityPool(address(underlying), LOCK_DURATION, "LP", "LP");

        underlying.mint(lp, type(uint128).max);
        underlying.mint(lp2, type(uint128).max);
    }

    /**
     * @notice Primer depósito: shares = assets - MINIMUM_LIQUIDITY (SWC-101).
     */
    function testFuzz_deposit_firstDeposit_locksMinimum(uint256 assets) public {
        assets = bound(assets, MINIMUM_LIQUIDITY + 1, 1_000_000 ether);

        vm.startPrank(lp);
        underlying.approve(address(pool), assets);
        uint256 shares = pool.deposit(assets, lp, 0);
        vm.stopPrank();

        assertEq(shares, assets - MINIMUM_LIQUIDITY);
        assertEq(pool.balanceOf(address(0)), MINIMUM_LIQUIDITY);
        assertEq(pool.totalAssets(), assets);
        assertEq(pool.totalSupply(), assets);
    }

    /**
     * @notice Depósito posterior pro-rata; slippage respetado (SWC-123).
     */
    function testFuzz_deposit_subsequent_proRataAndSlippage(uint256 firstAssets, uint256 secondAssets) public {
        firstAssets = bound(firstAssets, 1 ether, 100_000 ether);
        secondAssets = bound(secondAssets, 1, 100_000 ether);

        _deposit(lp, firstAssets);

        uint256 supplyBefore = pool.totalSupply();
        uint256 assetsBefore = pool.totalAssets();
        uint256 expectedShares = (secondAssets * supplyBefore) / assetsBefore;
        vm.assume(expectedShares > 0);

        vm.startPrank(lp2);
        underlying.approve(address(pool), secondAssets);
        uint256 shares = pool.deposit(secondAssets, lp2, expectedShares);
        vm.stopPrank();

        assertEq(shares, expectedShares);
        assertEq(pool.totalAssets(), assetsBefore + secondAssets);
    }

    /**
     * @notice `minSharesOut` demasiado alto revierte `SlippageExceeded`.
     */
    function testFuzz_deposit_revertsSlippage(uint256 assets, uint256 extra) public {
        assets = bound(assets, MINIMUM_LIQUIDITY + 1, 100_000 ether);
        extra = bound(extra, 1, 1_000 ether);

        uint256 preview = pool.previewDeposit(assets);

        vm.startPrank(lp);
        underlying.approve(address(pool), assets);
        vm.expectRevert(ILiquidityPool.SlippageExceeded.selector);
        pool.deposit(assets, lp, preview + extra);
        vm.stopPrank();
    }

    /**
     * @notice Withdraw pro-rata tras unlock; assetsOut ≤ totalAssets (SWC-101).
     */
    function testFuzz_withdraw_proRataAfterUnlock(uint256 depositAssets, uint256 withdrawSharesSeed) public {
        depositAssets = bound(depositAssets, 1 ether, 100_000 ether);
        _deposit(lp, depositAssets);

        uint256 lpShares = pool.balanceOf(lp);
        uint256 withdrawShares = bound(withdrawSharesSeed, 1, lpShares);
        uint256 expectedOut = (withdrawShares * pool.totalAssets()) / pool.totalSupply();

        vm.warp(pool.lockUntil(lp) + 1);

        uint256 balBefore = underlying.balanceOf(lp);
        vm.prank(lp);
        uint256 assetsOut = pool.withdraw(withdrawShares, lp, 0);

        assertEq(assetsOut, expectedOut);
        assertLe(assetsOut, depositAssets);
        assertEq(underlying.balanceOf(lp), balBefore + assetsOut);
        assertEq(pool.balanceOf(address(0)), MINIMUM_LIQUIDITY);
    }

    /**
     * @notice Fees aumentan withdrawable de LPs existentes (share price ↑).
     */
    function testFuzz_accrueFees_increasesWithdrawable(uint256 depositAssets, uint256 feeAmount) public {
        depositAssets = bound(depositAssets, 1 ether, 50_000 ether);
        // Fee material respecto al supply para evitar dust que no mueve previewWithdraw.
        feeAmount = bound(feeAmount, depositAssets / 1000 + 1, 10_000 ether);

        _deposit(lp, depositAssets);
        uint256 shares = pool.balanceOf(lp);
        uint256 beforeOut = pool.previewWithdraw(shares);

        underlying.mint(address(this), feeAmount);
        underlying.approve(address(pool), feeAmount);
        pool.accrueFees(feeAmount);

        assertGt(pool.previewWithdraw(shares), beforeOut);
        assertEq(pool.totalAssets(), depositAssets + feeAmount);
    }

    /**
     * @notice Round-trip deposit → withdraw no crea assets (solo dust de rounding).
     */
    function testFuzz_roundTrip_noAssetInflation(uint256 assets) public {
        assets = bound(assets, 1 ether, 50_000 ether);
        _deposit(lp, assets);

        uint256 shares = pool.balanceOf(lp);
        vm.warp(pool.lockUntil(lp) + 1);

        vm.prank(lp);
        uint256 out = pool.withdraw(shares, lp, 0);

        // Quedan MINIMUM_LIQUIDITY shares locked → residual en pool.
        assertLe(out, assets);
        assertEq(pool.balanceOf(address(0)), MINIMUM_LIQUIDITY);
        assertEq(pool.totalAssets(), assets - out);
    }

    function _deposit(address user, uint256 assets) internal {
        vm.startPrank(user);
        underlying.approve(address(pool), assets);
        pool.deposit(assets, user, 0);
        vm.stopPrank();
    }
}
