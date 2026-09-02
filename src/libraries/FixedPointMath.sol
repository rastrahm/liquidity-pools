// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title FixedPointMath
 * @notice Matemática de punto fijo UD60x18 para conversión shares ↔ assets y fee accrual.
 * @dev Escala `1e18` para `accFeePerShare`. `mulDiv` evita overflow intermedio en productos grandes.
 */
library FixedPointMath {
    /// @notice Factor de escala UD60x18 (1e18).
    uint256 internal constant SCALE = 1e18;

    /// @notice Producto `x * y` desborda uint256.
    error MulDivOverflow();

    /**
     * @notice Calcula `(x * y) / denominator` con chequeo de overflow.
     * @param x Numerador multiplicando.
     * @param y Numerador multiplicando.
     * @param denominator Divisor (0 → retorna 0).
     * @return result Cociente redondeado hacia abajo.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        if (denominator == 0) return 0;

        unchecked {
            uint256 product = x * y;
            if (x != 0 && product / x != y) revert MulDivOverflow();
            return product / denominator;
        }
    }

    /**
     * @notice Convierte `assets` a LP shares según supply y reservas actuales.
     * @dev Primer depósito: `shares = assets - minimumLiquidity` si `assets > minimumLiquidity`.
     * @param assets Underlying a depositar.
     * @param totalSupply_ LP supply actual.
     * @param totalAssets_ Reservas contabilizadas.
     * @param minimumLiquidity Tranche mínima bloqueada en el primer mint.
     * @return shares LP shares estimadas (0 si depósito inválido).
     */
    function convertToShares(uint256 assets, uint256 totalSupply_, uint256 totalAssets_, uint256 minimumLiquidity)
        internal
        pure
        returns (uint256 shares)
    {
        if (assets == 0) return 0;

        if (totalSupply_ == 0) {
            if (assets <= minimumLiquidity) return 0;
            return assets - minimumLiquidity;
        }

        if (totalAssets_ == 0) return 0;

        return mulDiv(assets, totalSupply_, totalAssets_);
    }

    /**
     * @notice Convierte LP `shares` a underlying retirable.
     * @param shares LP shares a quemar.
     * @param totalSupply_ LP supply actual.
     * @param totalAssets_ Reservas contabilizadas.
     * @return assets Underlying estimado (0 si shares o supply es 0).
     */
    function convertToAssets(uint256 shares, uint256 totalSupply_, uint256 totalAssets_)
        internal
        pure
        returns (uint256 assets)
    {
        if (shares == 0 || totalSupply_ == 0) return 0;
        return mulDiv(shares, totalAssets_, totalSupply_);
    }

    /**
     * @notice Incrementa el acumulador de fees por share (UD60x18).
     * @param feeAmount Fees nuevos a distribuir.
     * @param totalSupply_ LP supply actual.
     * @param currentAccFeePerShare Acumulador vigente.
     * @return newAccFeePerShare Acumulador actualizado.
     */
    function accrueFeePerShare(uint256 feeAmount, uint256 totalSupply_, uint256 currentAccFeePerShare)
        internal
        pure
        returns (uint256 newAccFeePerShare)
    {
        if (feeAmount == 0 || totalSupply_ == 0) return currentAccFeePerShare;
        return currentAccFeePerShare + mulDiv(feeAmount, SCALE, totalSupply_);
    }
}
