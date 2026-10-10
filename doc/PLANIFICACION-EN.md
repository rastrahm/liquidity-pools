# Planning — Module 07: Liquidity Pools & Fee Distribution

🌐 [Español](./PLANIFICACION-ES.md) · **English** · [Index](./README.md)

**Status:** Phase **8** ✅ — gas snapshot + NatSpec + SafeTransfer (module closed).

## 1. Project goal

A **liquidity pool tokenization** engine with proportional fee distribution, dynamic deposit/withdrawal accounting, and mathematical protections against inflation attacks (flash loans), built with Foundry and Solidity `0.8.24`.

### Main capabilities

- Minting and burning of **LP tokens** (internal ERC-20) tied to the reserve/share ratio.
- **Deposits and withdrawals** with slippage protection (`SlippageExceeded`).
- **Proportional distribution of fees** accumulated in the pool using fixed-point math (`UD60x18`).
- **Anti-inflation attack:** `1000` wei of LP burned to `address(0)` on the first liquidity provision.
- Optional per-deposit **lock time** to mitigate short-term manipulation.
- Security: **CEI**, **ReentrancyGuard**, **custom errors**, safe transfers (SafeERC20).

---

## 2. Scope

### Included

| Area | Description |
|------|-------------|
| LiquidityPool | Main pool: deposit, withdraw, accrue fees, mint/burn LP |
| LP ERC-20 | Internal implementation; shares ∝ ownership of reserves + fees |
| Fee accounting | Accumulation and proportional distribution via `UD60x18` (share price) |
| Anti-inflation | `MINIMUM_LIQUIDITY = 1000` wei burned to `address(0)` on the first deposit |
| Lock time | Per-position unlock timestamp; `LockTimeNotExpired` |
| Ratio guard | Ratio validation on multi-asset deposits; `InvalidRatio` |
| Slippage | `minSharesOut` / `minAmountOut` on deposit/withdraw |
| Security | CEI (mint/burn before transfers), `nonReentrant`, SafeERC20 |
| Tests | Unit, fuzz, invariant, first-deposit attack, multi-user dilution |

### Not included (v1)

- AMM swaps / constant product (covered in module 06).
- Concentrated liquidity / ticks.
- On-chain governance of fee parameters.
- Next.js frontend (optional in a later phase).
- Chainlink / external oracle integration.
- Flash loan callbacks as a product feature.

---

## 3. Tech stack

| Component | Choice |
|-----------|--------|
| Compiler | `pragma solidity 0.8.24;` (exact, no floating pragma) |
| Framework | Foundry (`forge test`, fuzz ≥ 1000, invariant testing) |
| Libraries | OpenZeppelin Contracts v5.x (ERC20, SafeERC20, ReentrancyGuard), Solmate (optional, for gas) |
| Math | `UD60x18` fixed point for fees and share ratios |
| Transfers | SafeERC20; ETH via `.call{value}` where applicable |
| Documentation | NatSpec on every public/external API |

---

## 4. Architecture

```
07-liquidity-pools/
├── doc/                                    # Design documentation (-ES / -EN)
│   ├── README.md                           # Bilingual index
│   ├── PLANIFICACION-EN.md
│   ├── diagrama-clases-EN.md
│   ├── diagrama-flujo-EN.md
│   └── flujograma-EN.md
├── src/
│   ├── LiquidityPool.sol                   # Core pool: deposit/withdraw/fees/LP
│   ├── LiquidityPoolFactory.sol            # Deploys one pool per underlying asset
│   ├── interfaces/
│   │   ├── ILiquidityPool.sol
│   │   └── ILiquidityPoolFactory.sol
│   ├── libraries/
│   │   └── FixedPointMath.sol              # UD60x18: shares, fees, ratios
│   └── mocks/
│       └── MockERC20.sol
├── test/
│   ├── LiquidityPool.t.sol                 # Unit: deposit/withdraw/fees/edge cases
│   ├── LiquidityPoolFactory.t.sol
│   ├── fuzz/LiquidityPool.fuzz.t.sol       # Amounts + slippage with bound()
│   ├── invariant/LiquidityPool.invariant.t.sol
│   └── attack/FirstDepositAttack.t.sol     # Donation / inflation attack
├── script/
│   └── Deploy.s.sol
├── foundry.toml
└── remappings.txt
```

