// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SafeTransfer
 * @notice Transferencias ERC-20 seguras (tokens con/sin retorno `bool`).
 * @dev Patrón Uniswap V2 `TransferHelper`: low-level `call` + validación de retorno.
 *      Propaga revert data del token (p. ej. `ReentrancyGuardReentrantCall`) — SWC-104.
 */
library SafeTransfer {
    /// @notice La llamada ERC-20 falló o devolvió `false`.
    error SafeTransferFailed();

    /**
     * @notice `transfer` seguro hacia `to`.
     * @param token Contrato ERC-20.
     * @param to Receptor.
     * @param value Cantidad.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(IERC20.transfer, (to, value)));
    }

    /**
     * @notice `transferFrom` seguro desde `from` hacia `to`.
     * @param token Contrato ERC-20.
     * @param from Remitente.
     * @param to Receptor.
     * @param value Cantidad.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(IERC20.transferFrom, (from, to, value)));
    }

    /**
     * @dev Acepta retorno vacío (USDT-style) o `true`; revierte en `false` o fallo de call.
     *      Propaga el revert data del callee para preservar errores custom.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        (bool success, bytes memory returndata) = address(token).call(data);
        if (!success) {
            if (returndata.length > 0) {
                assembly ("memory-safe") {
                    revert(add(returndata, 32), mload(returndata))
                }
            }
            revert SafeTransferFailed();
        }
        if (returndata.length > 0 && !abi.decode(returndata, (bool))) {
            revert SafeTransferFailed();
        }
    }
}
