# Documentación — Module 07: Liquidity Pools & Fee Distribution

Índice de la carpeta `doc/`.

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos deposit / withdraw / fee accrual |
| [flujograma.md](./flujograma.md) | Operativo, anti-inflation, pipeline TDD |

**Estado:** Fase **1** ✅ — tests TDD (13 rojos / 7 verdes).

**Contratos (planificados):** `LiquidityPool` · `LiquidityPoolFactory` · `FixedPointMath`  
**Tests:** `forge test --match-contract LiquidityPoolTest` → **7 PASS / 13 FAIL** (rojos hasta fases 3–4)