### Roles

| Actor | Responsibility |
|-------|----------------|
| **LP (Liquidity Provider)** | Deposits the underlying asset → receives LP; burns LP → withdraws a proportional amount |
| **Fee depositor** | Sends fees to the pool (direct transfer or `accrueFees`) → benefits every LP through the share price |
| **LiquidityPool** | Holds reserves, mints/burns LP, distributes fees proportionally |
| **Factory** | Creates one unique pool per underlying token (or token pair in v2) |
| **Attacker (test)** | Simulates a donation/inflation attack → must fail once the guard is in place |

---

## 5. Data model

```solidity
// LiquidityPool (state summary)
address public immutable underlying;       // ERC-20 held by the pool (v1: single-asset)
uint256 public totalAssets;              // Accounted reserves (includes accumulated fees)
uint256 public accFeePerShare;           // UD60x18 accumulator per LP share
uint256 public constant MINIMUM_LIQUIDITY = 1000;

mapping(address => uint256) public lockUntil;  // Unlock timestamp per LP
// + LP totalSupply / balances (internal ERC-20)
```

### Key formulas

| Operation | Formula |
|-----------|---------|
| First deposit | `shares = assets - MINIMUM_LIQUIDITY`; mint `MINIMUM_LIQUIDITY` → `address(0)` |
| Later deposit | `shares = assets * totalSupply / totalAssets` |
| Withdrawal | `assetsOut = shares * totalAssets / totalSupply` |
| Fee accrual | `accFeePerShare += feeAmount * 1e18 / totalSupply` (UD60x18) |
| Share price | `totalAssets / totalSupply` (rises when fees come in) |

---

## 6. On-chain API (LiquidityPool)

| Function | Visibility | Description |
|----------|------------|-------------|
| `deposit(uint256 assets, address to, uint256 minSharesOut)` | external nonReentrant | Deposits underlying → mints LP to `to` |
| `withdraw(uint256 shares, address to, uint256 minAssetsOut)` | external nonReentrant | Burns LP → transfers underlying to `to` |
| `previewDeposit(uint256 assets)` | view | Estimated shares (includes accumulated fees) |
| `previewWithdraw(uint256 shares)` | view | Estimated assets on withdrawal |
| `totalAssets()` | view | Total accounted reserves |
| `accrueFees(uint256 amount)` | external | Records explicit fees (optional if fees arrive by transfer) |
| `lockUntil(address)` | view | LP unlock timestamp |

### Custom errors (required)

| Error | Condition |
|-------|-----------|
| `ZeroLiquidity()` | Deposit/withdrawal with amount 0, or resulting shares equal 0 |
| `SlippageExceeded()` | Shares/assets received < expected minimum |
| `InvalidRatio()` | Deposit ratio doesn't meet the pool constraint |
| `LockTimeNotExpired()` | Withdrawal before `lockUntil[msg.sender]` |

### Events

`Deposit` · `Withdraw` · `FeesAccrued` · `PoolCreated` (Factory)

---

## 7. Deposit logic (CEI + anti-inflation)

1. Validate `assets > 0` and the ratio (if applicable) → otherwise `ZeroLiquidity` / `InvalidRatio`.
2. Compute `shares` via `FixedPointMath` (first deposit vs later deposits).
3. Validate `shares >= minSharesOut` → otherwise `SlippageExceeded`.
4. **Effects:** `_mint(to, shares)` (and burn `MINIMUM_LIQUIDITY` on the first deposit).
5. Update `totalAssets` and `lockUntil[to]` where applicable.
6. **Interactions:** `SafeERC20.transferFrom(msg.sender, address(this), assets)`.
7. Emit `Deposit`.

---

