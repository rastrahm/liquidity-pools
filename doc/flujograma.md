# Flujograma del proyecto — Liquidity Pools & Fee Distribution

Flujograma operativo **to-be** (v1): setup → depósito → fees → retiro → seguridad → TDD.

## 1. Flujograma maestro del sistema

```mermaid
flowchart TB
    subgraph SETUP["FASE 0 — Setup"]
        S1[Inicializar Foundry 0.8.24] --> S2[Deploy LiquidityPoolFactory]
        S2 --> S3[createPool underlying]
        S3 --> S4[Deploy MockERC20 / token subyacente]
    end

    subgraph DEP["FASE 1 — Depósito LP"]
        D1[LP aprueba underlying] --> D2{Validaciones deposit}
        D2 -->|assets == 0| Dx1[ZeroLiquidity]
        D2 -->|ratio inválido| Dx2[InvalidRatio]
        D2 -->|OK primer| D3[shares = assets - 1000]
        D2 -->|OK later| D4[convertToShares UD60x18]
        D3 --> D5[Mint 1000 → address 0]
        D4 --> D6{shares >= minSharesOut?}
        D5 --> D6
        D6 -->|No| Dx3[SlippageExceeded]
        D6 -->|Sí| D7[Effects: _mint + totalAssets + lockUntil]
        D7 --> D8[Interaction: transferFrom]
        D8 --> D9[Emit Deposit]
    end

    subgraph BRANCH["FASE 2 — Uso del pool"]
        B1{¿Qué ocurre?}
        B1 -->|Fees| F1
        B1 -->|Retiro| W1
        B1 -->|Nuevo depósito| D1
    end

    subgraph FEES["FASE 2a — Fee distribution"]
        F1[Fee entra al pool] --> F2[_syncTotalAssets]
        F2 --> F3{totalSupply > 0?}
        F3 -->|No| F4[Fees en reserva<br/>pendientes de LPs]
        F3 -->|Sí| F5[accFeePerShare += fee * 1e18 / supply]
        F5 --> F6[Share price ↑ para todos los LPs]
        F4 --> F7[Emit FeesAccrued]
        F6 --> F7
    end

    subgraph WITHDRAW["FASE 2b — Retiro"]
        W1[LP llama withdraw] --> W2{lockUntil expirado?}
        W2 -->|No| Wx1[LockTimeNotExpired]
        W2 -->|Sí| W3[convertToAssets UD60x18]
        W3 --> W4{assetsOut >= minAssetsOut?}
        W4 -->|No| Wx2[SlippageExceeded]
        W4 -->|Sí| W5[Effects: _burn + totalAssets -=]
        W5 --> W6[Interaction: transfer → to]
        W6 --> W7[Emit Withdraw]
    end

    SETUP --> DEP
    DEP --> BRANCH
    BRANCH --> FEES
    BRANCH --> WITHDRAW
    FEES --> END1([Pool activo — LPs enriquecidos])
    WITHDRAW --> END1
    DEP --> END1
```

## 2. Flujograma detallado UD60x18 (conversión shares)

```mermaid
flowchart TD
    Start([Input: assets o shares]) --> Mode{Modo}
    Mode -->|Deposit| A1[assets > 0?]
    Mode -->|Withdraw| B1[shares > 0?]
    A1 -->|No| Fail1[ZeroLiquidity]
    B1 -->|No| Fail1
    A1 -->|Sí| A2{totalSupply == 0?}
    A2 -->|Sí| A3[shares = assets - MINIMUM_LIQUIDITY]
    A2 -->|No| A4[shares = assets * supply / totalAssets<br/>UD60x18 mulDiv]
    B1 -->|Sí| B2[assetsOut = shares * totalAssets / supply<br/>UD60x18 mulDiv]
    A3 --> Check{Resultado > 0<br/>y cumple slippage?}
    A4 --> Check
    B2 --> Check
    Check -->|No| Fail2[SlippageExceeded / ZeroLiquidity]
    Check -->|Sí| Ok([Proceder Effects CEI])
```

## 3. Flujograma de seguridad (reentrancy + CEI)

