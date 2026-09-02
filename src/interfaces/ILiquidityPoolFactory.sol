// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ILiquidityPoolFactory
 * @notice Crea y registra pools de liquidez únicos por token subyacente.
 * @dev Selectores de errores/eventos para tests Foundry (`vm.expectRevert` / `vm.expectEmit`).
 */
interface ILiquidityPoolFactory {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice `underlying` es `address(0)`.
    error ZeroAddress();

    /// @notice Ya existe un pool para ese underlying.
    error PoolExists();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /**
     * @notice Pool creado.
     * @param underlying Token subyacente del pool.
     * @param pool Dirección del pool desplegado.
     * @param allPoolsLength Longitud de `allPools` tras el alta.
     */
    event PoolCreated(address indexed underlying, address indexed pool, uint256 allPoolsLength);

    // -------------------------------------------------------------------------
    // Views
    // -------------------------------------------------------------------------

    /**
     * @notice Duración de lock time propagada a pools nuevos (segundos).
     * @return Segundos de lock por depósito.
     */
    function lockDuration() external view returns (uint256);

    /**
     * @notice Dirección del pool para `underlying`, o cero si no existe.
     * @param underlying Token subyacente.
     * @return pool Dirección del pool.
     */
    function getPool(address underlying) external view returns (address pool);

    /**
     * @notice Pool en el índice `index` de `allPools`.
     * @param index Índice 0-based.
     * @return pool Dirección del pool.
     */
    function allPools(uint256 index) external view returns (address pool);

    /**
     * @notice Número de pools creados.
     * @return length Cantidad de pools.
     */
    function allPoolsLength() external view returns (uint256 length);

    // -------------------------------------------------------------------------
    // Mutating
    // -------------------------------------------------------------------------

    /**
     * @notice Despliega un pool nuevo para `underlying`.
     * @param underlying Token ERC-20 subyacente.
     * @return pool Dirección del pool creado.
     */
    function createPool(address underlying) external returns (address pool);
}