## 8. Implementation phases (TDD)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| **0** | Foundry scaffold + docs + interfaces | ✅ |
| **1** | Failing tests: deposit / withdraw / reverts | ✅ |
| **2** | `FixedPointMath` (UD60x18) + `LiquidityPool` skeleton | ✅ |
| **3** | `deposit` + MINIMUM_LIQUIDITY + anti-inflation | ✅ |
| **4** | `withdraw` + slippage + lock time | ✅ |
| **5** | Proportional fee accrual (`accFeePerShare`) | ✅ |
| **6** | `LiquidityPoolFactory` + deploy script | ✅ |
| **7** | Fuzz + invariant + FirstDepositAttack tests | ✅ |
| **8** | Gas snapshot + NatSpec + SafeERC20 hardening | ✅ |

---

## 9. Test plan

| Suite | Location | Coverage |
|-------|----------|----------|
| Unit | `test/LiquidityPool.t.sol` | First vs later deposit, withdraw, fee share price |
| Factory | `test/LiquidityPoolFactory.t.sol` | One pool per underlying, `getPool` |
| Fuzz | `test/fuzz/LiquidityPool.fuzz.t.sol` | Amounts + slippage with `bound()` |
| Invariant | `test/invariant/LiquidityPool.invariant.t.sol` | `totalAssets >= sum(withdrawable)`; consistent shares |
| Attack | `test/attack/FirstDepositAttack.t.sol` | Donation/inflation doesn't drain later deposits |
| Edge | `test/LiquidityPool.t.sol` | Zero balance, multi-user dilution, lock time |

---

## 10. Acceptance criteria

- [x] Foundry scaffold (`0.8.24`, fuzz ≥ 1000)
- [x] TDD deposit / withdraw with red tests first
- [x] `MINIMUM_LIQUIDITY` (1000 wei) burned on the first deposit
- [x] Fee distribution via `UD60x18` with no critical rounding drift
- [x] CEI: mint/burn **before** ERC-20 transfers (deposit + withdraw)
- [x] Custom errors (no strings in `require`)
- [x] `ReentrancyGuard` on deposit/withdraw
- [x] First-deposit attack tests pass
- [x] Fuzz with `bound()` on amounts and slippage
- [x] Invariant: reserves stay balanced after random sequences
- [x] NatSpec on public/external functions
- [x] `vm.expectRevert` on every failure path
- [x] Gas baseline (`doc/GAS-EN.md` + `.gas-snapshot`)
- [x] Hardened `SafeTransfer` (SWC-104 bubble-revert)

---

## 11. Related documents

| Document | Contents |
|----------|----------|
| [diagrama-clases-EN.md](./diagrama-clases-EN.md) | Contract, library, and test UML |
| [diagrama-flujo-EN.md](./diagrama-flujo-EN.md) | Deposit/withdraw/fee accrual flows |
| [flujograma-EN.md](./flujograma-EN.md) | Operations + anti-inflation + TDD pipeline |
| [SWC-AUDIT-EN.md](./SWC-AUDIT-EN.md) | SWC-100–136 matrix + test mapping |
| [GAS-EN.md](./GAS-EN.md) | Gas baseline, optimizations, snapshot |

---

## 12. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| First-depositor inflation / donation attack | `MINIMUM_LIQUIDITY` locked at `address(0)` |
| Flash loan share price manipulation | Lock time + explicit `totalAssets` accounting |
| Reentrancy during ERC-20 transfer | CEI + `nonReentrant`; mint/burn before transfer |
| Rounding errors in fee payouts | `UD60x18` fixed point; edge-case tests with small amounts |
| Non-standard tokens | SafeERC20 with return value check |
| Slippage on volatile deposit/withdraw | `minSharesOut` / `minAssetsOut` + `SlippageExceeded` |
| Early withdrawal after deposit | `lockUntil` + `LockTimeNotExpired` |
| Disproportionate multi-user dilution | Dilution tests; pro-rata formulas verified by fuzzing |

---

## 13. Conventions (suite + Solidity rules)

- Fixed pragma `0.8.24`; layout: Interfaces → Libraries → Contracts → State → Events → Errors → Modifiers → Functions.
- NatSpec `@notice` / `@dev` / `@param` / `@return` on the public API.
- Tests first (TDD); `vm.expectRevert` on failure paths.
- Gas: `immutable`/`constant`, custom errors, packing where applicable.
- Relationship with module 06: the AMM swap lives in `06-token-swap`; this module focuses on **LP tokenization + fee distribution** as a reusable primitive.
