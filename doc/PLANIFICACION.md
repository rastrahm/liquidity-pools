# Planificación — Module 07: Liquidity Pools & Fee Distribution

**Estado:** Fase **0** ✅ — scaffold Foundry + interfaces + docs.

## 1. Objetivo del proyecto

Motor de **tokenización de pools de liquidez** con distribución proporcional de fees, contabilidad dinámica de depósitos/retiros y protecciones matemáticas contra ataques de inflación (flash loans), usando Foundry y Solidity `0.8.24`.

### Capacidades principales

- Emisión y quema de **tokens LP** (ERC-20 interno) ligados al ratio reserva/shares.
- **Depósito y retiro** con protección de slippage (`SlippageExceeded`).
- **Distribución proporcional de fees** acumulados en el pool mediante matemática de punto fijo (`UD60x18`).
- **Anti-inflation attack:** quema de `1000` wei de LP a `address(0)` en la primera provisión de liquidez.
- **Lock time** opcional por depósito para mitigar manipulaciones de corto plazo.
- Seguridad: **CEI**, **ReentrancyGuard**, **custom errors**, transferencias seguras (SafeERC20).

---

## 2. Alcance

### Incluye

| Área | Descripción |
|------|-------------|
| LiquidityPool | Pool principal: deposit, withdraw, accrue fees, mint/burn LP |
| LP ERC-20 | Implementación interna; shares ∝ participación en reservas + fees |
| Fee accounting | Acumulación y reparto proporcional vía `UD60x18` (share price) |
| Anti-inflation | `MINIMUM_LIQUIDITY = 1000` wei quemados a `address(0)` en primer depósito |
| Lock time | Timestamp de desbloqueo por posición; `LockTimeNotExpired` |
| Ratio guard | Validación de ratios en depósitos multi-activo; `InvalidRatio` |
| Slippage | `minSharesOut` / `minAmountOut` en deposit/withdraw |
| Seguridad | CEI (mint/burn antes de transfers), `nonReentrant`, SafeERC20 |
| Tests | Unit, fuzz, invariant, first-deposit attack, multi-user dilution |

### No incluye (v1)

- Swaps AMM / producto constante (cubierto en módulo 06).
- Concentrated liquidity / ticks.
- Governance on-chain de parámetros de fee.
- Frontend Next.js (opcional en fase posterior).
- Integración Chainlink / oráculos externos.
- Flash loan callbacks como feature de producto.

---

## 3. Stack técnico

| Componente | Elección |
|------------|----------|
| Compilador | `pragma solidity 0.8.24;` (exacto, sin pragma flotante) |
| Framework | Foundry (`forge test`, fuzz ≥ 1000, invariant testing) |
| Librerías | OpenZeppelin Contracts v5.x (ERC20, SafeERC20, ReentrancyGuard), Solmate (opcional gas) |
| Matemática | Punto fijo `UD60x18` para fees y ratios de shares |
| Transferencias | SafeERC20; ETH vía `.call{value}` si aplica |
| Documentación | NatSpec en toda API public/external |

---

## 4. Arquitectura

```
07-liquidity-pools/
├── doc/                                    # Documentación de diseño
│   ├── PLANIFICACION.md
│   ├── diagrama-clases.md
│   ├── diagrama-flujo.md
│   └── flujograma.md
├── src/
│   ├── LiquidityPool.sol                   # Pool core: deposit/withdraw/fees/LP
│   ├── LiquidityPoolFactory.sol            # Despliegue de pools por activo subyacente
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
│   ├── fuzz/LiquidityPool.fuzz.t.sol       # Amounts + slippage con bound()
│   ├── invariant/LiquidityPool.invariant.t.sol
│   └── attack/FirstDepositAttack.t.sol     # Donation / inflation attack
├── script/
│   └── Deploy.s.sol
├── foundry.toml
└── remappings.txt
```

### Roles

