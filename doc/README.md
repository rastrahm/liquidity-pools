# Documentación — Module 07: Liquidity Pools & Fee Distribution

Índice de la carpeta `doc/`.

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [SWC-AUDIT.md](./SWC-AUDIT.md) | Matriz SWC-100–136, mapeo a tests |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos deposit / withdraw / fee accrual |
| [flujograma.md](./flujograma.md) | Operativo, anti-inflation, pipeline TDD |

**Estado:** Fase **7** ✅ — fuzz + invariant + attack + SWC-AUDIT.

**Contratos:** `LiquidityPool` · `LiquidityPoolFactory` · `FixedPointMath` · `LiquidityPoolERC20`  
**Tests:** `forge test` → **71 PASS**
