// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ILiquidityPoolFactory} from "./interfaces/ILiquidityPoolFactory.sol";
import {LiquidityPool} from "./LiquidityPool.sol";

/**
 * @title LiquidityPoolFactory
 * @notice Despliega y registra pools de liquidez únicos por token subyacente.
 * @dev Propaga `lockDuration` a cada pool nuevo. Un underlying → un pool.
 */
contract LiquidityPoolFactory is ILiquidityPoolFactory {
    /// @inheritdoc ILiquidityPoolFactory
    uint256 public immutable lockDuration;

    /// @inheritdoc ILiquidityPoolFactory
    mapping(address => address) public getPool;

    /// @inheritdoc ILiquidityPoolFactory
    address[] public allPools;

    /**
     * @notice Configura la factory con la duración de lock de los pools.
     * @param lockDuration_ Segundos de lock tras cada depósito en pools nuevos.
     */
    constructor(uint256 lockDuration_) {
        lockDuration = lockDuration_;
    }

    /// @inheritdoc ILiquidityPoolFactory
    function allPoolsLength() external view returns (uint256 length) {
        return allPools.length;
    }

    /**
     * @inheritdoc ILiquidityPoolFactory
     * @dev Revierte si `underlying` es cero o ya existe un pool registrado.
     */
    function createPool(address underlying) external returns (address pool) {
        if (underlying == address(0)) revert ZeroAddress();
        if (getPool[underlying] != address(0)) revert PoolExists();

        pool = address(
            new LiquidityPool(underlying, lockDuration, "Liquidity Pool LP", "LPLP")
        );

        getPool[underlying] = pool;
        allPools.push(pool);

        emit PoolCreated(underlying, pool, allPools.length);
    }
}
