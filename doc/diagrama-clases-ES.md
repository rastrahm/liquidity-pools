# Diagrama de clases — Liquidity Pools & Fee Distribution

🌐 **Español** · [English](./diagrama-clases-EN.md) · [Índice](./README.md)

Modelo estructural **to-be** (módulo 07, planificación). Contratos, librerías y tests.

## 1. Diagrama principal (UML / Mermaid)

```mermaid
classDiagram
    direction TB

    class IERC20 {
        <<interface>>
        +balanceOf(address) uint256
        +transfer(address, uint256) bool
        +transferFrom(address, address, uint256) bool
        +approve(address, uint256) bool
    }

    class FixedPointMath {
        <<library>>
        +toUD60x18(uint256) UD60x18
        +fromUD60x18(UD60x18) uint256
        +mulDiv(uint256, uint256, uint256) uint256
        +convertToShares(uint256 assets, uint256 supply, uint256 totalAssets) uint256
        +convertToAssets(uint256 shares, uint256 supply, uint256 totalAssets) uint256
        +accrueFeePerShare(uint256 fee, uint256 supply, uint256 acc) uint256
    }

    class ILiquidityPool {
        <<interface>>
        +deposit(uint256, address, uint256) uint256
        +withdraw(uint256, address, uint256) uint256
        +previewDeposit(uint256) uint256
        +previewWithdraw(uint256) uint256
        +totalAssets() uint256
        +accrueFees(uint256)
        +lockUntil(address) uint256
    }

    class ILiquidityPoolFactory {
        <<interface>>
        +createPool(address) address
        +getPool(address) address
        +allPools(uint256) address
        +allPoolsLength() uint256
    }

    class LiquidityPool {
        +address immutable underlying
        +uint256 totalAssets
        +uint256 accFeePerShare
        +uint256 constant MINIMUM_LIQUIDITY
        +mapping lockUntil
        +deposit(uint256, address, uint256) uint256
        +withdraw(uint256, address, uint256) uint256
        +previewDeposit(uint256) uint256
        +previewWithdraw(uint256) uint256
        +accrueFees(uint256)
        -_depositEffects(uint256, address) uint256
        -_withdrawEffects(uint256, address) uint256
        -_syncTotalAssets()
    }

    class LiquidityPoolFactory {
        +mapping getPool
        +address[] allPools
        +uint256 lockDuration
        +createPool(address) address
    }

    class ReentrancyGuard {
        <<OZ>>
        #nonReentrant()
    }

    class ERC20LP {
        <<internal ERC20>>
        +totalSupply()
        +balanceOf()
        #_mint(address, uint256)
        #_burn(address, uint256)
    }

    class SafeERC20 {
        <<OZ library>>
        +safeTransferFrom(IERC20, address, address, uint256)
        +safeTransfer(IERC20, address, uint256)
    }

    ILiquidityPool <|.. LiquidityPool
    ReentrancyGuard <|-- LiquidityPool
    ERC20LP <|-- LiquidityPool
    ILiquidityPoolFactory <|.. LiquidityPoolFactory
    LiquidityPool ..> FixedPointMath : shares / fees
    LiquidityPool ..> IERC20 : underlying
    LiquidityPool ..> SafeERC20 : transfers
    LiquidityPoolFactory ..> LiquidityPool : create
```

## 2. Errores y eventos

```mermaid
classDiagram
    direction LR

    class LiquidityPoolErrors {
        <<errors>>
        ZeroLiquidity()
        SlippageExceeded()
        InvalidRatio()
        LockTimeNotExpired()
    }

    class LiquidityPoolEvents {
        <<events>>
        Deposit(address indexed, address indexed, uint256, uint256)
        Withdraw(address indexed, address indexed, uint256, uint256)
        FeesAccrued(uint256, uint256)
    }

    class LiquidityPool {
        +deposit()
        +withdraw()
        +accrueFees()
    }

    LiquidityPool ..> LiquidityPoolErrors : revert
    LiquidityPool ..> LiquidityPoolEvents : emit
```

