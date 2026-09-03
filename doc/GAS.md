# Optimización de gas — Liquidity Pools

Regenerar:

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge test --match-contract 'LiquidityPoolTest|LiquidityPoolFactoryTest|LiquidityPoolGasTest' --gas-report
forge snapshot --match-contract LiquidityPoolGasTest
```

**Fecha baseline:** 2026-09-03 (Fase 8)  
**Snapshot:** `.gas-snapshot` (tests en `test/gas/LiquidityPool.gas.t.sol`)

---

## Deploy

| Contrato | Coste deploy | Bytecode | Notas |
|----------|--------------|----------|-------|
| `LiquidityPool` | 998 194 gas · 5 152 B | Runtime vía Factory | Incluye LP ERC-20 + ReentrancyGuard + SafeTransfer |
| `LiquidityPoolFactory` | 1 295 009 gas · 5 894 B | Incluye bytecode del pool | `createPool` ~992 613 (mediana) |

---

## Funciones principales (gas-report, medianas)

| Función | Min | Avg | Median | Max | Notas |
|---------|-----|-----|--------|-----|-------|
| `deposit` | 27 141 | 146 868 | **176 965** | 176 965 | Primer depósito (cold) en el alto |
| `withdraw` | 27 120 | 44 741 | **46 498** | 63 550 | Post-lock; burn + transfer |
| `accrueFees` | 31 492 | 66 307 | **68 688** | 82 416 | Pull + sync UD60x18 |
| `previewDeposit` | 4 759 | 4 805 | **4 836** | 4 836 | View puro |
| `previewWithdraw` | 4 738 | 4 905 | **4 922** | 4 922 | View puro |
| `Factory.createPool` | 21 557 | 861 022 | **992 613** | 992 613 | Incluye `new LiquidityPool` |

---

## Snapshot e2e (`test/gas/LiquidityPool.gas.t.sol`)

| Test | Gas |
|------|-----|
| `testGas_createPool` | 1 415 577 |
| `testGas_firstDeposit` | 173 334 |
| `testGas_subsequentDeposit` | 190 163 |
| `testGas_withdraw` | 188 404 |
| `testGas_accrueFees` | 218 178 |
| `testGas_previewDeposit` | 10 054 |
| `testGas_previewWithdraw` | 175 697 |

---

## Optimizaciones aplicadas (Fase 8)

| Técnica | Dónde | Efecto |
|---------|-------|--------|
| `SafeTransfer` (low-level `call` + bubble revert) | Pool | SWC-104; propaga `ReentrancyGuard` en reentrada |
| `immutable` `underlying` / `lockDuration` | Pool, Factory | Lecturas baratas |
| `constant` `_MINIMUM_LIQUIDITY` | Pool | Sin SLOAD en conversiones |
| `unchecked` en `totalAssets +=/-=` post-checks | deposit / withdraw | Overflow imposible tras validaciones |
| Cache locals `balance` / `supply` / `assetsCached` | `_syncFees` | Menos lecturas de storage |
| Custom errors | Todos | Menor coste vs `require` strings |
| `optimizer_runs = 200` | `foundry.toml` | Balance deploy/runtime |

---

## Tradeoffs aceptados

| Decisión | Por qué |
|----------|---------|
| `SafeTransfer` propio vs OZ `SafeERC20` | Bubble-revert SWC-104 (reentrancy tests); patrón Uniswap V2 |
| Lock time con `block.timestamp` | Diseño explícito; SWC-116 aceptado |
| Contabilidad `totalAssets` explícita | Donaciones no inflan share price hasta `accrueFees` |
| Single-asset pool | Sin packing multi-token; gas predecible O(1) |

---

## Relación con seguridad

Ver [`SWC-AUDIT.md`](./SWC-AUDIT.md): SafeTransfer cubre SWC-104; CEI + `nonReentrant` cubren SWC-107; fuzz/invariant validan que las opts no rompen solvencia.
