# Decisiones técnicas, lógica y gas — Module 07

Documento de lectura para entender **qué se decidió**, **cómo fluye el sistema** y **dónde aún se puede ahorrar gas**.

🌐 **Español** · [English](./DECISIONES-TECNICAS-EN.md) · [Índice](./README.md)

Complementa: [PLANIFICACION-ES.md](./PLANIFICACION-ES.md) · [GAS-ES.md](./GAS-ES.md) · [SWC-AUDIT-ES.md](./SWC-AUDIT-ES.md) · [diagrama-flujo-ES.md](./diagrama-flujo-ES.md)

---

## 1. Qué es este módulo (en una frase)

Un **vault de un solo ERC-20**: depositás underlying → recibís **LP shares**; los **fees** aumentan el share price; al retirar quemás shares y recuperás underlying (más fees si hubo accrual).

No es un AMM (`x · y = k`). Eso vive en el módulo 06.

```
Usuario ──deposit──► LiquidityPool ──custodia──► Underlying ERC-20
              │
              └── minta LP shares (ERC-20 interno)

Fees ──accrueFees──► totalAssets ↑ ──► más assets por share al withdraw
```

---

## 2. Decisiones técnicas

### 2.1 Arquitectura

| Decisión | Qué implica | Por qué |
|----------|-------------|---------|
| **Single-asset vault** | Un `underlying` por pool | Contabilidad O(1), sin packing multi-token; foco en fees + anti-inflation |
| **Factory + Pool** | `LiquidityPoolFactory.createPool(underlying)` | Varios pools sin redeploy de lógica; `lockDuration` fijo en factory |
| **LP ERC-20 propio** (`LiquidityPoolERC20`) | No hereda OZ ERC20 | OZ v5 **revierte** mint a `address(0)`; necesitamos quemar `MINIMUM_LIQUIDITY` ahí |
| **Contabilidad `totalAssets` explícita** | No usamos solo `balanceOf(pool)` como verdad | Donaciones directas **no** cambian share price hasta `accrueFees` |
| **Preview + slippage on-chain** | `previewDeposit` / `previewWithdraw` + `minSharesOut` / `minAssetsOut` | Mitiga MEV (SWC-114) entre estimación y tx |

### 2.2 Seguridad y modelo de amenazas

| Decisión | Detalle |
|----------|---------|
| **CEI** | Mint/burn y updates de estado **antes** de `safeTransfer` / `safeTransferFrom` |
| **`nonReentrant`** | En `deposit`, `withdraw`, `accrueFees` (defense in depth + tokens con callback) |
| **`MINIMUM_LIQUIDITY = 1000`** | Primer depósito: mint 1000 wei a `address(0)` y al usuario `assets - 1000` | Evita inflation attack del first depositor |
| **Lock time** | Cada depósito pone `lockUntil[to] = now + lockDuration` | Reduce churn / manipulación flash de corto plazo |
| **Custom errors** | `ZeroLiquidity`, `SlippageExceeded`, `LockTimeNotExpired`, … | Más barato y tipado que `require` con strings |
| **`SafeTransfer` propio** | Low-level `call` + bubble-revert (estilo Uniswap V2) | SWC-104; propaga errores custom del token (útil en tests de reentrancy) |
| **Pragma fijo `0.8.24`** | Sin `^` | SWC-103; overflow nativo de 0.8 |

### 2.3 Matemática de fees

| Decisión | Detalle |
|----------|---------|
| **Share price implícito** | `assets_por_share ≈ totalAssets / totalSupply` |
| **`accFeePerShare` (UD60x18)** | Acumulador: `+= feeDelta * 1e18 / totalSupply` | Precisión fija; no mint de shares nuevas al fee |
| **Conversión** | `shares = assets * supply / totalAssets` (post-primer depósito) | `FixedPointMath.mulDiv` con check de overflow |
| **Fees sin LPs** | Si `totalSupply == 0`, el delta queda en reserva | Se refleja al primer depósito vía `totalAssets` |

