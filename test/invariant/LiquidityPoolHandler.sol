// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {LiquidityPool} from "../../src/LiquidityPool.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

/**
 * @title LiquidityPoolHandler
 * @notice Handler para invariantes: deposit / withdraw / accrueFees / donate / warp.
 */
contract LiquidityPoolHandler is Test {
    LiquidityPool public immutable pool;
    MockERC20 public immutable underlying;

    address[] public actorsList;

    /// @notice Suma ghost de assets depositados vía handler (neto de withdraws del handler).
    uint256 public ghostDeposited;
    /// @notice Suma ghost de fees/donaciones sincronizadas vía handler.
    uint256 public ghostFees;

    constructor(LiquidityPool pool_, MockERC20 underlying_) {
        pool = pool_;
        underlying = underlying_;

        actorsList.push(makeAddr("actor0"));
        actorsList.push(makeAddr("actor1"));
        actorsList.push(makeAddr("actor2"));

        for (uint256 i = 0; i < actorsList.length; ++i) {
            underlying.mint(actorsList[i], 1_000_000 ether);
        }
    }

    function deposit(uint256 actorSeed, uint256 assets) external {
        address actor = actorsList[actorSeed % actorsList.length];
        assets = bound(assets, 1 ether, 5_000 ether);

        uint256 bal = underlying.balanceOf(actor);
        if (bal < assets) {
            underlying.mint(actor, assets - bal);
        }

        vm.startPrank(actor);
        underlying.approve(address(pool), assets);
        try pool.deposit(assets, actor, 0) returns (uint256) {
            ghostDeposited += assets;
        } catch {}
        vm.stopPrank();
    }

    function withdraw(uint256 actorSeed, uint256 sharesSeed) external {
        address actor = actorsList[actorSeed % actorsList.length];
        uint256 bal = pool.balanceOf(actor);
        if (bal == 0) return;

        if (block.timestamp < pool.lockUntil(actor)) {
            vm.warp(pool.lockUntil(actor) + 1);
        }

        uint256 shares = bound(sharesSeed, 1, bal);
        uint256 assetsBefore = pool.totalAssets();

        vm.startPrank(actor);
        try pool.withdraw(shares, actor, 0) returns (uint256 assetsOut) {
            if (ghostDeposited >= assetsOut) {
                ghostDeposited -= assetsOut;
            } else {
                ghostDeposited = 0;
            }
            assertLe(pool.totalAssets(), assetsBefore);
            assertEq(pool.totalAssets(), assetsBefore - assetsOut);
        } catch {}
        vm.stopPrank();
    }

    function accrueFees(uint256 feeAmount) external {
        feeAmount = bound(feeAmount, 1, 1_000 ether);
        underlying.mint(address(this), feeAmount);
        underlying.approve(address(pool), feeAmount);
        pool.accrueFees(feeAmount);
        ghostFees += feeAmount;
    }

    function donate(uint256 amount) external {
        amount = bound(amount, 1, 500 ether);
        underlying.mint(address(this), amount);
        underlying.transfer(address(pool), amount);
        // Sync explícito para contabilizar donación en totalAssets.
        pool.accrueFees(0);
        ghostFees += amount;
    }

    function warpTime(uint256 secs) external {
        secs = bound(secs, 1, 7 days);
        vm.warp(block.timestamp + secs);
    }
}
