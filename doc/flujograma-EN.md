# Project Flowchart — Liquidity Pools & Fee Distribution

🌐 [Español](./flujograma-ES.md) · **English** · [Index](./README.md)

**To-be** operational flowchart (v1): setup → deposit → fees → withdrawal → security → TDD.

## 1. System master flowchart

```mermaid
flowchart TB
    subgraph SETUP["PHASE 0 — Setup"]
        S1[Initialize Foundry 0.8.24] --> S2[Deploy LiquidityPoolFactory]
        S2 --> S3[createPool underlying]
        S3 --> S4[Deploy MockERC20 / underlying token]
    end

    subgraph DEP["PHASE 1 — LP deposit"]
        D1[LP approves underlying] --> D2{Deposit validations}
        D2 -->|assets == 0| Dx1[ZeroLiquidity]
        D2 -->|invalid ratio| Dx2[InvalidRatio]
        D2 -->|OK first| D3[shares = assets - 1000]
        D2 -->|OK later| D4[convertToShares UD60x18]
        D3 --> D5[Mint 1000 → address 0]
        D4 --> D6{shares >= minSharesOut?}
        D5 --> D6
        D6 -->|No| Dx3[SlippageExceeded]
        D6 -->|Yes| D7[Effects: _mint + totalAssets + lockUntil]
        D7 --> D8[Interaction: transferFrom]
        D8 --> D9[Emit Deposit]
    end

    subgraph BRANCH["PHASE 2 — Pool usage"]
        B1{What happens?}
        B1 -->|Fees| F1
        B1 -->|Withdrawal| W1
        B1 -->|New deposit| D1
    end

    subgraph FEES["PHASE 2a — Fee distribution"]
        F1[Fee enters the pool] --> F2[_syncTotalAssets]
        F2 --> F3{totalSupply > 0?}
        F3 -->|No| F4[Fees held in reserve<br/>pending LPs]
        F3 -->|Yes| F5[accFeePerShare += fee * 1e18 / supply]
        F5 --> F6[Share price ↑ for every LP]
        F4 --> F7[Emit FeesAccrued]
        F6 --> F7
    end

    subgraph WITHDRAW["PHASE 2b — Withdrawal"]
        W1[LP calls withdraw] --> W2{lockUntil expired?}
        W2 -->|No| Wx1[LockTimeNotExpired]
        W2 -->|Yes| W3[convertToAssets UD60x18]
        W3 --> W4{assetsOut >= minAssetsOut?}
        W4 -->|No| Wx2[SlippageExceeded]
        W4 -->|Yes| W5[Effects: _burn + totalAssets -=]
        W5 --> W6[Interaction: transfer → to]
        W6 --> W7[Emit Withdraw]
    end

    SETUP --> DEP
    DEP --> BRANCH
    BRANCH --> FEES
    BRANCH --> WITHDRAW
    FEES --> END1([Active pool — LPs benefit])
    WITHDRAW --> END1
    DEP --> END1
```

## 2. Detailed UD60x18 flowchart (share conversion)

```mermaid
flowchart TD
    Start([Input: assets or shares]) --> Mode{Mode}
    Mode -->|Deposit| A1[assets > 0?]
    Mode -->|Withdraw| B1[shares > 0?]
    A1 -->|No| Fail1[ZeroLiquidity]
    B1 -->|No| Fail1
    A1 -->|Yes| A2{totalSupply == 0?}
    A2 -->|Yes| A3[shares = assets - MINIMUM_LIQUIDITY]
    A2 -->|No| A4[shares = assets * supply / totalAssets<br/>UD60x18 mulDiv]
    B1 -->|Yes| B2[assetsOut = shares * totalAssets / supply<br/>UD60x18 mulDiv]
    A3 --> Check{Result > 0<br/>and within slippage?}
    A4 --> Check
    B2 --> Check
    Check -->|No| Fail2[SlippageExceeded / ZeroLiquidity]
    Check -->|Yes| Ok([Proceed to CEI Effects])
```

## 3. Security flowchart (reentrancy + CEI)

