// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ILiquidityPool} from "./interfaces/ILiquidityPool.sol";
import {LiquidityPoolERC20} from "./LiquidityPoolERC20.sol";

/**
 * @title LiquidityPool
 * @notice Pool de liquidez tokenizado — stub fase 1 (validaciones sin lógica de depósito/retiro).
 * @dev Fases 2–5 implementan FixedPointMath, deposit, withdraw y fee accrual.
 */
contract LiquidityPool is ILiquidityPool, LiquidityPoolERC20, ReentrancyGuard {
    /// @inheritdoc ILiquidityPool
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

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
    function previewDeposit(uint256) external pure returns (uint256 shares) {
        shares = 0;
    }

    /// @inheritdoc ILiquidityPool
    function previewWithdraw(uint256) external pure returns (uint256 assets) {
        assets = 0;
    }

    /// @inheritdoc ILiquidityPool
    function deposit(uint256 assets, address to, uint256) external nonReentrant returns (uint256) {
        if (assets == 0) revert ZeroLiquidity();
        if (to == address(0)) revert ZeroAddress();
        if (totalSupply == 0 && assets <= MINIMUM_LIQUIDITY) revert ZeroLiquidity();
        revert ZeroLiquidity();
    }

    /// @inheritdoc ILiquidityPool
    function withdraw(uint256 shares, address to, uint256) external nonReentrant returns (uint256) {
        if (shares == 0) revert ZeroLiquidity();
        if (to == address(0)) revert ZeroAddress();
        revert ZeroLiquidity();
    }

    /// @inheritdoc ILiquidityPool
    function accrueFees(uint256) external {}
}
