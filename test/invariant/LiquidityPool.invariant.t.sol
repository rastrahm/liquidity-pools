// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {LiquidityPool} from "../../src/LiquidityPool.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {LiquidityPoolHandler} from "./LiquidityPoolHandler.sol";

/**
 * @title LiquidityPoolInvariantTest
 * @notice Fase 7: totalAssets ↔ balance; MINIMUM_LIQUIDITY locked; solvencia (SWC-101/123).
 */
contract LiquidityPoolInvariantTest is StdInvariant, Test {
    uint256 internal constant LOCK_DURATION = 1 days;
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    MockERC20 internal underlying;
    LiquidityPool internal pool;
    LiquidityPoolHandler internal handler;

    function setUp() public {
        underlying = new MockERC20("Underlying", "UND");
        pool = new LiquidityPool(address(underlying), LOCK_DURATION, "LP", "LP");
        handler = new LiquidityPoolHandler(pool, underlying);

        // Seed: primer depósito para fijar MINIMUM_LIQUIDITY.
        address actor0 = handler.actorsList(0);
        vm.startPrank(actor0);
        underlying.approve(address(pool), 1_000 ether);
        pool.deposit(1_000 ether, actor0, 0);
        vm.stopPrank();

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = LiquidityPoolHandler.deposit.selector;
        selectors[1] = LiquidityPoolHandler.withdraw.selector;
        selectors[2] = LiquidityPoolHandler.accrueFees.selector;
        selectors[3] = LiquidityPoolHandler.donate.selector;
        selectors[4] = LiquidityPoolHandler.warpTime.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /// @notice Tras sync (handler siempre sync donaciones), balance ≥ totalAssets.
    function invariant_balanceGeTotalAssets() public view {
        assertGe(underlying.balanceOf(address(pool)), pool.totalAssets());
    }

    /// @notice `totalAssets` no supera el balance del underlying en el pool.
    function invariant_totalAssetsEqBalanceWhenSynced() public view {
        // El handler sincroniza donaciones; deposit/withdraw mantienen paridad.
        assertEq(underlying.balanceOf(address(pool)), pool.totalAssets());
    }

    /// @notice MINIMUM_LIQUIDITY permanece bloqueada en `address(0)` mientras hay supply.
    function invariant_minimumLiquidityLocked() public view {
        if (pool.totalSupply() == 0) return;
        assertEq(pool.balanceOf(address(0)), MINIMUM_LIQUIDITY);
    }

    /// @notice Convertir todo el supply a assets no supera totalAssets (solvencia).
    function invariant_fullConvertToAssetsLeTotalAssets() public view {
        uint256 supply = pool.totalSupply();
        if (supply == 0) return;
        uint256 allAssets = pool.previewWithdraw(supply);
        assertLe(allAssets, pool.totalAssets());
    }

    /// @notice Shares del dead address no son retirables por actores (solo locked).
    function invariant_deadSharesRemain() public view {
        if (pool.totalSupply() == 0) return;
        assertEq(pool.balanceOf(address(0)), MINIMUM_LIQUIDITY);
        assertGe(pool.totalSupply(), MINIMUM_LIQUIDITY);
    }
}