```mermaid
flowchart TD
    A[Atacante llama deposit/withdraw] --> B[nonReentrant: status = ENTERED]
    B --> C[Checks: amounts, lock, slippage, ratio]
    C --> D[Effects: _mint o _burn<br/>totalAssets actualizado]
    D --> E{Token malicioso<br/>reentra en callback?}
    E -->|Sí| F[Segunda llamada deposit/withdraw]
    F --> G{status == ENTERED?}
    G -->|Sí| H[Revert ReentrancyGuard]
    G -->|No| I[No debería ocurrir]
    E -->|No| J[Interaction: SafeERC20 transfer]
    H --> K([Ataque fallido — LP/reservas consistentes])
    J --> L([Transacción OK])
```

## 4. Flujograma anti first-deposit attack

```mermaid
flowchart TD
    A([Escenario de ataque]) --> B[Atacante: primer deposit mínimo]
    B --> C[1000 wei LP locked → address 0]
    C --> D[Atacante intenta inflar share price<br/>donando underlying sin mint]
    D --> E[Segundo LP deposita amount significativo]
    E --> F{¿Segundo LP recibe shares<br/>proporcionales justas?}
    F -->|No — ataque exitoso| G[FAIL: ajustar MINIMUM_LIQUIDITY / sync]
    F -->|Sí| H[PASS: FirstDepositAttack.t.sol]
    H --> I([Pool seguro para multi-user])
```

## 5. Flujograma del pipeline de desarrollo (TDD)

```mermaid
flowchart LR
    A[.cursorrules] --> B[Docs planificación]
    B --> C[Tests .t.sol rojos]
    C --> D[FixedPointMath UD60x18]
    D --> E[deposit + MINIMUM_LIQUIDITY]
    E --> F[withdraw + lock time + slippage]
    F --> G[accrueFees + share price]
    G --> H[LiquidityPoolFactory]
    H --> I[Fuzz + Invariant 1000]
    I --> J[FirstDepositAttack tests]
    J --> K[Gas + NatSpec + SafeERC20]
    K --> L([Módulo cerrado])
```

## 6. Matriz flujo ↔ función ↔ invariante

| Paso del flujograma | Función | Invariante |
|---------------------|---------|------------|
| Crear pool | `Factory.createPool` | Un pool por `underlying` |
| Primer deposit | `deposit` | `totalSupply = assets - 1000`; 1000 LP locked |
| Deposit posterior | `deposit` | shares ∝ `assets * supply / totalAssets` |
| Pre-withdraw | `withdraw` | `block.timestamp >= lockUntil[sender]` |
| Post-withdraw | `withdraw` | `totalAssets -= assetsOut`; supply ↓ |
| Fee accrual | `accrueFees` / sync | `accFeePerShare` ↑; share price ↑ |
| Slippage deposit | `deposit` | `shares >= minSharesOut` |
| Slippage withdraw | `withdraw` | `assetsOut >= minAssetsOut` |
| Ratio inválido | `deposit` | `InvalidRatio` si restricción incumplida |
| Invariant suite | Handler | `totalAssets >= convertToAssets(totalSupply)` |
| Reentrada | guard | segunda llamada revierte |
| First-deposit attack | test | segundo LP no pierde > tolerancia fuzz |

## 7. Flujograma multi-user (dilución de shares)

```mermaid
flowchart TD
    U1[LP1 deposita A1] --> U2[supply = S1, totalAssets = A1]
    U2 --> U3[Fees entran: +F]
    U3 --> U4[share price = totalAssets / supply ↑]
    U4 --> U5[LP2 deposita A2]
    U5 --> U6[LP2 recibe shares = A2 * S1 / totalAssets<br/>pro-rata al precio actual]
    U6 --> U7[LP1 mantiene participación<br/>en A1 + parte de F]
    U7 --> U8{Invariant: suma withdrawable<br/>≤ totalAssets?}
    U8 -->|Sí| U9([Dilución justa verificada])
    U8 -->|No| U10([FAIL invariant test])
```

## 8. Cómo leer estos diagramas

1. **Setup → Depósito**: el pool nace vacío; el primer depósito fija el ratio inicial con offset anti-inflation (`1000` wei locked).
2. **Branch**: fees (enriquecen LPs vía share price) o retiro (con lock time y slippage).
3. **UD60x18**: toda conversión shares ↔ assets y acumulación de fees usa punto fijo para evitar drift.
4. **CEI**: mint/burn siempre antes de transfers — crítico para reentrancy.
5. **TDD pipeline**: tests rojos → implementación → fuzz/invariant/attack → cierre del módulo.
