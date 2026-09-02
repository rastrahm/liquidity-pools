// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {FixedPointMath} from "../src/libraries/FixedPointMath.sol";

/**
 * @title FixedPointMathTest
 * @notice Tests unitarios de conversión shares/assets y fee accrual UD60x18.
 */
contract FixedPointMathTest is Test {
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant SCALE = 1e18;

    function test_mulDiv_basic() public pure {
        assertEq(FixedPointMath.mulDiv(100, 200, 50), 400);
    }

    function test_mulDiv_zeroDenominatorReturnsZero() public pure {
        assertEq(FixedPointMath.mulDiv(100, 200, 0), 0);
    }

    function test_mulDiv_revertsOnOverflow() public {
        vm.expectRevert(FixedPointMath.MulDivOverflow.selector);
        this.exposedMulDiv(type(uint256).max, 2, 1);
    }

    function exposedMulDiv(uint256 x, uint256 y, uint256 denominator) external pure returns (uint256) {
        return FixedPointMath.mulDiv(x, y, denominator);
    }

    function test_convertToShares_firstDeposit() public pure {
        uint256 assets = 1000 ether;
        uint256 shares = FixedPointMath.convertToShares(assets, 0, 0, MINIMUM_LIQUIDITY);
        assertEq(shares, assets - MINIMUM_LIQUIDITY);
    }

    function test_convertToShares_firstDepositTooSmallReturnsZero() public pure {
        assertEq(FixedPointMath.convertToShares(MINIMUM_LIQUIDITY, 0, 0, MINIMUM_LIQUIDITY), 0);
        assertEq(FixedPointMath.convertToShares(500, 0, 0, MINIMUM_LIQUIDITY), 0);
    }

    function test_convertToShares_subsequentProRata() public pure {
        uint256 supply = 1000 ether;
        uint256 assets = 2000 ether;
        uint256 deposit = 500 ether;

        uint256 shares = FixedPointMath.convertToShares(deposit, supply, assets, MINIMUM_LIQUIDITY);
        assertEq(shares, (deposit * supply) / assets);
    }

    function test_convertToShares_zeroAssetsReturnsZero() public pure {
        assertEq(FixedPointMath.convertToShares(0, 1000, 2000, MINIMUM_LIQUIDITY), 0);
    }

    function test_convertToAssets_proRata() public pure {
        uint256 supply = 1000 ether + MINIMUM_LIQUIDITY;
        uint256 assets = 1000 ether;
        uint256 shares = 250 ether;

        uint256 out = FixedPointMath.convertToAssets(shares, supply, assets);
        assertEq(out, (shares * assets) / supply);
    }

    function test_convertToAssets_zeroSharesReturnsZero() public pure {
        assertEq(FixedPointMath.convertToAssets(0, 1000, 2000), 0);
    }

    function test_accrueFeePerShare_increasesAccumulated() public pure {
        uint256 supply = 1000 ether;
        uint256 fee = 10 ether;
        uint256 acc = FixedPointMath.accrueFeePerShare(fee, supply, 0);
        assertEq(acc, (fee * SCALE) / supply);
    }

    function test_accrueFeePerShare_zeroFeeReturnsCurrent() public pure {
        assertEq(FixedPointMath.accrueFeePerShare(0, 1000, 42), 42);
    }

    function test_accrueFeePerShare_zeroSupplyReturnsCurrent() public pure {
        assertEq(FixedPointMath.accrueFeePerShare(10 ether, 0, 42), 42);
    }

    function test_roundTrip_depositWithdrawApproximation() public pure {
        uint256 totalAssets = 1000 ether;
        uint256 totalSupply = totalAssets - MINIMUM_LIQUIDITY + MINIMUM_LIQUIDITY;
        uint256 deposit = 100 ether;

        uint256 shares = FixedPointMath.convertToShares(deposit, totalSupply, totalAssets, MINIMUM_LIQUIDITY);
        uint256 assetsOut = FixedPointMath.convertToAssets(shares, totalSupply + shares, totalAssets + deposit);

        assertLe(assetsOut, deposit);
        assertGt(assetsOut, deposit - 1);
    }
}
