# Documentación — Module 07: Liquidity Pools & Fee Distribution

🌐 **Español** · [English](./README-EN.md) · [Índice](./README.md)

Índice de la carpeta `doc/`. **Proyecto completo** (contratos + seguridad + gas).

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION-ES.md](./PLANIFICACION-ES.md) | Objetivo, alcance, fases TDD, criterios |
| [DECISIONES-TECNICAS-ES.md](./DECISIONES-TECNICAS-ES.md) | Decisiones, lógica del vault, mejoras de gas |
| [DICCIONARIO-CONTABLE-ES.md](./DICCIONARIO-CONTABLE-ES.md) | Términos DeFi ↔ analogía contable (suite) |
| [SWC-AUDIT-ES.md](./SWC-AUDIT-ES.md) | Matriz SWC-100–136, mapeo a tests |
| [GAS-ES.md](./GAS-ES.md) | Baseline gas, optimizaciones, snapshot |
| [DEPLOY-ES.md](./DEPLOY-ES.md) | Deploy en Anvil + configuración del frontend |
| [diagrama-clases-ES.md](./diagrama-clases-ES.md) | UML contratos / libs / tests |
| [diagrama-flujo-ES.md](./diagrama-flujo-ES.md) | Flujos deposit / withdraw / fee accrual |
| [flujograma-ES.md](./flujograma-ES.md) | Operativo, anti-inflation, pipeline TDD |

**Estado:** Fases **0–8** ✅ + **UI** ✅

**Contratos:** `LiquidityPool` · `LiquidityPoolFactory` · `FixedPointMath` · `SafeTransfer`  
**Tests:** `forge test` → **78 PASS** · `cd frontend && npm test`  
**UI:** `frontend/` — deposit, withdraw, fees, tema claro/oscuro
