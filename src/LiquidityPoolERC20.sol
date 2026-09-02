// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title LiquidityPoolERC20
 * @notice ERC-20 interno para LP shares del pool.
 * @dev Permite `_mint` a `address(0)` para bloquear `MINIMUM_LIQUIDITY`.
 *      OpenZeppelin ERC20 v5 revierte en receptor cero; por eso no se usa como base del LP.
 */
abstract contract LiquidityPoolERC20 {
    /// @notice Nombre del token LP.
    string public name;

    /// @notice Símbolo del token LP.
    string public symbol;

    /// @notice Decimales del token LP.
    uint8 public constant decimals = 18;

    /// @notice Supply total de LP.
    uint256 public totalSupply;

    /// @notice Balance LP por cuenta.
    mapping(address => uint256) public balanceOf;

    /// @notice Allowance LP: owner => spender => amount.
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice Aprobación de gasto.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Transferencia de LP.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Inicializa metadatos del token LP.
     * @param name_ Nombre del token LP.
     * @param symbol_ Símbolo del token LP.
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    /**
     * @notice Aprueba `spender` a gastar `value` de `msg.sender`.
     * @param spender Gastador autorizado.
     * @param value Cantidad aprobada.
     * @return success Siempre `true`.
     */
    function approve(address spender, uint256 value) external returns (bool success) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice Transfiere `value` LP a `to`.
     * @param to Receptor.
     * @param value Cantidad.
     * @return success Siempre `true`.
     */
    function transfer(address to, uint256 value) external returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Transfiere `value` LP de `from` a `to` usando allowance.
     * @param from Remitente.
     * @param to Receptor.
     * @param value Cantidad.
     * @return success Siempre `true`.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool success) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - value;
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice Acuña LP a `to` (permite `address(0)`).
     * @param to Receptor.
     * @param value Cantidad.
     */
    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        unchecked {
            balanceOf[to] += value;
        }
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice Quema LP de `from`.
     * @param from Cuenta a debitar.
     * @param value Cantidad.
     */
    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        unchecked {
            totalSupply -= value;
        }
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] -= value;
        unchecked {
            balanceOf[to] += value;
        }
        emit Transfer(from, to, value);
    }
}
