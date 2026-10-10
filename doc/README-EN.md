# Documentation — Module 07: Liquidity Pools & Fee Distribution

🌐 [Español](./README-ES.md) · **English** · [Index](./README.md)

Index of the `doc/` folder. **Complete project** (contracts + security + gas).

| Document | Contents |
|----------|----------|
| [PLANIFICACION-EN.md](./PLANIFICACION-EN.md) | Goal, scope, TDD phases, criteria |
| [DECISIONES-TECNICAS-EN.md](./DECISIONES-TECNICAS-EN.md) | Decisions, vault logic, gas improvements |
| [DICCIONARIO-CONTABLE-EN.md](./DICCIONARIO-CONTABLE-EN.md) | DeFi terms ↔ accounting analogy (suite) |
| [SWC-AUDIT-EN.md](./SWC-AUDIT-EN.md) | SWC-100–136 matrix, test mapping |
| [GAS-EN.md](./GAS-EN.md) | Gas baseline, optimizations, snapshot |
| [DEPLOY-EN.md](./DEPLOY-EN.md) | Anvil deployment + frontend configuration |
| [diagrama-clases-EN.md](./diagrama-clases-EN.md) | Contract / library / test UML |
| [diagrama-flujo-EN.md](./diagrama-flujo-EN.md) | Deposit / withdraw / fee accrual flows |
| [flujograma-EN.md](./flujograma-EN.md) | Operations, anti-inflation, TDD pipeline |

**Status:** Phases **0–8** ✅ + **UI** ✅

**Contracts:** `LiquidityPool` · `LiquidityPoolFactory` · `FixedPointMath` · `SafeTransfer`  
**Tests:** `forge test` → **78 PASS** · `cd frontend && npm test`  
**UI:** `frontend/` — deposit, withdraw, fees, light/dark theme
