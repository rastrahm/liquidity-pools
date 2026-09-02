# Diagrama de flujo — Liquidity Pools & Fee Distribution

Flujos de negocio **to-be** (v1). Ver también [flujograma.md](./flujograma.md) y [PLANIFICACION.md](./PLANIFICACION.md).

## 1. Ciclo de vida del pool

```mermaid
flowchart TD
    Start([Inicio]) --> DeployF[Deploy LiquidityPoolFactory]
    DeployF --> Create[createPool underlying]
    Create --> PoolReady[Pool listo — totalAssets = 0]

    PoolReady --> LPAction{Acción LP}
    LPAction -->|deposit| Deposit[Depositar underlying → LP]
    LPAction -->|withdraw| Withdraw[Quemar LP → underlying]

    PoolReady --> FeeAction{Acción fees}
    FeeAction -->|transfer / accrueFees| Accrue[Acumular fees al pool]

    Deposit --> Active[totalAssets > 0<br/>LP en circulación]
    Withdraw --> Active
    Accrue --> Active
    Active -.->|sigue operable| PoolReady
```

## 2. Flujo de deposit (primer depósito vs subsequent)

```mermaid
flowchart TD
    A([LP llama deposit assets, to, minSharesOut]) --> B[nonReentrant ON]
    B --> C{assets > 0?}
    C -->|No| E1[Revert ZeroLiquidity]
    C -->|Sí| D{totalSupply == 0?}
    D -->|Sí — primer depósito| F[shares = assets - MINIMUM_LIQUIDITY]
    F --> G[Mint MINIMUM_LIQUIDITY → address 0]
    D -->|No| H[shares = FixedPointMath.convertToShares<br/>assets, supply, totalAssets]
    G --> I{shares >= minSharesOut<br/>y shares > 0?}
    H --> I
    I -->|No| E2[Revert SlippageExceeded / ZeroLiquidity]
    I -->|Sí| J[Effects: _mint LP → to]
    J --> K[totalAssets += assets]
    K --> L[lockUntil to = now + lockDuration]
    L --> M[Interactions: SafeERC20.transferFrom]
    M --> N[Emit Deposit]
    N --> O[nonReentrant OFF]
    O --> P([LP recibe shares])
```

## 3. Flujo de withdraw

```mermaid
flowchart TD
    A([LP llama withdraw shares, to, minAssetsOut]) --> B[nonReentrant ON]
    B --> C{shares > 0?}
    C -->|No| E1[Revert ZeroLiquidity]
    C -->|Sí| D{block.timestamp >= lockUntil msg.sender?}
    D -->|No| E2[Revert LockTimeNotExpired]
    D -->|Sí| E[assetsOut = convertToAssets<br/>shares, supply, totalAssets]
    E --> F{assetsOut >= minAssetsOut<br/>y assetsOut > 0?}
    F -->|No| E3[Revert SlippageExceeded / ZeroLiquidity]
    F -->|Sí| G[Effects: _burn LP de msg.sender]
    G --> H[totalAssets -= assetsOut]
    H --> I[Interactions: SafeERC20.transfer → to]
    I --> J[Emit Withdraw]
    J --> K[nonReentrant OFF]
    K --> L([LP recibe underlying])
```

## 4. Flujo de acumulación de fees

```mermaid
flowchart TD
    A([Fee entra al pool<br/>transfer directo o accrueFees]) --> B[_syncTotalAssets:<br/>totalAssets = balance underlying]
    B --> C{feeDelta > 0?}
    C -->|No| D[Sin cambio en accFeePerShare]
    C -->|Sí| E{totalSupply > 0?}
    E -->|No| F[Fees quedan en pool<br/>sin distribuir aún]
    E -->|Sí| G[accFeePerShare +=<br/>feeDelta * 1e18 / totalSupply]
    G --> H[Share price sube:<br/>totalAssets / totalSupply ↑]
    D --> I[Emit FeesAccrued]
    F --> I
    H --> I
    I --> J([LPs existentes enriquecidos<br/>proporcionalmente])
```

## 5. Flujo preview (view — sin estado)

```mermaid
flowchart TD
    A([Usuario consulta previewDeposit / previewWithdraw]) --> B{Operación}
    B -->|previewDeposit| C[Leer totalAssets + totalSupply]
    B -->|previewWithdraw| C
    C --> D{Aplicar accFeePerShare<br/>y balance actual}
    D --> E[FixedPointMath.convertToShares o convertToAssets]
    E --> F([Retornar estimación<br/>sin modificar estado])
```

## 6. Flujo anti-inflation (primer depósito)

```mermaid
flowchart TD
    A([Atacante intenta manipular<br/>share price antes del 2.º LP]) --> B{¿Primer depósito?}
    B -->|Sí| C[Pool mintea shares - 1000 al LP]
    C --> D[1000 wei LP → address 0<br/>permanentemente locked]
    D --> E[Ratio shares/assets congelado<br/>con offset mínimo]
    B -->|No| F[Pro-rata estándar<br/>convertToShares]
    E --> G{Atacante dona tokens<br/>al pool sin mint?}
    G -->|Sí| H[Donación beneficia a todos los LPs<br/>no permite robar shares baratas]
    G -->|No| I[Flujo normal]
    H --> J([Segundo LP recibe shares justas<br/>FirstDepositAttack test OK])
    F --> J
    I --> J
```

## Leyenda

| Símbolo | Significado |
|---------|-------------|
| Rectángulo | Proceso / acción on-chain |
| Diamante | Decisión / validación |
| Óvalo | Inicio / fin |
| Flecha punteada | Estado persistente del pool |

## Orden CEI (deposit / withdraw)

| Paso | Deposit | Withdraw |
|------|---------|----------|
| **Checks** | assets > 0, ratio, slippage | shares > 0, lock time, slippage |
| **Effects** | `_mint`, `totalAssets +=`, `lockUntil` | `_burn`, `totalAssets -=` |
| **Interactions** | `transferFrom` underlying | `transfer` underlying |
