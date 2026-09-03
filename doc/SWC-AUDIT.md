# Auditoría SWC — Liquidity Pools & Fee Distribution

Verificación de `LiquidityPool` y `LiquidityPoolFactory` contra el [SWC Registry](https://swcregistry.io/) (EIP-1470) y principios del monorepo (custom errors, `ReentrancyGuard`, SafeERC20, MINIMUM_LIQUIDITY, UD60x18).

> **Nota:** El SWC Registry no se mantiene activamente desde ~2020. Complementar con [SCSVS](https://github.com/ComposableSecurity/SCSVS) y [EEA EthTrust](https://entethalliance.org/specs/ethtrust/).

**Contratos auditados:** `src/LiquidityPool.sol`, `src/LiquidityPoolFactory.sol`, `src/LiquidityPoolERC20.sol`, `src/libraries/FixedPointMath.sol`  
**Fecha:** 2026-09-02  
**Referencia tests:** `test/LiquidityPool.t.sol`, `test/LiquidityPoolFactory.t.sol`, `test/fuzz/`, `test/invariant/`, `test/attack/`  
**Estilo:** alineado a [`06-token-swap/doc/SWC-AUDIT.md`](../../06-token-swap/doc/SWC-AUDIT.md)

---

## Resumen ejecutivo

| Estado | Cantidad |
|--------|----------|
| ✅ Mitigado / No aplicable | 33 |
| ⚠️ Informativo (diseño / MEV / trust) | 3 |
| ❌ Vulnerable | 0 |

**Conclusión:** Sin vulnerabilidades SWC explotables en el alcance v1 (single-asset ERC-20, sin swaps AMM). Riesgos informativos: MEV/orden en deposit/withdraw públicos (mitigado con `minSharesOut` / `minAssetsOut` + lock time), donaciones al pool (mitigado con contabilidad `totalAssets` explícita + `MINIMUM_LIQUIDITY`), y tokens fee-on-transfer fuera de alcance.

**Principios del suite verificados:**

| Principio | Estado |
|-----------|--------|
| Custom errors (no `require` strings) | ✅ |
| Pragma fijo `0.8.24` | ✅ |
| CEI + `nonReentrant` en deposit/withdraw/accrueFees | ✅ + attack suite |
| Anti-inflation `MINIMUM_LIQUIDITY` → `address(0)` | ✅ + FirstDepositAttack |
| SafeERC20 (SWC-104) en transfers | ✅ |
| Fee accrual UD60x18 (`accFeePerShare`) | ✅ + fuzz |
| Fuzz ≥ 1000 runs | ✅ `foundry.toml` |
| Invariantes solvencia / LP locked / balance | ✅ `test/invariant/` |

---

## Matriz completa SWC-100 — SWC-136

| ID | Título | Aplica | Estado | Evidencia en Liquidity Pool |
|----|--------|--------|--------|------------------------------|
| SWC-100 | Function Default Visibility | Sí | ✅ | Visibilidad explícita en contratos y libs |
| SWC-101 | Integer Overflow and Underflow | Sí | ✅ | Solidity `0.8.24`; `FixedPointMath.mulDiv` con overflow check |
| SWC-102 | Outdated Compiler Version | Sí | ✅ | `pragma solidity 0.8.24` + `foundry.toml` |
| SWC-103 | Floating Pragma | Sí | ✅ | Pragma exacto (sin `^`) |
| SWC-104 | Unchecked Call Return Value | Sí | ✅ | OZ `SafeERC20.safeTransfer` / `safeTransferFrom` |
| SWC-105 | Unprotected Ether Withdrawal | No | N/A | Sin ETH / `payable` / `.call{value}` |
| SWC-106 | Unprotected SELFDESTRUCT | No | N/A | Sin `selfdestruct` |
| SWC-107 | Reentrancy | Sí | ✅ | `nonReentrant` + CEI; `test/attack/ReentrancyAttack.t.sol` |
| SWC-108 | State Variable Default Visibility | Sí | ✅ | Estado con visibilidad explícita (`public` / `immutable`) |
| SWC-109 | Uninitialized Storage Pointer | No | N/A | Sin punteros storage legacy |
| SWC-110 | Assert Violation | No | N/A | Sin `assert` de producción |
| SWC-111 | Deprecated Solidity Functions | Sí | ✅ | Sin `suicide` / `throw` / `tx.origin` |
| SWC-112 | Delegatecall to Untrusted Callee | No | N/A | Sin `delegatecall` |
| SWC-113 | DoS with Failed Call | Parcial | ✅ | Transfer ERC-20 fallida → revert completa de deposit/withdraw |
| SWC-114 | Transaction Order Dependence | Sí | ⚠️ | Front-run de deposit/withdraw (MEV); slippage params |
| SWC-115 | Authorization through tx.origin | No | N/A | Sin `tx.origin` |
| SWC-116 | Block values as a proxy for time | Sí | ✅ | `lockUntil` usa `block.timestamp` (diseño explícito de lock) |
| SWC-117 | Signature Malleability | No | N/A | Sin firmas / `ecrecover` / permit |
| SWC-118 | Incorrect Constructor Name | No | N/A | `constructor` 0.8+ |
| SWC-119 | Shadowing State Variables | Sí | ✅ | Sin shadowing de estado |
| SWC-120 | Weak Sources of Randomness | No | N/A | Sin RNG |
| SWC-121 | Missing Protection against Signature Replay | No | N/A | Sin firmas |
| SWC-122 | Lack of Proper Signature Verification | No | N/A | Sin verificación de firmas |
| SWC-123 | Requirement Violation | Sí | ✅ | Custom errors + unit/fuzz/invariant/attack |
| SWC-124 | Write to Arbitrary Storage Location | No | N/A | Sin assembly de storage arbitrario |
| SWC-125 | Incorrect Inheritance Order | Sí | ✅ | `ILiquidityPool, LiquidityPoolERC20, ReentrancyGuard` |
| SWC-126 | Insufficient Gas Griefing | No | N/A | Sin relayers con stipend fijo |
| SWC-127 | Arbitrary Jump with Function Type Variable | No | N/A | Sin function types dinámicos |
| SWC-128 | DoS With Block Gas Limit | Parcial | ✅ | Sin loops de usuario; operaciones O(1) |
| SWC-129 | Typographical Error | Sí | ✅ | Revisión + `forge build` / tests |
| SWC-130 | Right-To-Left-Override | No | N/A | ASCII |
| SWC-131 | Presence of unused variables | Sí | ✅ | Sin dead code material |
| SWC-132 | Unexpected Ether balance | No | N/A | Contratos no manejan ETH |
| SWC-133 | Hash Collisions (var-length args) | No | N/A | Sin hashing multi-dinámico propio |
| SWC-134 | Message call with hardcoded gas | No | N/A | Sin `{gas: …}` |
| SWC-135 | Code With No Effects | No | N/A | Sin no-ops relevantes |
| SWC-136 | Unencrypted Private Data On-Chain | Parcial | ✅ | `totalAssets`, shares y fees son públicos por diseño |

---

## Riesgos informativos

### SWC-114 — MEV y orden de transacciones

Un bot puede front-run depósitos/retiros alterando el share price entre `preview*` y la tx del usuario.

**Mitigación de producto:** `minSharesOut` / `minAssetsOut` (`SlippageExceeded`); `lockDuration` reduce manipulación flash de corto plazo.

### Donación / inflation attack residual

Tokens enviados directamente al pool sin sync no alteran `totalAssets` (contabilidad explícita). Tras `accrueFees(0)`, el share price sube para **todos** los LPs existentes; `MINIMUM_LIQUIDITY` evita diluir a cero al siguiente depositante.

**Mitigación:** `MINIMUM_LIQUIDITY` locked; `test/attack/FirstDepositAttack.t.sol`; invariante `balanceOf(address(0)) == 1000`.

### Centralización / trust

| Tema | Riesgo | Tratamiento v1 |
|------|--------|----------------|
| Factory única | Pools maliciosos off-suite | Usar factory desplegada conocida |
| Lock duration fijo | Parámetro de deploy | Immutable en factory/pool |
| Tokens fee-on-transfer | Accounting incorrecto | Fuera de alcance v1; solo ERC-20 estándar |
| Fees pre-primer depósito | Quedan en reserva hasta LPs | Documentado; `accrueFees` pending |

---

## Checklist principios monorepo

| Principio | ¿Cumple? | Notas |
|-----------|----------|--------|
| Custom errors | ✅ | `ZeroLiquidity`, `SlippageExceeded`, `InvalidRatio`, `LockTimeNotExpired`, … |
| ReentrancyGuard (OZ) | ✅ | deposit / withdraw / accrueFees |
| SafeERC20 | ✅ | pull/push underlying |
| MINIMUM_LIQUIDITY anti-inflation | ✅ | 1000 wei → `address(0)` |
| Fee accrual UD60x18 | ✅ | `FixedPointMath.accrueFeePerShare` |
| NatSpec públicas/externas | ⏳ | Fase 8 hardening |
| Fuzz ≥ 1000 runs | ✅ | `test/fuzz/LiquidityPool.fuzz.t.sol` |
| Invariantes solvencia / LP | ✅ | `test/invariant/` |

---

## Mapeo SWC → tests

| SWC | Test(s) |
|-----|---------|
| SWC-101 | `testFuzz_deposit_*`, `testFuzz_withdraw_*`, `testFuzz_roundTrip_*`, `FixedPointMath.mulDiv` overflow |
| SWC-103 | Compilador fijo (build) |
| SWC-104 | Unit deposit/withdraw; SafeERC20 en pool |
| SWC-107 | `test_Attack_reenterDeposit_*`, `test_Attack_reenterWithdraw_*`, `test_Attack_reenterAccrueFees_*` |
| SWC-114 | `testFuzz_deposit_revertsSlippage`; documental arriba |
| SWC-116 | Unit `lockUntil` / `LockTimeNotExpired` |
| SWC-123 | unit Pool/Factory + fuzz + invariant + attack |
| Inflation | `test_Attack_inflation_*`, `invariant_minimumLiquidityLocked` |
| Solvencia | `invariant_totalAssetsEqBalanceWhenSynced`, `invariant_fullConvertToAssetsLeTotalAssets` |

---

## Referencias

- [SWC Registry](https://swcregistry.io/)
- [EIP-1470](https://eips.ethereum.org/EIPS/eip-1470)
- Módulo 06: [`06-token-swap/doc/SWC-AUDIT.md`](../../06-token-swap/doc/SWC-AUDIT.md)
- Plan: [`PLANIFICACION.md`](./PLANIFICACION.md)
