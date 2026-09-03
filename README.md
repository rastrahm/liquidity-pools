# 07 — Liquidity Pools & Fee Distribution

Motor de tokenización de pools de liquidez con distribución proporcional de fees, contabilidad dinámica de depósitos/retiros y protección anti-inflation attack. Solidity `0.8.24` + Foundry.

**Estado:** Fase **7** ✅ — fuzz + invariant + attack + [SWC-AUDIT](./doc/SWC-AUDIT.md).

---

## Stack

| Capa | Tecnología |
|------|------------|
| Contratos | Solidity `0.8.24` |
| Tooling | Foundry (`forge` / `cast` / `anvil`) |
| Librerías | OpenZeppelin Contracts v5.2, forge-std |
| Matemática | Punto fijo `UD60x18` |
| Seguridad | CEI, ReentrancyGuard, custom errors, SafeERC20 |

---

## Documentación

| Doc | Descripción |
|-----|-------------|
| [doc/README.md](./doc/README.md) | Índice de documentación |
| [doc/PLANIFICACION.md](./doc/PLANIFICACION.md) | Plan, fases TDD y criterios de aceptación |
| [doc/SWC-AUDIT.md](./doc/SWC-AUDIT.md) | Auditoría SWC-100–136 y mapeo a tests |
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

## Deploy local (Anvil)

```shell
anvil
forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
```

---

## Estructura (fase 7)

```
src/LiquidityPool.sol
src/LiquidityPoolFactory.sol
src/libraries/FixedPointMath.sol
test/LiquidityPool.t.sol
test/LiquidityPoolFactory.t.sol
test/fuzz/LiquidityPool.fuzz.t.sol
test/invariant/LiquidityPool.invariant.t.sol
test/invariant/LiquidityPoolHandler.sol
test/attack/FirstDepositAttack.t.sol
test/attack/ReentrancyAttack.t.sol
test/mocks/MockERC20Reentrant.sol
doc/SWC-AUDIT.md
```

---

## Tests

```shell
forge test
# 71 passed — unit + factory + fuzz(1000) + invariant(256) + attack
```

---

## Próxima fase

| Fase | Entregable |
|------|------------|
| 8 | Gas snapshot + NatSpec + SafeERC20 hardening |
