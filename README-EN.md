# 07 — Liquidity Pools & Fee Distribution

🌐 [Español](./README-ES.md) · **English** · [Index](./README.md)

Liquidity pool tokenization engine with proportional fee distribution, dynamic deposit/withdrawal accounting, and protection against inflation attacks. Solidity `0.8.24` + Foundry.

**Status:** Phases **0–8** ✅ (module closed).

---

## Stack

| Layer | Technology |
|-------|------------|
| Contracts | Solidity `0.8.24` |
| Tooling | Foundry (`forge` / `cast` / `anvil`) |
| Libraries | OpenZeppelin Contracts v5.2, forge-std, custom `SafeTransfer` |
| Math | `UD60x18` fixed point |
| Security | CEI, ReentrancyGuard, custom errors, SafeTransfer |

---

## Documentation

| Doc | Description |
|-----|-------------|
| [doc/README-EN.md](./doc/README-EN.md) | Documentation index |
| [doc/PLANIFICACION-EN.md](./doc/PLANIFICACION-EN.md) | Plan, TDD phases, and acceptance criteria |
| [doc/DECISIONES-TECNICAS-EN.md](./doc/DECISIONES-TECNICAS-EN.md) | Technical decisions, vault logic, and gas improvements |
| [doc/SWC-AUDIT-EN.md](./doc/SWC-AUDIT-EN.md) | SWC-100–136 audit and test mapping |
| [doc/GAS-EN.md](./doc/GAS-EN.md) | Baseline gas report and optimizations |
| [doc/DEPLOY-EN.md](./doc/DEPLOY-EN.md) | Anvil deployment + frontend |
| [doc/diagrama-flujo-EN.md](./doc/diagrama-flujo-EN.md) | Deposit / withdraw / fee flows |
| [doc/diagrama-clases-EN.md](./doc/diagrama-clases-EN.md) | Contract UML |
| [doc/flujograma-EN.md](./doc/flujograma-EN.md) | Operational flowchart and TDD pipeline |

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

## Local deployment (Anvil)

```shell
anvil
forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
```

---

## Structure

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
