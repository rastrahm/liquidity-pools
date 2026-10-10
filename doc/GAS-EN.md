# Gas Optimization — Liquidity Pools

🌐 [Español](./GAS-ES.md) · **English** · [Index](./README.md)

Regenerate:

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge test --match-contract 'LiquidityPoolTest|LiquidityPoolFactoryTest|LiquidityPoolGasTest' --gas-report
forge snapshot --match-contract LiquidityPoolGasTest
```

**Baseline date:** 2026-09-03 (Phase 8)  
**Snapshot:** `.gas-snapshot` (tests in `test/gas/LiquidityPool.gas.t.sol`)

---

## Deployment

| Contract | Deployment cost | Bytecode | Notes |
|----------|-----------------|----------|-------|
| `LiquidityPool` | 998,194 gas · 5,152 B | Deployed at runtime via the Factory | Includes LP ERC-20 + ReentrancyGuard + SafeTransfer |
| `LiquidityPoolFactory` | 1,295,009 gas · 5,894 B | Includes the pool bytecode | `createPool` ~992,613 (median) |

---

## Main functions (gas report, medians)

| Function | Min | Avg | Median | Max | Notes |
|----------|-----|-----|--------|-----|-------|
| `deposit` | 27,141 | 146,868 | **176,965** | 176,965 | First (cold) deposit sits at the high end |
| `withdraw` | 27,120 | 44,741 | **46,498** | 63,550 | After lock; burn + transfer |
| `accrueFees` | 31,492 | 66,307 | **68,688** | 82,416 | Pull + UD60x18 sync |
| `previewDeposit` | 4,759 | 4,805 | **4,836** | 4,836 | Pure view |
| `previewWithdraw` | 4,738 | 4,905 | **4,922** | 4,922 | Pure view |
| `Factory.createPool` | 21,557 | 861,022 | **992,613** | 992,613 | Includes `new LiquidityPool` |

---

## End-to-end snapshot (`test/gas/LiquidityPool.gas.t.sol`)

| Test | Gas |
|------|-----|
| `testGas_createPool` | 1,415,577 |
| `testGas_firstDeposit` | 173,334 |
| `testGas_subsequentDeposit` | 190,163 |
| `testGas_withdraw` | 188,404 |
| `testGas_accrueFees` | 218,178 |
| `testGas_previewDeposit` | 10,054 |
| `testGas_previewWithdraw` | 175,697 |

---

## Optimizations applied (Phase 8)

| Technique | Where | Effect |
|-----------|-------|--------|
| `SafeTransfer` (low-level `call` + bubble revert) | Pool | SWC-104; propagates `ReentrancyGuard` on reentry |
| `immutable` `underlying` / `lockDuration` | Pool, Factory | Cheap reads |
| `constant` `_MINIMUM_LIQUIDITY` | Pool | No SLOAD in conversions |
| `unchecked` on `totalAssets +=/-=` after checks | deposit / withdraw | Overflow is impossible after validation |
| Cached locals `balance` / `supply` / `assetsCached` | `_syncFees` | Fewer storage reads |
| Custom errors | Everywhere | Cheaper than `require` strings |
| `optimizer_runs = 200` | `foundry.toml` | Balances deployment vs runtime cost |

---

## Accepted tradeoffs

| Decision | Why |
|----------|-----|
| Custom `SafeTransfer` vs OZ `SafeERC20` | SWC-104 bubble-revert (reentrancy tests); Uniswap V2 pattern |
| Lock time based on `block.timestamp` | Explicit design; SWC-116 accepted |
| Explicit `totalAssets` accounting | Donations don't inflate the share price until `accrueFees` |
| Single-asset pool | No multi-token packing; predictable O(1) gas |

---

## Relationship with security

See [`SWC-AUDIT-EN.md`](./SWC-AUDIT-EN.md): SafeTransfer covers SWC-104; CEI + `nonReentrant` cover SWC-107; fuzz/invariant tests confirm the optimizations don't break solvency.
