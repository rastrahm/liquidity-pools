# 07 — Liquidity Pools & Fee Distribution

Motor de tokenización de pools de liquidez con distribución proporcional de fees, contabilidad dinámica de depósitos/retiros y protección anti-inflation attack. Solidity `0.8.24` + Foundry.

**Estado:** Fase **1** ✅ — tests TDD deposit/withdraw (13 rojos, 7 verdes).

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

## Estructura (fase 1)

```
src/interfaces/           # ILiquidityPool, ILiquidityPoolFactory
src/LiquidityPool.sol     # Stub fase 1 (validaciones; lógica en fases 2–5)
src/LiquidityPoolERC20.sol
src/mocks/                # MockERC20
test/LiquidityPool.t.sol  # 20 tests TDD (13 rojos)
test/Scaffold.t.sol
script/Deploy.s.sol
doc/
```

---

## Tests TDD (fase 1)

```shell
forge test --match-contract LiquidityPoolTest
# 7 passed — constructor + reverts básicos (stub)
# 13 failed — caminos felices deposit/withdraw (fases 3–4)
```

---

## Próximas fases

| Fase | Entregable |
|------|------------|
| 2 | `FixedPointMath` + skeleton `LiquidityPool` |
| 3 | `deposit` + MINIMUM_LIQUIDITY + anti-inflation |
| 4 | `withdraw` + slippage + lock time |
| 5 | Fee accrual proporcional |
| 6 | `LiquidityPoolFactory` + deploy script |
| 7 | Fuzz + invariant + FirstDepositAttack |
| 8 | Gas snapshot + NatSpec + SafeERC20 |