| Actor | Responsabilidad |
|-------|-----------------|
| **LP (Liquidity Provider)** | Deposita activo subyacente → recibe LP; quema LP → retira proporcional |
| **Fee depositor** | Envía fees al pool (transfer directo o `accrueFees`) → beneficia a todos los LPs vía share price |
| **LiquidityPool** | Custodia reservas, emite/quema LP, distribuye fees proporcionalmente |
| **Factory** | Crea pools únicos por token subyacente (o par de tokens en v2) |
| **Atacante (test)** | Simula donation/inflation attack → debe fallar post-guard |

---

## 5. Modelo de datos

```solidity
// LiquidityPool (resumen de estado)
address public immutable underlying;       // ERC-20 custodiado (v1: single-asset)
uint256 public totalAssets;              // Reservas contabilizadas (incluye fees acumulados)
uint256 public accFeePerShare;           // Acumulador UD60x18 por share LP
uint256 public constant MINIMUM_LIQUIDITY = 1000;

mapping(address => uint256) public lockUntil;  // Timestamp de desbloqueo por LP
// + totalSupply / balances LP (ERC-20 interno)
```

### Fórmulas clave

| Operación | Fórmula |
|-----------|---------|
| Primer depósito | `shares = assets - MINIMUM_LIQUIDITY`; mint `MINIMUM_LIQUIDITY` → `address(0)` |
| Depósito posterior | `shares = assets * totalSupply / totalAssets` |
| Retiro | `assetsOut = shares * totalAssets / totalSupply` |
| Fee accrual | `accFeePerShare += feeAmount * 1e18 / totalSupply` (UD60x18) |
| Share price | `totalAssets / totalSupply` (aumenta cuando entran fees) |

---

## 6. API on-chain (LiquidityPool)

| Función | Visibilidad | Descripción |
|---------|-------------|-------------|
| `deposit(uint256 assets, address to, uint256 minSharesOut)` | external nonReentrant | Deposita underlying → mint LP a `to` |
| `withdraw(uint256 shares, address to, uint256 minAssetsOut)` | external nonReentrant | Quema LP → transfiere underlying a `to` |
| `previewDeposit(uint256 assets)` | view | Shares estimadas (incluye fees acumulados) |
| `previewWithdraw(uint256 shares)` | view | Assets estimados al retirar |
| `totalAssets()` | view | Reservas totales contabilizadas |
| `accrueFees(uint256 amount)` | external | Registra fees explícitos (opcional si fees entran por transfer) |
| `lockUntil(address)` | view | Timestamp de desbloqueo del LP |

### Errores custom (obligatorios)

| Error | Condición |
|-------|-----------|
| `ZeroLiquidity()` | Depósito/retiro con amount 0 o shares resultantes 0 |
| `SlippageExceeded()` | Shares/assets recibidos < mínimo esperado |
| `InvalidRatio()` | Ratio de depósito no cumple restricción del pool |
| `LockTimeNotExpired()` | Retiro antes de `lockUntil[msg.sender]` |

### Eventos

`Deposit` · `Withdraw` · `FeesAccrued` · `PoolCreated` (Factory)

---

## 7. Lógica de depósito (CEI + anti-inflation)

1. Validar `assets > 0` y ratio (si aplica) → sino `ZeroLiquidity` / `InvalidRatio`.
2. Calcular `shares` vía `FixedPointMath` (primer depósito vs subsequent).
3. Validar `shares >= minSharesOut` → sino `SlippageExceeded`.
4. **Effects:** `_mint(to, shares)` (y quema `MINIMUM_LIQUIDITY` en primer depósito).
5. Actualizar `totalAssets`, `lockUntil[to]` si aplica.
6. **Interactions:** `SafeERC20.transferFrom(msg.sender, address(this), assets)`.
7. Emit `Deposit`.

---

## 8. Fases de implementación (TDD)

