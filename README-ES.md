# 07 — Liquidity Pools & Fee Distribution

🌐 **Español** · [English](./README-EN.md) · [Índice](./README.md)

Motor de tokenización de pools de liquidez con distribución proporcional de fees, contabilidad dinámica de depósitos/retiros y protección anti-inflation attack. Solidity `0.8.24` + Foundry.

**Estado:** Fases **0–8** ✅ (módulo cerrado).

---

## Stack

| Capa | Tecnología |
|------|------------|
| Contratos | Solidity `0.8.24` |
| Tooling | Foundry (`forge` / `cast` / `anvil`) |
| Librerías | OpenZeppelin Contracts v5.2, forge-std, `SafeTransfer` propio |
| Matemática | Punto fijo `UD60x18` |
| Seguridad | CEI, ReentrancyGuard, custom errors, SafeTransfer |

---

## Documentación

| Doc | Descripción |
|-----|-------------|
| [doc/README-ES.md](./doc/README-ES.md) | Índice de documentación |
| [doc/PLANIFICACION-ES.md](./doc/PLANIFICACION-ES.md) | Plan, fases TDD y criterios de aceptación |
| [doc/DECISIONES-TECNICAS-ES.md](./doc/DECISIONES-TECNICAS-ES.md) | Decisiones, lógica del vault y mejoras de gas |
| [doc/SWC-AUDIT-ES.md](./doc/SWC-AUDIT-ES.md) | Auditoría SWC-100–136 y mapeo a tests |
| [doc/GAS-ES.md](./doc/GAS-ES.md) | Gas report baseline y optimizaciones |
| [doc/DEPLOY-ES.md](./doc/DEPLOY-ES.md) | Deploy en Anvil + frontend |
| [doc/diagrama-flujo-ES.md](./doc/diagrama-flujo-ES.md) | Flujos deposit / withdraw / fees |
| [doc/diagrama-clases-ES.md](./doc/diagrama-clases-ES.md) | UML de contratos |
| [doc/flujograma-ES.md](./doc/flujograma-ES.md) | Flujograma operativo y pipeline TDD |

---

## Setup

```shell
export PATH="$HOME/.foundry/bin:$PATH"

forge install foundry-rs/forge-std@v1.16.2 --no-git
forge install OpenZeppelin/openzeppelin-contracts@v5.2.0 --no-git

forge build
forge test
forge snapshot --match-contract LiquidityPoolGasTest
```

---

## Deploy local (Anvil)

```shell
anvil
forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
```

---

## Estructura

```
src/LiquidityPool.sol
src/LiquidityPoolFactory.sol
src/LiquidityPoolERC20.sol
src/libraries/FixedPointMath.sol
src/libraries/SafeTransfer.sol
test/LiquidityPool.t.sol
test/LiquidityPoolFactory.t.sol
test/fuzz/
test/invariant/
test/attack/
test/gas/LiquidityPool.gas.t.sol
script/Deploy.s.sol
doc/
```

---

## Tests

```shell
forge test
# 78 passed — unit + factory + fuzz + invariant + attack + gas
```
