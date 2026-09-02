# 07 — Liquidity Pools & Fee Distribution

Motor de tokenización de pools de liquidez con distribución proporcional de fees, contabilidad dinámica de depósitos/retiros y protección anti-inflation attack. Solidity `0.8.24` + Foundry.

**Estado:** Fase **4** ✅ — `deposit` + `withdraw` (lock time + slippage).

---

## Stack

| Capa | Tecnología |
|------|------------|
| Contratos | Solidity `0.8.24` |
| Tooling | Foundry (`forge` / `cast` / `anvil`) |
| Librerías | OpenZeppelin Contracts v5.2, forge-std |
| Matemática | Punto fijo `UD60x18` (fase 2+) |
| Seguridad | CEI, ReentrancyGuard, custom errors, SafeERC20 |

---

## Documentación

| Doc | Descripción |
|-----|-------------|
| [doc/README.md](./doc/README.md) | Índice de documentación |
| [doc/PLANIFICACION.md](./doc/PLANIFICACION.md) | Plan, fases TDD y criterios de aceptación |
| [doc/diagrama-flujo.md](./doc/diagrama-flujo.md) | Flujos deposit / withdraw / fees |
| [doc/diagrama-clases.md](./doc/diagrama-clases.md) | UML de contratos |
| [doc/flujograma.md](./doc/flujograma.md) | Flujograma operativo y pipeline TDD |

---

## Setup

```shell
export PATH="$HOME/.foundry/bin:$PATH"

forge install foundry-rs/forge-std@v1.16.2 --no-git
forge install OpenZeppelin/openzeppelin-contracts@v5.2.0 --no-git

forge build
forge test
```

---

## Estructura (fase 4)

```
src/libraries/FixedPointMath.sol
src/LiquidityPool.sol          # deposit ✅ · withdraw ✅
src/LiquidityPoolERC20.sol
src/mocks/MockERC20.sol
test/LiquidityPool.t.sol       # 23/23 verdes
test/FixedPointMath.t.sol
```

---

## Tests

```shell
forge test
# 39 passed — deposit + withdraw + FixedPointMath + scaffold
```

---

## Próximas fases

| Fase | Entregable |
|------|------------|
| 5 | Fee accrual proporcional (`accFeePerShare`) |
| 5 | Fee accrual proporcional |
| 6 | `LiquidityPoolFactory` + deploy script |
| 7 | Fuzz + invariant + FirstDepositAttack |
| 8 | Gas snapshot + NatSpec + SafeERC20 |
