# Technical Decisions, Logic, and Gas — Module 07

🌐 [Español](./DECISIONES-TECNICAS-ES.md) · **English** · [Index](./README.md)

A reading guide to understand **what was decided**, **how the system flows**, and **where gas can still be saved**.

Complements: [PLANIFICACION-EN.md](./PLANIFICACION-EN.md) · [GAS-EN.md](./GAS-EN.md) · [SWC-AUDIT-EN.md](./SWC-AUDIT-EN.md) · [diagrama-flujo-EN.md](./diagrama-flujo-EN.md)

---

## 1. What this module is (in one sentence)

A **single-ERC-20 vault**: you deposit the underlying → you receive **LP shares**; **fees** raise the share price; when you withdraw you burn shares and get the underlying back (plus fees, if any were accrued).

It is not an AMM (`x · y = k`). That lives in module 06.

```
User ──deposit──► LiquidityPool ──holds──► Underlying ERC-20
          │
          └── mints LP shares (internal ERC-20)

Fees ──accrueFees──► totalAssets ↑ ──► more assets per share on withdraw
```

---

## 2. Technical decisions

### 2.1 Architecture

| Decision | What it means | Why |
|----------|---------------|-----|
| **Single-asset vault** | One `underlying` per pool | O(1) accounting, no multi-token packing; focus on fees + anti-inflation |
| **Factory + Pool** | `LiquidityPoolFactory.createPool(underlying)` | Multiple pools without redeploying logic; `lockDuration` fixed in the factory |
| **Custom LP ERC-20** (`LiquidityPoolERC20`) | Doesn't inherit OZ ERC20 | OZ v5 **reverts** on minting to `address(0)`; we need to burn `MINIMUM_LIQUIDITY` there |
| **Explicit `totalAssets` accounting** | `balanceOf(pool)` alone is not the source of truth | Direct donations do **not** change the share price until `accrueFees` |
| **Preview + on-chain slippage** | `previewDeposit` / `previewWithdraw` + `minSharesOut` / `minAssetsOut` | Mitigates MEV (SWC-114) between the estimate and the transaction |

### 2.2 Security and threat model

| Decision | Detail |
|----------|--------|
| **CEI** | Mint/burn and state updates happen **before** `safeTransfer` / `safeTransferFrom` |
| **`nonReentrant`** | On `deposit`, `withdraw`, `accrueFees` (defense in depth + tokens with callbacks) |
| **`MINIMUM_LIQUIDITY = 1000`** | First deposit: mint 1000 wei to `address(0)` and `assets - 1000` to the user | Prevents the first-depositor inflation attack |
| **Lock time** | Every deposit sets `lockUntil[to] = now + lockDuration` | Reduces churn / short-term flash manipulation |
| **Custom errors** | `ZeroLiquidity`, `SlippageExceeded`, `LockTimeNotExpired`, … | Cheaper and better typed than `require` with strings |
| **Custom `SafeTransfer`** | Low-level `call` + bubble-revert (Uniswap V2 style) | SWC-104; propagates the token's custom errors (useful in reentrancy tests) |
| **Fixed pragma `0.8.24`** | No `^` | SWC-103; native 0.8 overflow checks |

### 2.3 Fee math

| Decision | Detail |
|----------|--------|
| **Implicit share price** | `assets_per_share ≈ totalAssets / totalSupply` |
| **`accFeePerShare` (UD60x18)** | Accumulator: `+= feeDelta * 1e18 / totalSupply` | Fixed precision; no new shares are minted for fees |
| **Conversion** | `shares = assets * supply / totalAssets` (after the first deposit) | `FixedPointMath.mulDiv` with an overflow check |
| **Fees with no LPs** | If `totalSupply == 0`, the delta stays in reserve | It is reflected at the first deposit through `totalAssets` |

**Design note:** in this vault the LP does **not** claim a per-account "pending fee." The benefit is automatic: since `totalAssets` grows without a proportional increase in shares, **each share is worth more** on withdrawal.

### 2.4 Out of scope (v1)

- Swaps / constant product (module 06)
- Fee-on-transfer / rebasing tokens
- On-chain governance of the fee or the lock
- Permit / signatures in the pool
- Native ETH as the underlying

---

## 3. How the system works

### 3.1 Lifecycle

1. Deploy `LiquidityPoolFactory(lockDuration)`.
2. `createPool(underlying)` → new `LiquidityPool`.
3. Users: `approve` → `deposit` / `withdraw` / `accrueFees`.

### 3.2 First deposit

```
assets > 1000
→ mint 1000 LP to address(0)     // locked forever
→ mint (assets - 1000) to `to`
→ totalAssets += assets
→ lockUntil[to] = now + lockDuration
→ transferFrom(user → pool, assets)
```

