// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ILiquidityPool
 * @notice API del pool de liquidez tokenizado con distribución proporcional de fees.
 * @dev Selectores de errores/eventos para tests Foundry (`vm.expectRevert` / `vm.expectEmit`).
 *      El pool también emite LP shares como ERC-20 interno; esa superficie vive en el contrato.
 */
interface ILiquidityPool {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Cantidad de liquidez o shares resultantes es cero.
    error ZeroLiquidity();

    /// @notice Shares o assets recibidos son menores al mínimo esperado.
    error SlippageExceeded();

    /// @notice Ratio de depósito no cumple la restricción del pool.
    error InvalidRatio();

    /// @notice Retiro solicitado antes de que expire el lock time del LP.
    error LockTimeNotExpired();

    /// @notice Dirección cero no permitida.
    error ZeroAddress();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /**
     * @notice Depósito de underlying acuñando LP shares.
     * @param sender Caller de `deposit`.
     * @param owner Receptor de las LP shares (`to`).
     * @param assets Cantidad de underlying depositada.
     * @param shares LP shares acuñadas.
     */
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    /**
     * @notice Retiro quemando LP shares a cambio de underlying.
     * @param sender Caller de `withdraw`.
     * @param receiver Receptor del underlying (`to`).
     * @param owner Dueño de las shares quemadas.
     * @param assets Cantidad de underlying transferida.
     * @param shares LP shares quemadas.
     */
    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    /**
     * @notice Fees registrados en el pool incrementando el share price.
     * @param feeAmount Cantidad de fees acumulada.
     * @param accFeePerShare Nuevo acumulador UD60x18 por share.
     */
    event FeesAccrued(uint256 feeAmount, uint256 accFeePerShare);

    // -------------------------------------------------------------------------
    // Views
    // -------------------------------------------------------------------------

    /**
     * @notice Token ERC-20 subyacente custodiado por el pool.
     * @return Dirección del underlying.
     */
    function underlying() external view returns (address);

    /**
     * @notice Duración del lock time aplicada en cada depósito (segundos).
     * @return Segundos hasta desbloqueo tras depositar.
     */
    function lockDuration() external view returns (uint256);

    /**
     * @notice Reservas totales contabilizadas (incluye fees acumulados).
     * @return Assets totales del pool.
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Acumulador de fees por share en escala UD60x18.
     * @return Acumulador actual.
     */
    function accFeePerShare() external view returns (uint256);

    /**
     * @notice Liquidez mínima bloqueada en el primer depósito (`address(0)`).
     * @return Cantidad constante (1000 wei).
     */
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    /**
     * @notice Timestamp Unix a partir del cual el LP puede retirar.
     * @param account Dirección del LP.
     * @return Timestamp de desbloqueo.
     */
    function lockUntil(address account) external view returns (uint256);

    /**
     * @notice Estima LP shares por un depósito de `assets` (sin modificar estado).
     * @param assets Cantidad de underlying a depositar.
     * @return shares Shares estimadas.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Estima underlying retirable por quema de `shares` (sin modificar estado).
     * @param shares Cantidad de LP shares a quemar.
     * @return assets Underlying estimado.
     */
    function previewWithdraw(uint256 shares) external view returns (uint256 assets);

    // -------------------------------------------------------------------------
    // Mutating
    // -------------------------------------------------------------------------

    /**
     * @notice Deposita `assets` de underlying y acuña LP shares a `to`.
     * @dev CEI: mint antes de `transferFrom`. Primer depósito quema MINIMUM_LIQUIDITY a `address(0)`.
     * @param assets Cantidad de underlying a depositar.
     * @param to Receptor de las LP shares.
     * @param minSharesOut Mínimo de shares aceptables (slippage).
     * @return shares LP shares acuñadas.
     */
    function deposit(uint256 assets, address to, uint256 minSharesOut) external returns (uint256 shares);

    /**
     * @notice Quema `shares` LP del caller y transfiere underlying a `to`.
     * @dev CEI: burn antes de `transfer`. Requiere `lockUntil[msg.sender]` expirado.
     * @param shares LP shares a quemar.
     * @param to Receptor del underlying.
     * @param minAssetsOut Mínimo de underlying aceptable (slippage).
     * @return assets Underlying transferido.
     */
    function withdraw(uint256 shares, address to, uint256 minAssetsOut) external returns (uint256 assets);

    /**
     * @notice Sincroniza y registra fees explícitos incrementando `accFeePerShare`.
     * @param amount Cantidad de fees a acumular (0 = solo sync de balance).
     */
    function accrueFees(uint256 amount) external;
}
