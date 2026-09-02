# Documentación — Module 07: Liquidity Pools & Fee Distribution

Índice de la carpeta `doc/`.

| Documento | Contenido |
|-----------|-----------|
| [PLANIFICACION.md](./PLANIFICACION.md) | Objetivo, alcance, fases TDD, criterios |
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos / libs / tests |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos deposit / withdraw / fee accrual |
| [flujograma.md](./flujograma.md) | Operativo, anti-inflation, pipeline TDD |

**Estado:** Fase **2** ✅ — FixedPointMath + skeleton previews.

**Contratos:** `LiquidityPool` (skeleton) · `FixedPointMath` · `LiquidityPoolERC20`  
**Tests:** `forge test` → **27 PASS / 12 FAIL** (deposit/withdraw en fases 3–4)
