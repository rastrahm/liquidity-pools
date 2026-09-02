// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ILiquidityPool} from "../src/interfaces/ILiquidityPool.sol";
import {ILiquidityPoolFactory} from "../src/interfaces/ILiquidityPoolFactory.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/**
 * @title ScaffoldTest
 * @notice Verifica que el scaffold de fase 0 compila y el mock ERC-20 funciona.
 */
contract ScaffoldTest is Test {
    /**
     * @notice Confirma que MockERC20 acuña y transfiere correctamente.
     */
    function test_MockERC20_mintAndTransfer() public {
        MockERC20 token = new MockERC20("Pool Underlying", "UND");
        token.mint(address(this), 1_000 ether);

        assertEq(token.balanceOf(address(this)), 1_000 ether);

        address recipient = makeAddr("recipient");
        assertTrue(token.transfer(recipient, 100 ether));
        assertEq(token.balanceOf(recipient), 100 ether);
    }

    /**
     * @notice Confirma selectores de errores custom del pool (para vm.expectRevert en fase 1+).
     */
    function test_ILiquidityPool_customErrorSelectors() public pure {
        assertEq(ILiquidityPool.ZeroLiquidity.selector, bytes4(keccak256("ZeroLiquidity()")));
        assertEq(ILiquidityPool.SlippageExceeded.selector, bytes4(keccak256("SlippageExceeded()")));
        assertEq(ILiquidityPool.InvalidRatio.selector, bytes4(keccak256("InvalidRatio()")));
        assertEq(ILiquidityPool.LockTimeNotExpired.selector, bytes4(keccak256("LockTimeNotExpired()")));
    }

    /**
     * @notice Confirma selectores de errores custom de la factory.
     */
    function test_ILiquidityPoolFactory_customErrorSelectors() public pure {
        assertEq(ILiquidityPoolFactory.ZeroAddress.selector, bytes4(keccak256("ZeroAddress()")));
        assertEq(ILiquidityPoolFactory.PoolExists.selector, bytes4(keccak256("PoolExists()")));
    }
}