| Fase | Entregable | Estado |
|------|------------|--------|
| **0** | Scaffold Foundry + docs + interfaces | ✅ |
| **1** | Tests failing: deposit / withdraw / reverts | ⏳ |
| **2** | `FixedPointMath` (UD60x18) + skeleton `LiquidityPool` | ⏳ |
| **3** | `deposit` + MINIMUM_LIQUIDITY + anti-inflation | ⏳ |
| **4** | `withdraw` + slippage + lock time | ⏳ |
| **5** | Fee accrual proporcional (`accFeePerShare`) | ⏳ |
| **6** | `LiquidityPoolFactory` + deploy script | ⏳ |
| **7** | Fuzz + invariant + FirstDepositAttack tests | ⏳ |
| **8** | Gas snapshot + NatSpec + SafeERC20 hardening | ⏳ |

---

## 9. Plan de pruebas

| Suite | Ubicación | Cobertura |
|-------|-----------|-----------|
| Unit | `test/LiquidityPool.t.sol` | Primer vs subsequent deposit, withdraw, fee share price |
| Factory | `test/LiquidityPoolFactory.t.sol` | Pool único por underlying, `getPool` |
| Fuzz | `test/fuzz/LiquidityPool.fuzz.t.sol` | Amounts + slippage con `bound()` |
| Invariant | `test/invariant/LiquidityPool.invariant.t.sol` | `totalAssets >= sum(withdrawable)`; shares consistentes |
| Attack | `test/attack/FirstDepositAttack.t.sol` | Donation/inflation no drena depósitos posteriores |
| Edge | `test/LiquidityPool.t.sol` | Zero balance, multi-user dilution, lock time |

---

## 10. Criterios de aceptación

- [ ] Scaffold Foundry (`0.8.24`, fuzz ≥ 1000)
- [ ] TDD deposit / withdraw con tests rojos primero
- [ ] `MINIMUM_LIQUIDITY` (1000 wei) quemado en primer depósito
- [ ] Fee distribution vía `UD60x18` sin drift de rounding crítico
- [ ] CEI: mint/burn **antes** de transfers ERC-20
- [ ] Custom errors (sin strings en `require`)
- [ ] `ReentrancyGuard` en deposit/withdraw
- [ ] Tests first-deposit attack pasan
- [ ] Fuzz con `bound()` en amounts y slippage
- [ ] Invariant: reservas balanceadas tras secuencias aleatorias
- [ ] NatSpec en funciones public/external
- [ ] `vm.expectRevert` en todos los caminos de fallo

---

## 11. Documentos relacionados

| Documento | Contenido |
|-----------|-----------|
| [diagrama-clases.md](./diagrama-clases.md) | UML contratos, libs, tests |
| [diagrama-flujo.md](./diagrama-flujo.md) | Flujos deposit/withdraw/fee accrual |
| [flujograma.md](./flujograma.md) | Operativo + anti-inflation + pipeline TDD |

---

## 12. Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| First-depositor inflation / donation attack | `MINIMUM_LIQUIDITY` locked a `address(0)` |
| Flash loan manipulación de share price | Lock time + contabilidad `totalAssets` explícita |
| Reentrancy en transfer ERC-20 | CEI + `nonReentrant`; mint/burn antes de transfer |
| Rounding errors en fee payout | `UD60x18` fixed-point; tests de edge con amounts pequeños |
| Tokens non-standard | SafeERC20 con chequeo de retorno |
| Slippage en deposit/withdraw volátil | `minSharesOut` / `minAssetsOut` + `SlippageExceeded` |
| Retiro prematuro post-deposit | `lockUntil` + `LockTimeNotExpired` |
| Dilución desproporcionada multi-user | Tests de dilución; fórmulas pro-rata verificadas por fuzz |

---

## 13. Convenciones (suite + Solidity rules)

- Pragma fijo `0.8.24`; layout: Interfaces → Libraries → Contracts → State → Events → Errors → Modifiers → Functions.
- NatSpec `@notice` / `@dev` / `@param` / `@return` en API pública.
- Tests primero (TDD); `vm.expectRevert` en caminos de fallo.
- Gas: `immutable`/`constant`, custom errors, packing donde aplique.
- Relación con módulo 06: el swap AMM vive en `06-token-swap`; este módulo se centra en **tokenización LP + fee distribution** como primitiva reutilizable.
