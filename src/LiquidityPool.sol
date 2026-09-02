// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ILiquidityPool} from "./interfaces/ILiquidityPool.sol";
import {LiquidityPoolERC20} from "./LiquidityPoolERC20.sol";
import {FixedPointMath} from "./libraries/FixedPointMath.sol";

/**
 * @title LiquidityPool
 * @notice Pool de liquidez tokenizado — skeleton fase 2 (previews + validación; mutaciones en fases 3–4).
 * @dev `previewDeposit` / `previewWithdraw` usan `FixedPointMath` UD60x18.
 *      `deposit` / `withdraw` validan slippage pero aún no ejecutan mint/burn (fases 3–4).
 */
contract LiquidityPool is ILiquidityPool, LiquidityPoolERC20, ReentrancyGuard {
    /// @inheritdoc ILiquidityPool
    address public immutable underlying;

    /// @inheritdoc ILiquidityPool
    uint256 public immutable lockDuration;

    /// @inheritdoc ILiquidityPool
    uint256 public totalAssets;

    /// @inheritdoc ILiquidityPool
    uint256 public accFeePerShare;

    /// @inheritdoc ILiquidityPool
    mapping(address => uint256) public lockUntil;

    /**
     * @notice Despliega un pool para un underlying ERC-20.
     * @param underlying_ Token subyacente custodiado.
     * @param lockDuration_ Segundos de lock tras cada depósito.
     * @param name_ Nombre del token LP.
     * @param symbol_ Símbolo del token LP.
     */
    constructor(address underlying_, uint256 lockDuration_, string memory name_, string memory symbol_)
        LiquidityPoolERC20(name_, symbol_)
    {
        if (underlying_ == address(0)) revert ZeroAddress();
        underlying = underlying_;
        lockDuration = lockDuration_;
    }

    /// @inheritdoc ILiquidityPool
    function MINIMUM_LIQUIDITY() external pure returns (uint256) {
        return 1000;
    }

    /// @inheritdoc ILiquidityPool
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        return _convertToShares(assets);
    }

    /// @inheritdoc ILiquidityPool
    function previewWithdraw(uint256 shares) external view returns (uint256 assets) {
        return _convertToAssets(shares);
    }

    /// @inheritdoc ILiquidityPool
    function deposit(uint256 assets, address to, uint256 minSharesOut) external nonReentrant returns (uint256 shares) {
        if (assets == 0) revert ZeroLiquidity();
        if (to == address(0)) revert ZeroAddress();

        shares = _convertToShares(assets);
        if (shares == 0) revert ZeroLiquidity();
        if (shares < minSharesOut) revert SlippageExceeded();

        revert ZeroLiquidity();
    }

    /// @inheritdoc ILiquidityPool
    function withdraw(uint256 shares, address to, uint256 minAssetsOut) external nonReentrant returns (uint256 assets) {
        if (shares == 0) revert ZeroLiquidity();
        if (to == address(0)) revert ZeroAddress();
        if (block.timestamp < lockUntil[msg.sender]) revert LockTimeNotExpired();

        assets = _convertToAssets(shares);
        if (assets == 0) revert ZeroLiquidity();
        if (assets < minAssetsOut) revert SlippageExceeded();

        revert ZeroLiquidity();
    }

    /// @inheritdoc ILiquidityPool
    function accrueFees(uint256) external view {}

    /**
     * @notice Convierte assets a shares usando estado actual del pool.
     * @param assets Underlying a depositar.
     * @return shares LP shares estimadas.
     */
    function _convertToShares(uint256 assets) internal view returns (uint256 shares) {
        return FixedPointMath.convertToShares(assets, totalSupply, totalAssets, _minimumLiquidity());
    }

    /**
     * @notice Convierte shares a assets usando estado actual del pool.
     * @param shares LP shares a quemar.
     * @return assets Underlying estimado.
     */
    function _convertToAssets(uint256 shares) internal view returns (uint256 assets) {
        return FixedPointMath.convertToAssets(shares, totalSupply, totalAssets);
    }

    /**
     * @notice Liquidez mínima bloqueada en el primer depósito.
     * @return Cantidad en wei (1000).
     */
    function _minimumLiquidity() internal pure returns (uint256) {
        return 1000;
    }
}