## 3. Tests y handlers de invariantes

```mermaid
classDiagram
    direction LR

    class LiquidityPool
    class LiquidityPoolFactory
    class MockERC20
    class LiquidityPoolTest
    class LiquidityPoolFactoryTest
    class LiquidityPoolFuzzTest
    class LiquidityPoolInvariantTest
    class FirstDepositAttackTest
    class Handler {
        <<invariant actor>>
        +deposit()
        +withdraw()
        +donate()
        +accrueFees()
    }

    MockERC20 ..|> IERC20
    LiquidityPoolTest --> LiquidityPool
    LiquidityPoolTest --> MockERC20
    LiquidityPoolFactoryTest --> LiquidityPoolFactory
    LiquidityPoolFuzzTest --> LiquidityPool
    LiquidityPoolInvariantTest --> Handler
    FirstDepositAttackTest --> LiquidityPool
    FirstDepositAttackTest --> MockERC20
    Handler --> LiquidityPool
    Handler --> MockERC20
```

## 4. Responsabilidades

| Artefacto | Rol |
|-----------|-----|
| `LiquidityPool` | Custodia underlying, mint/burn LP, fee accrual, lock time |
| `LiquidityPoolFactory` | Crear pools únicos por token subyacente |
| `FixedPointMath` | Conversión shares ↔ assets; acumulador `accFeePerShare` (UD60x18) |
| `ERC20LP` | Representación interna de participación en el pool |
| `ReentrancyGuard` | Lock en deposit/withdraw |
| `SafeERC20` | Transferencias seguras del underlying |
| `MockERC20` | Token de prueba Foundry / Anvil |
| `Handler` | Actor aleatorio para invariant testing |
| `FirstDepositAttackTest` | Verifica que donation/inflation no drena LPs |

## 5. Dependencias (resumen)

```
LiquidityPool
  ├── hereda     → ERC20LP (interno), ReentrancyGuard
  ├── implementa → ILiquidityPool
  ├── usa        → FixedPointMath (UD60x18), SafeERC20
  ├── custodia   → IERC20 underlying
  ├── emite      → Deposit / Withdraw / FeesAccrued
  └── revierte   → ZeroLiquidity / SlippageExceeded / InvalidRatio / LockTimeNotExpired

LiquidityPoolFactory
  ├── createPool → new LiquidityPool(underlying, lockDuration)
  └── getPool    → mapping underlying → pool

FixedPointMath
  ├── convertToShares(assets, supply, totalAssets)
  ├── convertToAssets(shares, supply, totalAssets)
  └── accrueFeePerShare(fee, supply, acc) → acc + fee * 1e18 / supply
```

## 6. Layout Solidity (LiquidityPool)

1. Imports / interfaces / libraries  
2. Contract `LiquidityPool`  
3. Immutables (`underlying`, `lockDuration`)  
4. State: `totalAssets`, `accFeePerShare`, `lockUntil`  
5. Events → Errors → Modifiers  
6. External: `deposit`, `withdraw`, `preview*`, `totalAssets`, `accrueFees`  
7. Internal: `_depositEffects`, `_withdrawEffects`, `_syncTotalAssets`, `_mint`, `_burn`

## 7. Relación con módulo 06 (Token Swap)

```mermaid
classDiagram
    direction LR

    class TokenSwapPair {
        <<módulo 06>>
        +mint()
        +burn()
        +swap()
    }

    class LiquidityPool {
        <<módulo 07>>
        +deposit()
        +withdraw()
        +accrueFees()
    }

    note for TokenSwapPair "AMM x*y=k\nLP geométrico + swap"
    note for LiquidityPool "Tokenización LP\nFee distribution UD60x18\nAnti-inflation guard"
```

El módulo 07 abstrae la **tokenización y distribución de fees** como primitiva independiente; puede integrarse posteriormente con pares AMM del módulo 06.
