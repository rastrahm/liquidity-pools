// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {ILiquidityPool} from "../src/interfaces/ILiquidityPool.sol";
import {ILiquidityPoolFactory} from "../src/interfaces/ILiquidityPoolFactory.sol";
import {LiquidityPoolFactory} from "../src/LiquidityPoolFactory.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/**
 * @title LiquidityPoolFactoryTest
 * @notice Fase 6: creación de pools, unicidad por underlying y registro.
 */
contract LiquidityPoolFactoryTest is Test {
    uint256 internal constant LOCK_DURATION = 1 days;

    LiquidityPoolFactory internal factory;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    function setUp() public {
        factory = new LiquidityPoolFactory(LOCK_DURATION);
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
    }

    /**
     * @notice Constructor fija `lockDuration` y el registro arranca vacío.
     */
    function test_constructor_setsLockDurationAndEmptyRegistry() public view {
        assertEq(factory.lockDuration(), LOCK_DURATION);
        assertEq(factory.allPoolsLength(), 0);
        assertEq(factory.getPool(address(tokenA)), address(0));
    }

    /**
     * @notice `createPool` despliega un pool, lo registra y emite `PoolCreated`.
     */
    function test_createPool_registersAndEmits() public {
        vm.expectEmit(true, false, false, true, address(factory));
        emit ILiquidityPoolFactory.PoolCreated(address(tokenA), address(0), 1);

        address pool = factory.createPool(address(tokenA));

        assertTrue(pool != address(0));
        assertEq(factory.getPool(address(tokenA)), pool);
        assertEq(factory.allPools(0), pool);
        assertEq(factory.allPoolsLength(), 1);

        assertEq(ILiquidityPool(pool).underlying(), address(tokenA));
        assertEq(ILiquidityPool(pool).lockDuration(), LOCK_DURATION);
        assertEq(ILiquidityPool(pool).MINIMUM_LIQUIDITY(), 1000);
    }

    /**
     * @notice Dos underlyings distintos producen pools distintos.
     */
    function test_createPool_multipleUnderlyings() public {
        address poolA = factory.createPool(address(tokenA));
        address poolB = factory.createPool(address(tokenB));

        assertTrue(poolA != poolB);
        assertEq(factory.getPool(address(tokenA)), poolA);
        assertEq(factory.getPool(address(tokenB)), poolB);
        assertEq(factory.allPoolsLength(), 2);
        assertEq(factory.allPools(0), poolA);
        assertEq(factory.allPools(1), poolB);
    }

    /**
     * @notice Segundo `createPool` del mismo underlying revierte `PoolExists`.
     */
    function test_createPool_revertsPoolExists() public {
        factory.createPool(address(tokenA));

        vm.expectRevert(ILiquidityPoolFactory.PoolExists.selector);
        factory.createPool(address(tokenA));
    }

    /**
     * @notice Underlying cero revierte `ZeroAddress`.
     */
    function test_createPool_revertsZeroAddress() public {
        vm.expectRevert(ILiquidityPoolFactory.ZeroAddress.selector);
        factory.createPool(address(0));
    }

    /**
     * @notice El pool creado acepta depósitos (integración mínima factory → pool).
     */
    function test_createPool_poolAcceptsDeposit() public {
        address pool = factory.createPool(address(tokenA));
        address lp = makeAddr("lp");

        tokenA.mint(lp, 1_000 ether);

        vm.startPrank(lp);
        tokenA.approve(pool, 1_000 ether);
        uint256 shares = ILiquidityPool(pool).deposit(1_000 ether, lp, 0);
        vm.stopPrank();

        assertEq(shares, 1_000 ether - 1000);
        assertEq(ILiquidityPool(pool).totalAssets(), 1_000 ether);
    }
}
