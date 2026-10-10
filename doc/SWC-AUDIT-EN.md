# SWC Audit — Liquidity Pools & Fee Distribution

🌐 [Español](./SWC-AUDIT-ES.md) · **English** · [Index](./README.md)

Review of `LiquidityPool` and `LiquidityPoolFactory` against the [SWC Registry](https://swcregistry.io/) (EIP-1470) and the monorepo principles (custom errors, `ReentrancyGuard`, SafeERC20, MINIMUM_LIQUIDITY, UD60x18).

> **Note:** The SWC Registry has not been actively maintained since ~2020. Complement it with [SCSVS](https://github.com/ComposableSecurity/SCSVS) and [EEA EthTrust](https://entethalliance.org/specs/ethtrust/).

**Audited contracts:** `src/LiquidityPool.sol`, `src/LiquidityPoolFactory.sol`, `src/LiquidityPoolERC20.sol`, `src/libraries/FixedPointMath.sol`  
**Date:** 2026-09-02  
**Test references:** `test/LiquidityPool.t.sol`, `test/LiquidityPoolFactory.t.sol`, `test/fuzz/`, `test/invariant/`, `test/attack/`  
**Style:** aligned with [`06-token-swap/doc/SWC-AUDIT-EN.md`](../../06-token-swap/doc/SWC-AUDIT-EN.md)

---

## Executive summary

| Status | Count |
|--------|-------|
| ✅ Mitigated / Not applicable | 33 |
| ⚠️ Informational (design / MEV / trust) | 3 |
| ❌ Vulnerable | 0 |

**Conclusion:** No exploitable SWC vulnerabilities in the v1 scope (single-asset ERC-20, no AMM swaps). Informational risks: MEV/ordering on public deposit/withdraw (mitigated with `minSharesOut` / `minAssetsOut` + lock time), donations to the pool (mitigated with explicit `totalAssets` accounting + `MINIMUM_LIQUIDITY`), and fee-on-transfer tokens, which are out of scope.

**Suite principles verified:**

| Principle | Status |
|-----------|--------|
| Custom errors (no `require` strings) | ✅ |
| Fixed pragma `0.8.24` | ✅ |
| CEI + `nonReentrant` on deposit/withdraw/accrueFees | ✅ + attack suite |
| Anti-inflation `MINIMUM_LIQUIDITY` → `address(0)` | ✅ + FirstDepositAttack |
| SafeERC20 (SWC-104) on transfers | ✅ |
| UD60x18 fee accrual (`accFeePerShare`) | ✅ + fuzz |
| Fuzz ≥ 1000 runs | ✅ `foundry.toml` |
| Solvency / locked LP / balance invariants | ✅ `test/invariant/` |

---

## Full matrix SWC-100 — SWC-136

| ID | Title | Applies | Status | Evidence in Liquidity Pool |
|----|-------|---------|--------|----------------------------|
| SWC-100 | Function Default Visibility | Yes | ✅ | Explicit visibility in contracts and libraries |
| SWC-101 | Integer Overflow and Underflow | Yes | ✅ | Solidity `0.8.24`; `FixedPointMath.mulDiv` with overflow check |
| SWC-102 | Outdated Compiler Version | Yes | ✅ | `pragma solidity 0.8.24` + `foundry.toml` |
| SWC-103 | Floating Pragma | Yes | ✅ | Exact pragma (no `^`) |
| SWC-104 | Unchecked Call Return Value | Yes | ✅ | OZ `SafeERC20.safeTransfer` / `safeTransferFrom` |
| SWC-105 | Unprotected Ether Withdrawal | No | N/A | No ETH / `payable` / `.call{value}` |
| SWC-106 | Unprotected SELFDESTRUCT | No | N/A | No `selfdestruct` |
| SWC-107 | Reentrancy | Yes | ✅ | `nonReentrant` + CEI; `test/attack/ReentrancyAttack.t.sol` |
| SWC-108 | State Variable Default Visibility | Yes | ✅ | State with explicit visibility (`public` / `immutable`) |
| SWC-109 | Uninitialized Storage Pointer | No | N/A | No legacy storage pointers |
| SWC-110 | Assert Violation | No | N/A | No production `assert` |
| SWC-111 | Deprecated Solidity Functions | Yes | ✅ | No `suicide` / `throw` / `tx.origin` |
| SWC-112 | Delegatecall to Untrusted Callee | No | N/A | No `delegatecall` |
| SWC-113 | DoS with Failed Call | Partial | ✅ | A failed ERC-20 transfer reverts the whole deposit/withdraw |
| SWC-114 | Transaction Order Dependence | Yes | ⚠️ | Deposit/withdraw front-running (MEV); slippage params |
| SWC-115 | Authorization through tx.origin | No | N/A | No `tx.origin` |
| SWC-116 | Block values as a proxy for time | Yes | ✅ | `lockUntil` uses `block.timestamp` (explicit lock design) |
| SWC-117 | Signature Malleability | No | N/A | No signatures / `ecrecover` / permit |
| SWC-118 | Incorrect Constructor Name | No | N/A | 0.8+ `constructor` |
| SWC-119 | Shadowing State Variables | Yes | ✅ | No state shadowing |
| SWC-120 | Weak Sources of Randomness | No | N/A | No RNG |
| SWC-121 | Missing Protection against Signature Replay | No | N/A | No signatures |
| SWC-122 | Lack of Proper Signature Verification | No | N/A | No signature verification |
| SWC-123 | Requirement Violation | Yes | ✅ | Custom errors + unit/fuzz/invariant/attack |
| SWC-124 | Write to Arbitrary Storage Location | No | N/A | No arbitrary storage assembly |
| SWC-125 | Incorrect Inheritance Order | Yes | ✅ | `ILiquidityPool, LiquidityPoolERC20, ReentrancyGuard` |
| SWC-126 | Insufficient Gas Griefing | No | N/A | No relayers with a fixed stipend |
| SWC-127 | Arbitrary Jump with Function Type Variable | No | N/A | No dynamic function types |
| SWC-128 | DoS With Block Gas Limit | Partial | ✅ | No user-driven loops; O(1) operations |
| SWC-129 | Typographical Error | Yes | ✅ | Review + `forge build` / tests |
| SWC-130 | Right-To-Left-Override | No | N/A | ASCII |
| SWC-131 | Presence of unused variables | Yes | ✅ | No material dead code |
| SWC-132 | Unexpected Ether balance | No | N/A | Contracts don't handle ETH |
| SWC-133 | Hash Collisions (var-length args) | No | N/A | No custom multi-dynamic hashing |
| SWC-134 | Message call with hardcoded gas | No | N/A | No `{gas: …}` |
| SWC-135 | Code With No Effects | No | N/A | No relevant no-ops |
| SWC-136 | Unencrypted Private Data On-Chain | Partial | ✅ | `totalAssets`, shares, and fees are public by design |

---

## Informational risks

### SWC-114 — MEV and transaction ordering

A bot can front-run deposits/withdrawals and change the share price between `preview*` and the user's transaction.

**Product mitigation:** `minSharesOut` / `minAssetsOut` (`SlippageExceeded`); `lockDuration` reduces short-term flash manipulation.

### Residual donation / inflation attack

Tokens sent directly to the pool without a sync don't change `totalAssets` (explicit accounting). After `accrueFees(0)`, the share price rises for **all** existing LPs; `MINIMUM_LIQUIDITY` prevents the next depositor from being diluted to zero.

**Mitigation:** locked `MINIMUM_LIQUIDITY`; `test/attack/FirstDepositAttack.t.sol`; invariant `balanceOf(address(0)) == 1000`.

### Centralization / trust

| Topic | Risk | v1 handling |
|-------|------|-------------|
| Single factory | Malicious pools outside the suite | Use a known deployed factory |
| Fixed lock duration | Deployment parameter | Immutable in factory/pool |
| Fee-on-transfer tokens | Incorrect accounting | Out of v1 scope; standard ERC-20 only |
| Fees before the first deposit | Held in reserve until there are LPs | Documented; `accrueFees` pending |

---

## Monorepo principles checklist

| Principle | Met? | Notes |
|-----------|------|-------|
| Custom errors | ✅ | `ZeroLiquidity`, `SlippageExceeded`, `InvalidRatio`, `LockTimeNotExpired`, … |
| ReentrancyGuard (OZ) | ✅ | deposit / withdraw / accrueFees |
| SafeERC20 | ✅ | Custom `SafeTransfer` (Phase 8, SWC-104 bubble-revert) |
| MINIMUM_LIQUIDITY anti-inflation | ✅ | 1000 wei → `address(0)` |
| UD60x18 fee accrual | ✅ | `FixedPointMath.accrueFeePerShare` |
| NatSpec on public/external | ✅ | Phase 8 |
| Fuzz ≥ 1000 runs | ✅ | `test/fuzz/LiquidityPool.fuzz.t.sol` |
| Solvency / LP invariants | ✅ | `test/invariant/` |
| Gas baseline | ✅ | `doc/GAS-EN.md` + `.gas-snapshot` |

---

## SWC → test mapping

| SWC | Test(s) |
|-----|---------|
| SWC-101 | `testFuzz_deposit_*`, `testFuzz_withdraw_*`, `testFuzz_roundTrip_*`, `FixedPointMath.mulDiv` overflow |
| SWC-103 | Fixed compiler (build) |
| SWC-104 | Deposit/withdraw unit tests; `SafeTransfer` bubble-revert |
| SWC-107 | `test_Attack_reenterDeposit_*`, `test_Attack_reenterWithdraw_*`, `test_Attack_reenterAccrueFees_*` |
| SWC-114 | `testFuzz_deposit_revertsSlippage`; documented above |
| SWC-116 | `lockUntil` / `LockTimeNotExpired` unit tests |
| SWC-123 | Pool/Factory unit + fuzz + invariant + attack |
| Inflation | `test_Attack_inflation_*`, `invariant_minimumLiquidityLocked` |
| Solvency | `invariant_totalAssetsEqBalanceWhenSynced`, `invariant_fullConvertToAssetsLeTotalAssets` |

---

## References

- [SWC Registry](https://swcregistry.io/)
- [EIP-1470](https://eips.ethereum.org/EIPS/eip-1470)
- Module 06: [`06-token-swap/doc/SWC-AUDIT-EN.md`](../../06-token-swap/doc/SWC-AUDIT-EN.md)
- Plan: [`PLANIFICACION-EN.md`](./PLANIFICACION-EN.md)
