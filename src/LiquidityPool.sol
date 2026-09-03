// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ILiquidityPool} from "./interfaces/ILiquidityPool.sol";
import {LiquidityPoolERC20} from "./LiquidityPoolERC20.sol";
import {FixedPointMath} from "./libraries/FixedPointMath.sol";
import {SafeTransfer} from "./libraries/SafeTransfer.sol";

/**
 * @title LiquidityPool
 * @notice Pool de liquidez tokenizado con LP shares, anti-inflation guard y fee accrual.
 * @dev CEI en `deposit`/`withdraw`/`accrueFees`. Fees vía `accFeePerShare` (UD60x18).
 *      Transfers con `SafeTransfer` (SWC-104, bubble-revert).
 */
contract LiquidityPool is ILiquidityPool, LiquidityPoolERC20, ReentrancyGuard {
    using SafeTransfer for IERC20;

    /// @dev Tranche mínima bloqueada en el primer depósito (`address(0)`).
    uint256 private constant _MINIMUM_LIQUIDITY = 1000;

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
        return _MINIMUM_LIQUIDITY;
    }

    /// @inheritdoc ILiquidityPool
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        return _convertToShares(assets);
    }

    /// @inheritdoc ILiquidityPool
    function previewWithdraw(uint256 shares) external view returns (uint256 assets) {
        return _convertToAssets(shares);
    }

    /**
     * @inheritdoc ILiquidityPool
     * @dev CEI: mint LP + actualizar estado antes de `safeTransferFrom`.
     */
    function deposit(uint256 assets, address to, uint256 minSharesOut) external nonReentrant returns (uint256 shares) {
        if (assets == 0) revert ZeroLiquidity();
        if (to == address(0)) revert ZeroAddress();

        shares = _convertToShares(assets);
        if (shares == 0) revert ZeroLiquidity();
        if (shares < minSharesOut) revert SlippageExceeded();

        bool isFirstDeposit = totalSupply == 0;

        if (isFirstDeposit) {
            _mint(address(0), _MINIMUM_LIQUIDITY);
        }
        _mint(to, shares);

        unchecked {
            totalAssets += assets;
        }
        lockUntil[to] = block.timestamp + lockDuration;

        emit Deposit(msg.sender, to, assets, shares);

        IERC20(underlying).safeTransferFrom(msg.sender, address(this), assets);
    }

    /**
     * @inheritdoc ILiquidityPool
     * @dev CEI: burn LP + actualizar reservas antes de `safeTransfer`.
     */
    function withdraw(uint256 shares, address to, uint256 minAssetsOut) external nonReentrant returns (uint256 assets) {
        if (shares == 0) revert ZeroLiquidity();
        if (to == address(0)) revert ZeroAddress();
        if (block.timestamp < lockUntil[msg.sender]) revert LockTimeNotExpired();

        assets = _convertToAssets(shares);
        if (assets == 0) revert ZeroLiquidity();
        if (assets < minAssetsOut) revert SlippageExceeded();

        _burn(msg.sender, shares);
        unchecked {
            totalAssets -= assets;
        }

        emit Withdraw(msg.sender, to, msg.sender, assets, shares);

        IERC20(underlying).safeTransfer(to, assets);
    }

    /**
     * @inheritdoc ILiquidityPool
     * @dev `amount > 0` hace pull; `amount == 0` solo sincroniza donaciones on-chain.
     */
    function accrueFees(uint256 amount) external nonReentrant {
        if (amount > 0) {
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        }

        _syncFees();
    }

    /**
     * @notice Sincroniza `totalAssets` con el balance y distribuye fee delta a LPs.
     * @dev Si `totalSupply == 0`, los fees quedan en reserva hasta el primer depósito.
     */
    function _syncFees() internal {
        IERC20 token = IERC20(underlying);
        uint256 balance = token.balanceOf(address(this));
        uint256 assetsCached = totalAssets;
        if (balance <= assetsCached) return;

        uint256 feeDelta;
        unchecked {
            feeDelta = balance - assetsCached;
        }
        totalAssets = balance;

        uint256 supply = totalSupply;
        if (supply > 0) {
            accFeePerShare = FixedPointMath.accrueFeePerShare(feeDelta, supply, accFeePerShare);
        }

        emit FeesAccrued(feeDelta, accFeePerShare);
    }

    /**
     * @notice Convierte assets a shares usando estado actual del pool.
     * @param assets Underlying a depositar.
     * @return shares LP shares estimadas.
     */
    function _convertToShares(uint256 assets) internal view returns (uint256 shares) {
        return FixedPointMath.convertToShares(assets, totalSupply, totalAssets, _MINIMUM_LIQUIDITY);
    }

    /**
     * @notice Convierte shares a assets usando estado actual del pool.
     * @param shares LP shares a quemar.
     * @return assets Underlying estimado.
     */
    function _convertToAssets(uint256 shares) internal view returns (uint256 assets) {
        return FixedPointMath.convertToAssets(shares, totalSupply, totalAssets);
    }
}
