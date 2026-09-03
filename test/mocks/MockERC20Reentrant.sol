// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {ILiquidityPool} from "../../src/interfaces/ILiquidityPool.sol";

/**
 * @title MockERC20Reentrant
 * @notice ERC-20 de prueba que reentra en `deposit`/`withdraw`/`accrueFees` del pool.
 * @dev Dispara el hook en `transfer` (salida withdraw) o `transferFrom` (entrada deposit/fees).
 */
contract MockERC20Reentrant is MockERC20 {
    enum Attack {
        None,
        ReenterDeposit,
        ReenterWithdraw,
        ReenterAccrueFees
    }

    ILiquidityPool public pool;
    Attack public attack;
    address public attacker;
    uint256 public reenterAmount;

    constructor(string memory name_, string memory symbol_) MockERC20(name_, symbol_) {}

    /**
     * @notice Configura el objetivo de reentrada.
     * @param pool_ Pool a atacar.
     * @param attack_ Tipo de reentrada.
     * @param attacker_ Caller simulado en la reentrada.
     * @param reenterAmount_ Amount usado en deposit/withdraw/accrue reentrante.
     */
    function configure(ILiquidityPool pool_, Attack attack_, address attacker_, uint256 reenterAmount_) external {
        pool = pool_;
        attack = attack_;
        attacker = attacker_;
        reenterAmount = reenterAmount_;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        bool ok = super.transfer(to, amount);
        if (!ok || address(pool) == address(0) || attack == Attack.None) {
            return ok;
        }
        if (msg.sender == address(pool)) {
            _reenter();
        }
        return ok;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        bool ok = super.transferFrom(from, to, amount);
        if (!ok || address(pool) == address(0) || attack == Attack.None) {
            return ok;
        }
        if (to == address(pool) && msg.sender == address(pool)) {
            _reenter();
        }
        return ok;
    }

    function _reenter() internal {
        if (attack == Attack.ReenterDeposit) {
            pool.deposit(reenterAmount, attacker, 0);
        } else if (attack == Attack.ReenterWithdraw) {
            pool.withdraw(reenterAmount, attacker, 0);
        } else if (attack == Attack.ReenterAccrueFees) {
            pool.accrueFees(0);
        }
    }
}