```mermaid
flowchart TD
    A[Attacker calls deposit/withdraw] --> B[nonReentrant: status = ENTERED]
    B --> C[Checks: amounts, lock, slippage, ratio]
    C --> D[Effects: _mint or _burn<br/>totalAssets updated]
    D --> E{Malicious token<br/>reenters in a callback?}
    E -->|Yes| F[Second deposit/withdraw call]
    F --> G{status == ENTERED?}
    G -->|Yes| H[Revert ReentrancyGuard]
    G -->|No| I[Should never happen]
    E -->|No| J[Interaction: SafeERC20 transfer]
    H --> K([Attack failed — LP/reserves consistent])
    J --> L([Transaction OK])
```

## 4. First-deposit attack flowchart

```mermaid
flowchart TD
    A([Attack scenario]) --> B[Attacker: minimal first deposit]
    B --> C[1000 wei LP locked → address 0]
    C --> D[Attacker tries to inflate the share price<br/>by donating underlying without minting]
    D --> E[Second LP deposits a significant amount]
    E --> F{Does the second LP receive<br/>fair proportional shares?}
    F -->|No — attack succeeded| G[FAIL: adjust MINIMUM_LIQUIDITY / sync]
    F -->|Yes| H[PASS: FirstDepositAttack.t.sol]
    H --> I([Pool safe for multiple users])
```

## 5. Development pipeline flowchart (TDD)

```mermaid
flowchart LR
    A[.cursorrules] --> B[Planning docs]
    B --> C[Red .t.sol tests]
    C --> D[FixedPointMath UD60x18]
    D --> E[deposit + MINIMUM_LIQUIDITY]
    E --> F[withdraw + lock time + slippage]
    F --> G[accrueFees + share price]
    G --> H[LiquidityPoolFactory]
    H --> I[Fuzz + Invariant 1000]
    I --> J[FirstDepositAttack tests]
    J --> K[Gas + NatSpec + SafeERC20]
    K --> L([Module closed])
```

## 6. Flow ↔ function ↔ invariant matrix

| Flowchart step | Function | Invariant |
|----------------|----------|-----------|
| Create pool | `Factory.createPool` | One pool per `underlying` |
| First deposit | `deposit` | `totalSupply = assets - 1000`; 1000 LP locked |
| Later deposit | `deposit` | shares ∝ `assets * supply / totalAssets` |
| Pre-withdraw | `withdraw` | `block.timestamp >= lockUntil[sender]` |
| Post-withdraw | `withdraw` | `totalAssets -= assetsOut`; supply ↓ |
| Fee accrual | `accrueFees` / sync | `accFeePerShare` ↑; share price ↑ |
| Deposit slippage | `deposit` | `shares >= minSharesOut` |
| Withdraw slippage | `withdraw` | `assetsOut >= minAssetsOut` |
| Invalid ratio | `deposit` | `InvalidRatio` if the constraint is not met |
| Invariant suite | Handler | `totalAssets >= convertToAssets(totalSupply)` |
| Reentry | guard | the second call reverts |
| First-deposit attack | test | the second LP doesn't lose more than the fuzz tolerance |

## 7. Multi-user flowchart (share dilution)

```mermaid
flowchart TD
    U1[LP1 deposits A1] --> U2[supply = S1, totalAssets = A1]
    U2 --> U3[Fees come in: +F]
    U3 --> U4[share price = totalAssets / supply ↑]
    U4 --> U5[LP2 deposits A2]
    U5 --> U6[LP2 receives shares = A2 * S1 / totalAssets<br/>pro-rata at the current price]
    U6 --> U7[LP1 keeps ownership<br/>of A1 + part of F]
    U7 --> U8{Invariant: total withdrawable<br/>≤ totalAssets?}
    U8 -->|Yes| U9([Fair dilution verified])
    U8 -->|No| U10([Invariant test FAIL])
```

## 8. How to read these diagrams

1. **Setup → Deposit**: the pool starts empty; the first deposit sets the initial ratio with an anti-inflation offset (`1000` wei locked).
2. **Branch**: fees (benefit LPs through the share price) or withdrawal (with lock time and slippage).
3. **UD60x18**: every shares ↔ assets conversion and fee accumulation uses fixed point to avoid drift.
4. **CEI**: mint/burn always happens before transfers — critical for reentrancy.
5. **TDD pipeline**: red tests → implementation → fuzz/invariant/attack → module closed.