**Nota de diseño:** en este vault el LP **no** cobra un “pending fee” por cuenta. El beneficio es automático: al subir `totalAssets` sin subir (proporcionalmente) las shares del atacante vacío, **cada share vale más** al retirar.

### 2.4 Lo que quedó fuera de alcance (v1)

- Swaps / producto constante (módulo 06)
- Tokens fee-on-transfer / rebasing
- Gobernanza on-chain del fee o del lock
- Permit / firmas en el pool
- ETH nativo como underlying

---

## 3. Lógica que sigue el sistema

### 3.1 Ciclo de vida

1. Deploy `LiquidityPoolFactory(lockDuration)`.
2. `createPool(underlying)` → nuevo `LiquidityPool`.
3. Usuarios: `approve` → `deposit` / `withdraw` / `accrueFees`.

### 3.2 Primer depósito

```
assets > 1000
→ mint 1000 LP a address(0)     // locked para siempre
→ mint (assets - 1000) a `to`
→ totalAssets += assets
→ lockUntil[to] = now + lockDuration
→ transferFrom(user → pool, assets)
```

Si `assets <= 1000` → `ZeroLiquidity` (no se puede bootstrapar sin dejar liquidez mínima).

### 3.3 Depósitos siguientes

```
shares = assets * totalSupply / totalAssets
si shares < minSharesOut → SlippageExceeded
→ mint shares a `to`
→ totalAssets += assets
→ reinicia lockUntil[to]
→ transferFrom
```

### 3.4 Retiro

```
ahora >= lockUntil[msg.sender]  (si no → LockTimeNotExpired)
assets = shares * totalAssets / totalSupply
si assets < minAssetsOut → SlippageExceeded
→ burn shares de msg.sender
→ totalAssets -= assets
→ transfer(to, assets)
```

### 3.5 Accrual de fees

```
si amount > 0 → pull amount del caller
balance = underlying.balanceOf(pool)
si balance <= totalAssets → return (nada que sync)
feeDelta = balance - totalAssets
totalAssets = balance
si totalSupply > 0:
  accFeePerShare += feeDelta * 1e18 / totalSupply
emit FeesAccrued
```

Efecto para el LP: **mismas shares, más underlying al withdraw**.

### 3.6 Orden mental (CEI)

Siempre:

1. **Checks** (cero, lock, slippage)
2. **Effects** (mint/burn, `totalAssets`, `lockUntil`, `accFeePerShare`)
3. **Interactions** (transfer ERC-20)

---

## 4. ¿Se puede mejorar el gas de lo que existe?

Sí. El baseline actual es **sólido y legible** (Fase 8), no el mínimo absoluto. Abajo: mejoras realistas, ordenadas por impacto / riesgo.

Baseline (medianas, ver [GAS-ES.md](./GAS-ES.md)):

| Función | Mediana aprox. |
|---------|----------------|
| `deposit` | ~177k |
| `withdraw` | ~46k |
| `accrueFees` | ~69k |
| Deploy pool | ~1.0M |

### 4.1 Mejoras de alto valor / bajo riesgo relativo

| Idea | Qué ahorra | Costo / riesgo |
|------|------------|----------------|
| **Cachear `totalSupply` / `totalAssets` en locals** al inicio de `deposit`/`withdraw` | Menos SLOAD repetidos en convert + mint/burn | Cambio pequeño; re-testear fuzz/invariant |
| **`IERC20 private immutable _token`** además de `address immutable underlying` | Evita casts repetidos a `IERC20(underlying)` | +immutable; ligero bytecode |
| **Packing `name`/`symbol` o metadatos off-chain** | Deploy más barato (strings en storage cuestan) | Menos UX on-chain; o usar EIP-7201 / immutable hashes |
| **`optimizer_runs` más alto (p. ej. 1000–10000)** | Runtime más barato en hot path | Deploy más caro; medir con `forge snapshot` |
| **Eliminar storage de `accFeePerShare` si no se lee off-chain** | Un SSTORE menos en sync | Hoy es útil para indexers/UI; el share price ya está en `totalAssets/supply` |

