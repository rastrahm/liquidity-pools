// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ILiquidityPool} from "../src/interfaces/ILiquidityPool.sol";
import {LiquidityPool} from "../src/LiquidityPool.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/**
 * @title LiquidityPoolTest
 * @notice Suite TDD del pool: deposit / withdraw / reverts.
 * @dev Fases 3–5: deposit, withdraw y fee accrual verdes.
 */
contract LiquidityPoolTest is Test {
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant LOCK_DURATION = 1 days;
    uint256 internal constant FIRST_DEPOSIT = 1000 ether;
    uint256 internal constant SECOND_DEPOSIT = 500 ether;

    MockERC20 internal underlying;
    LiquidityPool internal pool;

    address internal lp = makeAddr("lp");
    address internal lp2 = makeAddr("lp2");
    address internal recipient = makeAddr("recipient");

    function setUp() public {
        underlying = new MockERC20("Pool Underlying", "UND");
        pool = new LiquidityPool(address(underlying), LOCK_DURATION, "Liquidity Pool LP", "LPLP");

        underlying.mint(lp, 100_000 ether);
        underlying.mint(lp2, 100_000 ether);
    }

    // -------------------------------------------------------------------------
    // Views / constructor
    // -------------------------------------------------------------------------

    /**
     * @notice Constructor fija immutables, MINIMUM_LIQUIDITY y estado inicial en cero.
     */
    function test_constructor_setsImmutablesAndMinimumLiquidity() public view {
        assertEq(pool.underlying(), address(underlying));
        assertEq(pool.lockDuration(), LOCK_DURATION);
        assertEq(pool.MINIMUM_LIQUIDITY(), MINIMUM_LIQUIDITY);
        assertEq(pool.totalAssets(), 0);
        assertEq(pool.accFeePerShare(), 0);
        assertEq(pool.totalSupply(), 0);
    }

    /**
     * @notice Underlying cero revierte `ZeroAddress`.
     */
    function test_constructor_revertsZeroAddress() public {
        vm.expectRevert(ILiquidityPool.ZeroAddress.selector);
        new LiquidityPool(address(0), LOCK_DURATION, "LP", "LP");
    }

    /**
     * @notice `lockUntil` es cero antes del primer depósito.
     */
    function test_lockUntil_initialIsZero() public view {
        assertEq(pool.lockUntil(lp), 0);
    }

    // -------------------------------------------------------------------------
    // preview — fase 2 (verdes)
    // -------------------------------------------------------------------------

    /**
     * @notice `previewDeposit` en pool vacío: assets - MINIMUM_LIQUIDITY.
     */
    function test_previewDeposit_firstDeposit_onEmptyPool() public view {
        uint256 shares = pool.previewDeposit(FIRST_DEPOSIT);
        assertEq(shares, FIRST_DEPOSIT - MINIMUM_LIQUIDITY);
    }

    /**
     * @notice `previewDeposit` con assets ≤ MINIMUM_LIQUIDITY retorna 0.
     */
    function test_previewDeposit_firstDepositTooSmallReturnsZero() public view {
        assertEq(pool.previewDeposit(MINIMUM_LIQUIDITY), 0);
        assertEq(pool.previewDeposit(500), 0);
    }

    /**
     * @notice `previewWithdraw` en pool vacío retorna 0.
     */
    function test_previewWithdraw_emptyPoolReturnsZero() public view {
        assertEq(pool.previewWithdraw(100 ether), 0);
    }

    // -------------------------------------------------------------------------
    // deposit — caminos felices (fase 3)
    // -------------------------------------------------------------------------

    /**
     * @notice Primer depósito: shares = assets - MINIMUM_LIQUIDITY; lock 1000 wei a `address(0)`.
     */
    function test_deposit_firstDeposit_locksMinimumLiquidityAndMintsShares() public {
        uint256 expectedShares = FIRST_DEPOSIT - MINIMUM_LIQUIDITY;

        vm.startPrank(lp);
        underlying.approve(address(pool), FIRST_DEPOSIT);

        vm.expectEmit(true, true, false, true, address(pool));
        emit ILiquidityPool.Deposit(lp, lp, FIRST_DEPOSIT, expectedShares);

        uint256 shares = pool.deposit(FIRST_DEPOSIT, lp, 0);
        vm.stopPrank();

        assertEq(shares, expectedShares, "LP minted to provider");
        assertEq(pool.balanceOf(lp), expectedShares);
        assertEq(pool.balanceOf(address(0)), MINIMUM_LIQUIDITY, "MINIMUM_LIQUIDITY locked");
        assertEq(pool.totalSupply(), expectedShares + MINIMUM_LIQUIDITY);
        assertEq(pool.totalAssets(), FIRST_DEPOSIT);
        assertEq(underlying.balanceOf(address(pool)), FIRST_DEPOSIT);
    }

    /**
     * @notice Depósitos posteriores: shares = assets * totalSupply / totalAssets.
     */
    function test_deposit_subsequent_isProRata() public {
        _deposit(lp, FIRST_DEPOSIT);

        uint256 supplyBefore = pool.totalSupply();
        uint256 assetsBefore = pool.totalAssets();
        uint256 expectedShares = (SECOND_DEPOSIT * supplyBefore) / assetsBefore;

        vm.startPrank(lp2);
        underlying.approve(address(pool), SECOND_DEPOSIT);
        uint256 shares = pool.deposit(SECOND_DEPOSIT, lp2, 0);
        vm.stopPrank();

        assertEq(shares, expectedShares);
        assertEq(pool.balanceOf(lp2), expectedShares);
        assertEq(pool.totalAssets(), assetsBefore + SECOND_DEPOSIT);
    }

    /**
     * @notice Cada depósito extiende `lockUntil` del receptor.
     */
    function test_deposit_setsLockUntil() public {
        uint256 ts = block.timestamp;

        vm.startPrank(lp);
        underlying.approve(address(pool), FIRST_DEPOSIT);
        pool.deposit(FIRST_DEPOSIT, lp, 0);
        vm.stopPrank();

        assertEq(pool.lockUntil(lp), ts + LOCK_DURATION);
    }

    /**
     * @notice LP shares van a `to`, no necesariamente al caller.
     */
    function test_deposit_mintsToRecipientNotCaller() public {
        vm.startPrank(lp);
        underlying.approve(address(pool), FIRST_DEPOSIT);
        uint256 shares = pool.deposit(FIRST_DEPOSIT, recipient, 0);
        vm.stopPrank();

        assertEq(pool.balanceOf(recipient), shares);
        assertEq(pool.balanceOf(lp), 0);
    }

    /**
     * @notice `previewDeposit` coincide con el resultado de `deposit`.
     */
    function test_previewDeposit_matchesDeposit() public {
        uint256 preview = pool.previewDeposit(FIRST_DEPOSIT);

        vm.startPrank(lp);
        underlying.approve(address(pool), FIRST_DEPOSIT);
        uint256 shares = pool.deposit(FIRST_DEPOSIT, lp, 0);
        vm.stopPrank();

        assertEq(preview, shares);
        assertEq(preview, FIRST_DEPOSIT - MINIMUM_LIQUIDITY);
    }

    // -------------------------------------------------------------------------
    // deposit — reverts
    // -------------------------------------------------------------------------

    /**
     * @notice `assets == 0` revierte `ZeroLiquidity`.
     */
    function test_deposit_revertsZeroLiquidity_whenAssetsZero() public {
        vm.prank(lp);
        vm.expectRevert(ILiquidityPool.ZeroLiquidity.selector);
        pool.deposit(0, lp, 0);
    }

    /**
     * @notice Primer depósito ≤ MINIMUM_LIQUIDITY revierte `ZeroLiquidity`.
     */
    function test_deposit_revertsZeroLiquidity_whenFirstDepositTooSmall() public {
        vm.startPrank(lp);
        underlying.approve(address(pool), MINIMUM_LIQUIDITY);
        vm.expectRevert(ILiquidityPool.ZeroLiquidity.selector);
        pool.deposit(MINIMUM_LIQUIDITY, lp, 0);
        vm.stopPrank();
    }

    /**
     * @notice `minSharesOut` mayor que shares calculadas revierte `SlippageExceeded`.
     */
    function test_deposit_revertsSlippageExceeded_whenMinSharesTooHigh() public {
        uint256 expectedShares = FIRST_DEPOSIT - MINIMUM_LIQUIDITY;

        vm.startPrank(lp);
        underlying.approve(address(pool), FIRST_DEPOSIT);
        vm.expectRevert(ILiquidityPool.SlippageExceeded.selector);
        pool.deposit(FIRST_DEPOSIT, lp, expectedShares + 1);
        vm.stopPrank();
    }

    /**
     * @notice `to == address(0)` revierte `ZeroAddress`.
     */
    function test_deposit_revertsZeroAddress_whenToZero() public {
        vm.startPrank(lp);
        underlying.approve(address(pool), FIRST_DEPOSIT);
        vm.expectRevert(ILiquidityPool.ZeroAddress.selector);
        pool.deposit(FIRST_DEPOSIT, address(0), 0);
        vm.stopPrank();
    }

    // -------------------------------------------------------------------------
    // withdraw — caminos felices (fase 4)
    // -------------------------------------------------------------------------

    /**
     * @notice Retiro pro-rata tras expirar lock time.
     */
    function test_withdraw_returnsProRataAssets() public {
        _deposit(lp, FIRST_DEPOSIT);

        uint256 lpShares = pool.balanceOf(lp);
        uint256 expectedAssets = (lpShares * pool.totalAssets()) / pool.totalSupply();

        vm.warp(pool.lockUntil(lp) + 1);

        vm.startPrank(lp);
        uint256 assetsOut = pool.withdraw(lpShares, lp, 0);
        vm.stopPrank();

        assertEq(assetsOut, expectedAssets);
        assertEq(underlying.balanceOf(lp), 100_000 ether - FIRST_DEPOSIT + expectedAssets);
        assertEq(pool.balanceOf(lp), 0);
        assertEq(pool.totalAssets(), FIRST_DEPOSIT - expectedAssets);
    }

    /**
     * @notice `withdraw` emite evento con sender, receiver y owner.
     */
    function test_withdraw_emitsWithdraw() public {
        _deposit(lp, FIRST_DEPOSIT);
        uint256 lpShares = pool.balanceOf(lp);
        uint256 expectedAssets = (lpShares * pool.totalAssets()) / pool.totalSupply();

        vm.warp(pool.lockUntil(lp) + 1);

        vm.startPrank(lp);
        vm.expectEmit(true, true, true, true, address(pool));
        emit ILiquidityPool.Withdraw(lp, lp, lp, expectedAssets, lpShares);
        pool.withdraw(lpShares, lp, 0);
        vm.stopPrank();
    }

    /**
     * @notice `previewWithdraw` coincide con el resultado de `withdraw`.
     */
    function test_previewWithdraw_matchesWithdraw() public {
        _deposit(lp, FIRST_DEPOSIT);
        uint256 lpShares = pool.balanceOf(lp);

        vm.warp(pool.lockUntil(lp) + 1);

        uint256 preview = pool.previewWithdraw(lpShares);

        vm.startPrank(lp);
        uint256 assetsOut = pool.withdraw(lpShares, lp, 0);
        vm.stopPrank();

        assertEq(preview, assetsOut);
        assertGt(assetsOut, 0);
    }

    // -------------------------------------------------------------------------
    // withdraw — reverts
    // -------------------------------------------------------------------------

    /**
     * @notice Retiro antes de `lockUntil` revierte `LockTimeNotExpired`.
     */
    function test_withdraw_revertsLockTimeNotExpired_beforeUnlock() public {
        _deposit(lp, FIRST_DEPOSIT);
        uint256 lpShares = pool.balanceOf(lp);

        vm.prank(lp);
        vm.expectRevert(ILiquidityPool.LockTimeNotExpired.selector);
        pool.withdraw(lpShares, lp, 0);
    }

    /**
     * @notice `shares == 0` revierte `ZeroLiquidity`.
     */
    function test_withdraw_revertsZeroLiquidity_whenSharesZero() public {
        vm.prank(lp);
        vm.expectRevert(ILiquidityPool.ZeroLiquidity.selector);
        pool.withdraw(0, lp, 0);
    }

    /**
     * @notice `minAssetsOut` demasiado alto revierte `SlippageExceeded`.
     */
    function test_withdraw_revertsSlippageExceeded_whenMinAssetsTooHigh() public {
        _deposit(lp, FIRST_DEPOSIT);
        uint256 lpShares = pool.balanceOf(lp);
        uint256 expectedAssets = (lpShares * pool.totalAssets()) / pool.totalSupply();

        vm.warp(pool.lockUntil(lp) + 1);

        vm.startPrank(lp);
        vm.expectRevert(ILiquidityPool.SlippageExceeded.selector);
        pool.withdraw(lpShares, lp, expectedAssets + 1);
        vm.stopPrank();
    }

    /**
     * @notice `to == address(0)` revierte `ZeroAddress`.
     */
    function test_withdraw_revertsZeroAddress_whenToZero() public {
        _deposit(lp, FIRST_DEPOSIT);
        uint256 lpShares = pool.balanceOf(lp);

        vm.warp(pool.lockUntil(lp) + 1);

        vm.startPrank(lp);
        vm.expectRevert(ILiquidityPool.ZeroAddress.selector);
        pool.withdraw(lpShares, address(0), 0);
        vm.stopPrank();
    }

    // -------------------------------------------------------------------------
    // fee accrual — fase 5
    // -------------------------------------------------------------------------

    uint256 internal constant FEE_AMOUNT = 100 ether;

    /**
     * @notice `accrueFees` incrementa share price y `accFeePerShare` para LPs existentes.
     */
    function test_accrueFees_increasesSharePriceForExistingLp() public {
        _deposit(lp, FIRST_DEPOSIT);

        uint256 shares = pool.balanceOf(lp);
        uint256 assetsBefore = pool.previewWithdraw(shares);

        _accrueFees(FEE_AMOUNT);

        uint256 assetsAfter = pool.previewWithdraw(shares);
        assertGt(assetsAfter, assetsBefore);
        assertEq(pool.totalAssets(), FIRST_DEPOSIT + FEE_AMOUNT);
    }

    /**
     * @notice `accFeePerShare` sigue fórmula UD60x18: fee * 1e18 / totalSupply.
     */
    function test_accrueFees_updatesAccFeePerShare() public {
        _deposit(lp, FIRST_DEPOSIT);

        _accrueFees(FEE_AMOUNT);

        uint256 expectedAcc = (FEE_AMOUNT * 1e18) / pool.totalSupply();
        assertEq(pool.accFeePerShare(), expectedAcc);
    }

    /**
     * @notice Emite `FeesAccrued` con fee delta y acumulador actualizado.
     */
    function test_accrueFees_emitsFeesAccrued() public {
        _deposit(lp, FIRST_DEPOSIT);

        uint256 expectedAcc = (FEE_AMOUNT * 1e18) / pool.totalSupply();

        underlying.mint(address(this), FEE_AMOUNT);

        vm.expectEmit(true, true, true, true, address(underlying));
        emit IERC20.Transfer(address(this), address(pool), FEE_AMOUNT);
        underlying.transfer(address(pool), FEE_AMOUNT);

        vm.expectEmit(false, false, false, true, address(pool));
        emit ILiquidityPool.FeesAccrued(FEE_AMOUNT, expectedAcc);
        pool.accrueFees(0);
    }

    /**
     * @notice Donación directa + `accrueFees(0)` sincroniza y distribuye fees.
     */
    function test_accrueFees_syncsDirectDonation() public {
        _deposit(lp, FIRST_DEPOSIT);

        underlying.mint(address(this), FEE_AMOUNT);
        underlying.transfer(address(pool), FEE_AMOUNT);

        uint256 shares = pool.balanceOf(lp);
        uint256 assetsBefore = pool.previewWithdraw(shares);

        pool.accrueFees(0);

        assertEq(pool.totalAssets(), FIRST_DEPOSIT + FEE_AMOUNT);
        assertGt(pool.previewWithdraw(shares), assetsBefore);
    }

    /**
     * @notice Fees antes del primer LP quedan en reserva (`totalAssets` ↑, acc sin cambio).
     */
    function test_accrueFees_beforeFirstDeposit_pendingInReserve() public {
        _accrueFees(FEE_AMOUNT);

        assertEq(pool.totalAssets(), FEE_AMOUNT);
        assertEq(pool.accFeePerShare(), 0);
        assertEq(pool.totalSupply(), 0);
    }

    /**
     * @notice Primer LP posterior a fees pre-deposito se beneficia del share price elevado.
     */
    function test_accrueFees_preDepositFeesBenefitFirstLp() public {
        _accrueFees(FEE_AMOUNT);

        _deposit(lp, FIRST_DEPOSIT);

        uint256 shares = pool.balanceOf(lp);
        uint256 withdrawable = pool.previewWithdraw(shares);
        assertGt(withdrawable, FIRST_DEPOSIT - MINIMUM_LIQUIDITY);
    }

    /**
     * @notice LP existente captura fees acumulados antes de que entre un segundo LP.
     */
    function test_accrueFees_existingLpKeepsFeeAdvantageOverNewLp() public {
        _deposit(lp, FIRST_DEPOSIT);
        _accrueFees(FEE_AMOUNT);

        uint256 lp1SharesBefore = pool.balanceOf(lp);
        uint256 lp1AssetsBefore = pool.previewWithdraw(lp1SharesBefore);

        _deposit(lp2, SECOND_DEPOSIT);

        uint256 lp1AssetsAfter = pool.previewWithdraw(lp1SharesBefore);
        assertEq(lp1AssetsAfter, lp1AssetsBefore);
        assertGt(lp1AssetsAfter, pool.previewWithdraw(pool.balanceOf(lp2)));
    }

    /**
     * @notice `accrueFees(0)` sin donación no modifica estado ni emite evento.
     */
    function test_accrueFees_zeroAmountNoOpWhenSynced() public {
        _deposit(lp, FIRST_DEPOSIT);

        uint256 assetsBefore = pool.totalAssets();
        uint256 accBefore = pool.accFeePerShare();

        pool.accrueFees(0);

        assertEq(pool.totalAssets(), assetsBefore);
        assertEq(pool.accFeePerShare(), accBefore);
    }

    // -------------------------------------------------------------------------
    // Multi-user
    // -------------------------------------------------------------------------

    /**
     * @notice Segundo LP recibe shares pro-rata al share price vigente.
     */
    function test_multiUser_secondDepositorGetsProRataShares() public {
        _deposit(lp, FIRST_DEPOSIT);

        uint256 supplyBefore = pool.totalSupply();
        uint256 assetsBefore = pool.totalAssets();

        _deposit(lp2, SECOND_DEPOSIT);

        uint256 expectedLp2Shares = (SECOND_DEPOSIT * supplyBefore) / assetsBefore;
        assertEq(pool.balanceOf(lp2), expectedLp2Shares);
        assertGt(pool.balanceOf(lp), 0);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * @dev Depósito auxiliar.
     */
    function _deposit(address user, uint256 assets) internal {
        vm.startPrank(user);
        underlying.approve(address(pool), assets);
        pool.deposit(assets, user, 0);
        vm.stopPrank();
    }

    /**
     * @dev Acumula fees desde el contrato de test hacia el pool.
     */
    function _accrueFees(uint256 amount) internal {
        underlying.mint(address(this), amount);
        underlying.approve(address(pool), amount);
        pool.accrueFees(amount);
    }
}
