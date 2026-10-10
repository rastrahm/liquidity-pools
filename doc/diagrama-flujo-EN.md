# Flow Diagram — Liquidity Pools & Fee Distribution

🌐 [Español](./diagrama-flujo-ES.md) · **English** · [Index](./README.md)

**To-be** business flows (v1). See also [flujograma-EN.md](./flujograma-EN.md) and [PLANIFICACION-EN.md](./PLANIFICACION-EN.md).

## 1. Pool lifecycle

```mermaid
flowchart TD
    Start([Start]) --> DeployF[Deploy LiquidityPoolFactory]
    DeployF --> Create[createPool underlying]
    Create --> PoolReady[Pool ready — totalAssets = 0]

    PoolReady --> LPAction{LP action}
    LPAction -->|deposit| Deposit[Deposit underlying → LP]
    LPAction -->|withdraw| Withdraw[Burn LP → underlying]

    PoolReady --> FeeAction{Fee action}
    FeeAction -->|transfer / accrueFees| Accrue[Accrue fees into the pool]

    Deposit --> Active[totalAssets > 0<br/>LP in circulation]
    Withdraw --> Active
    Accrue --> Active
    Active -.->|still operational| PoolReady
```

## 2. Deposit flow (first deposit vs later deposits)

```mermaid
flowchart TD
    A([LP calls deposit assets, to, minSharesOut]) --> B[nonReentrant ON]
    B --> C{assets > 0?}
    C -->|No| E1[Revert ZeroLiquidity]
    C -->|Yes| D{totalSupply == 0?}
    D -->|Yes — first deposit| F[shares = assets - MINIMUM_LIQUIDITY]
    F --> G[Mint MINIMUM_LIQUIDITY → address 0]
    D -->|No| H[shares = FixedPointMath.convertToShares<br/>assets, supply, totalAssets]
    G --> I{shares >= minSharesOut<br/>and shares > 0?}
    H --> I
    I -->|No| E2[Revert SlippageExceeded / ZeroLiquidity]
    I -->|Yes| J[Effects: _mint LP → to]
    J --> K[totalAssets += assets]
    K --> L[lockUntil to = now + lockDuration]
    L --> M[Interactions: SafeERC20.transferFrom]
    M --> N[Emit Deposit]
    N --> O[nonReentrant OFF]
    O --> P([LP receives shares])
```

## 3. Withdraw flow

```mermaid
flowchart TD
    A([LP calls withdraw shares, to, minAssetsOut]) --> B[nonReentrant ON]
    B --> C{shares > 0?}
    C -->|No| E1[Revert ZeroLiquidity]
    C -->|Yes| D{block.timestamp >= lockUntil msg.sender?}
    D -->|No| E2[Revert LockTimeNotExpired]
    D -->|Yes| E[assetsOut = convertToAssets<br/>shares, supply, totalAssets]
    E --> F{assetsOut >= minAssetsOut<br/>and assetsOut > 0?}
    F -->|No| E3[Revert SlippageExceeded / ZeroLiquidity]
    F -->|Yes| G[Effects: _burn LP from msg.sender]
    G --> H[totalAssets -= assetsOut]
    H --> I[Interactions: SafeERC20.transfer → to]
    I --> J[Emit Withdraw]
    J --> K[nonReentrant OFF]
    K --> L([LP receives underlying])
```

## 4. Fee accrual flow

```mermaid
flowchart TD
    A([Fee enters the pool<br/>direct transfer or accrueFees]) --> B[_syncTotalAssets:<br/>totalAssets = underlying balance]
    B --> C{feeDelta > 0?}
    C -->|No| D[No change to accFeePerShare]
    C -->|Yes| E{totalSupply > 0?}
    E -->|No| F[Fees stay in the pool<br/>not yet distributed]
    E -->|Yes| G[accFeePerShare +=<br/>feeDelta * 1e18 / totalSupply]
    G --> H[Share price rises:<br/>totalAssets / totalSupply ↑]
    D --> I[Emit FeesAccrued]
    F --> I
    H --> I
    I --> J([Existing LPs benefit<br/>proportionally])
```

## 5. Preview flow (view — no state change)

```mermaid
flowchart TD
    A([User calls previewDeposit / previewWithdraw]) --> B{Operation}
    B -->|previewDeposit| C[Read totalAssets + totalSupply]
    B -->|previewWithdraw| C
    C --> D{Apply accFeePerShare<br/>and current balance}
    D --> E[FixedPointMath.convertToShares or convertToAssets]
    E --> F([Return estimate<br/>without changing state])
```

## 6. Anti-inflation flow (first deposit)

```mermaid
flowchart TD
    A([Attacker tries to manipulate<br/>share price before the 2nd LP]) --> B{First deposit?}
    B -->|Yes| C[Pool mints shares - 1000 to the LP]
    C --> D[1000 wei LP → address 0<br/>permanently locked]
    D --> E[Shares/assets ratio frozen<br/>with a minimum offset]
    B -->|No| F[Standard pro-rata<br/>convertToShares]
    E --> G{Attacker donates tokens<br/>to the pool without minting?}
    G -->|Yes| H[Donation benefits every LP<br/>no cheap shares to steal]
    G -->|No| I[Normal flow]
    H --> J([Second LP receives fair shares<br/>FirstDepositAttack test OK])
    F --> J
    I --> J
```

## Legend

| Symbol | Meaning |
|--------|---------|
| Rectangle | On-chain process / action |
| Diamond | Decision / validation |
| Oval | Start / end |
| Dotted arrow | Persistent pool state |

## CEI order (deposit / withdraw)

| Step | Deposit | Withdraw |
|------|---------|----------|
| **Checks** | assets > 0, ratio, slippage | shares > 0, lock time, slippage |
| **Effects** | `_mint`, `totalAssets +=`, `lockUntil` | `_burn`, `totalAssets -=` |
| **Interactions** | underlying `transferFrom` | underlying `transfer` |