### 4.2 Mejoras medias (tradeoff seguridad o claridad)

| Idea | Qué ahorra | Tradeoff |
|------|------------|----------|
| **Quitar `ReentrancyGuard` y confiar solo en CEI** | ~2.3k–5k gas de SLOAD/SSTORE del status + menos bytecode | Solo seguro si el underlying **nunca** hace callback (no ERC-777 / hooks). Hoy se mantiene por defensa |
| **OZ `SafeERC20` vs `SafeTransfer` propio** | Código estándar | Pierdes bubble-revert limpio de errores custom en algunos paths de test |
| **Transient storage (Cancun) para reentrancy flag** | Flag más barato que storage clásico | Requiere target chain con EIP-1153 |
| **No emitir eventos en paths internos** | Algo de gas | Peor observabilidad |

### 4.3 Mejoras agresivas (solo si el objetivo es “mínimo gas”)

| Idea | Nota |
|------|------|
| **Solmate / ERC20 minimal sin allowance infinite check branches** | Ya hay infinite allowance en LP ERC-20; se puede compactar más |
| **Assembly en `mulDiv`** (estilo Uniswap `FullMath`) | Más gas-eficiente en productos grandes; más superficie de bug |
| **Clone / minimal proxy (EIP-1167) en Factory** | `createPool` mucho más barato vs `new LiquidityPool` (~1M) | Cambia modelo de deploy y verificación |
| **SSTORE2 / immutable args para bytecode del pool** | Deploy factory más ligero | Complejidad alta |

### 4.4 Qué **no** conviene “optimizar” a ciegas

- Sacar `MINIMUM_LIQUIDITY` → reabre inflation attack.
- Usar solo `balanceOf` como `totalAssets` → donaciones / sync accidental cambian el ratio.
- Quitar `minSharesOut` / `minAssetsOut` → MEV sin freno.
- `unchecked` sin checks previos → SWC-101.

### 4.5 Cómo medir cualquier cambio

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge snapshot --match-contract LiquidityPoolGasTest
forge test --match-contract LiquidityPoolGasTest --gas-report
forge test   # no romper 78 PASS + fuzz/invariant
```

Regla práctica: **si el snapshot baja pero un invariant falla, no es una mejora.**

---

## 5. Mapa rápido de archivos

| Pieza | Rol |
|-------|-----|
| `src/LiquidityPool.sol` | deposit / withdraw / accrueFees |
| `src/LiquidityPoolFactory.sol` | crea pools |
| `src/LiquidityPoolERC20.sol` | LP token (permite mint a `address(0)`) |
| `src/libraries/FixedPointMath.sol` | shares ↔ assets, `accFeePerShare` |
| `src/libraries/SafeTransfer.sol` | transfers seguros + bubble-revert |
| `test/attack/` | FirstDeposit + Reentrancy |
| `test/fuzz/` · `test/invariant/` | propiedad y solvencia |
| `test/gas/` · `.gas-snapshot` | baseline de gas |

---

## 6. Resumen

1. **Decisiones:** vault single-asset, LP propio, `totalAssets` explícito, CEI + reentrancy guard, anti-inflation, lock, slippage, fees por share price.
2. **Lógica:** deposit minta shares; fees suben `totalAssets`; withdraw quema shares tras el lock.
3. **Gas:** ya hay immutables, constants, unchecked post-check, cache en `_syncFees` y custom errors. Se puede bajar más (clones, transient reentrancy, menos SLOAD, optimizer), midiendo siempre contra fuzz/invariant.

Si querés el siguiente paso concreto: priorizar **clones EIP-1167 en Factory** (mayor win en deploy) o **cache de storage en deposit/withdraw** (win en hot path con menos riesgo).