If `assets <= 1000` → `ZeroLiquidity` (you can't bootstrap the pool without leaving minimum liquidity).

### 3.3 Later deposits

```
shares = assets * totalSupply / totalAssets
if shares < minSharesOut → SlippageExceeded
→ mint shares to `to`
→ totalAssets += assets
→ reset lockUntil[to]
→ transferFrom
```

### 3.4 Withdrawal

```
now >= lockUntil[msg.sender]  (otherwise → LockTimeNotExpired)
assets = shares * totalAssets / totalSupply
if assets < minAssetsOut → SlippageExceeded
→ burn shares from msg.sender
→ totalAssets -= assets
→ transfer(to, assets)
```

### 3.5 Fee accrual

```
if amount > 0 → pull amount from the caller
balance = underlying.balanceOf(pool)
if balance <= totalAssets → return (nothing to sync)
feeDelta = balance - totalAssets
totalAssets = balance
if totalSupply > 0:
  accFeePerShare += feeDelta * 1e18 / totalSupply
emit FeesAccrued
```

Effect for the LP: **same shares, more underlying on withdrawal**.

### 3.6 Mental model (CEI)

Always:

1. **Checks** (zero, lock, slippage)
2. **Effects** (mint/burn, `totalAssets`, `lockUntil`, `accFeePerShare`)
3. **Interactions** (ERC-20 transfer)

---

## 4. Can the existing gas usage be improved?

Yes. The current baseline is **solid and readable** (Phase 8), not the absolute minimum. Below are realistic improvements, ordered by impact / risk.

Baseline (medians, see [GAS-EN.md](./GAS-EN.md)):

| Function | Approx. median |
|----------|----------------|
| `deposit` | ~177k |
| `withdraw` | ~46k |
| `accrueFees` | ~69k |
| Pool deployment | ~1.0M |

### 4.1 High-value / relatively low-risk improvements

| Idea | What it saves | Cost / risk |
|------|---------------|-------------|
| **Cache `totalSupply` / `totalAssets` in locals** at the start of `deposit`/`withdraw` | Fewer repeated SLOADs in convert + mint/burn | Small change; re-run fuzz/invariant tests |
| **`IERC20 private immutable _token`** alongside `address immutable underlying` | Avoids repeated `IERC20(underlying)` casts | +1 immutable; slightly more bytecode |
| **Packing `name`/`symbol` or moving metadata off-chain** | Cheaper deployment (strings in storage are expensive) | Less on-chain UX; or use EIP-7201 / immutable hashes |
| **Higher `optimizer_runs` (e.g. 1000–10000)** | Cheaper runtime on the hot path | More expensive deployment; measure with `forge snapshot` |
| **Drop `accFeePerShare` storage if nothing reads it off-chain** | One less SSTORE on sync | Currently useful for indexers/UI; the share price is already `totalAssets/supply` |

### 4.2 Medium improvements (security or clarity tradeoff)

| Idea | What it saves | Tradeoff |
|------|---------------|----------|
| **Remove `ReentrancyGuard` and rely on CEI alone** | ~2.3k–5k gas of status SLOAD/SSTORE + less bytecode | Only safe if the underlying **never** calls back (no ERC-777 / hooks). Kept today as a defense |
| **OZ `SafeERC20` vs custom `SafeTransfer`** | Standard code | You lose the clean bubble-revert of custom errors on some test paths |
| **Transient storage (Cancun) for the reentrancy flag** | Cheaper flag than classic storage | Requires a target chain with EIP-1153 |
| **Skip events on internal paths** | Some gas | Worse observability |

### 4.3 Aggressive improvements (only if the goal is "minimum gas")

| Idea | Note |
|------|------|
| **Solmate / minimal ERC20 without infinite-allowance check branches** | The LP ERC-20 already has infinite allowance; it can be compacted further |
| **Assembly in `mulDiv`** (Uniswap `FullMath` style) | More gas-efficient for large products; larger bug surface |
| **Clone / minimal proxy (EIP-1167) in the Factory** | `createPool` much cheaper than `new LiquidityPool` (~1M) | Changes the deployment and verification model |
| **SSTORE2 / immutable args for the pool bytecode** | Lighter factory deployment | High complexity |

### 4.4 What you should **not** "optimize" blindly

- Removing `MINIMUM_LIQUIDITY` → reopens the inflation attack.
- Using `balanceOf` alone as `totalAssets` → donations / accidental syncs change the ratio.
- Removing `minSharesOut` / `minAssetsOut` → unchecked MEV.
- `unchecked` without prior checks → SWC-101.

### 4.5 How to measure any change

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge snapshot --match-contract LiquidityPoolGasTest
forge test --match-contract LiquidityPoolGasTest --gas-report
forge test   # don't break the 78 PASS + fuzz/invariant
```

Rule of thumb: **if the snapshot goes down but an invariant fails, it's not an improvement.**

---

## 5. Quick file map

| Piece | Role |
|-------|------|
| `src/LiquidityPool.sol` | deposit / withdraw / accrueFees |
| `src/LiquidityPoolFactory.sol` | creates pools |
| `src/LiquidityPoolERC20.sol` | LP token (allows minting to `address(0)`) |
| `src/libraries/FixedPointMath.sol` | shares ↔ assets, `accFeePerShare` |
| `src/libraries/SafeTransfer.sol` | safe transfers + bubble-revert |
| `test/attack/` | FirstDeposit + Reentrancy |
| `test/fuzz/` · `test/invariant/` | properties and solvency |
| `test/gas/` · `.gas-snapshot` | gas baseline |

---

## 6. Summary

1. **Decisions:** single-asset vault, custom LP token, explicit `totalAssets`, CEI + reentrancy guard, anti-inflation, lock, slippage, fees through the share price.
2. **Logic:** deposit mints shares; fees raise `totalAssets`; withdraw burns shares after the lock.
3. **Gas:** immutables, constants, post-check `unchecked`, caching in `_syncFees`, and custom errors are already in place. It can go lower (clones, transient reentrancy, fewer SLOADs, optimizer), always measured against fuzz/invariant tests.

Suggested next concrete step: prioritize **EIP-1167 clones in the Factory** (biggest deployment win) or **storage caching in deposit/withdraw** (hot-path win with less risk).
