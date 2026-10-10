# Class Diagram — Liquidity Pools & Fee Distribution

🌐 [Español](./diagrama-clases-ES.md) · **English** · [Index](./README.md)

**To-be** structural model (module 07, planning). Contracts, libraries, and tests.

## 1. Main diagram (UML / Mermaid)

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

## 2. Errors and events

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

## 3. Tests and invariant handlers

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

## 4. Responsibilities

| Artifact | Role |
|----------|------|
| `LiquidityPool` | Holds the underlying, mints/burns LP, fee accrual, lock time |
| `LiquidityPoolFactory` | Creates one unique pool per underlying token |
| `FixedPointMath` | Shares ↔ assets conversion; `accFeePerShare` accumulator (UD60x18) |
| `ERC20LP` | Internal representation of pool ownership |
| `ReentrancyGuard` | Lock on deposit/withdraw |
| `SafeERC20` | Safe transfers of the underlying |
| `MockERC20` | Test token for Foundry / Anvil |
| `Handler` | Random actor for invariant testing |
| `FirstDepositAttackTest` | Verifies that donation/inflation doesn't drain LPs |

## 5. Dependencies (summary)

```
LiquidityPool
  ├── inherits   → ERC20LP (internal), ReentrancyGuard
  ├── implements → ILiquidityPool
  ├── uses       → FixedPointMath (UD60x18), SafeERC20
  ├── holds      → IERC20 underlying
  ├── emits      → Deposit / Withdraw / FeesAccrued
  └── reverts    → ZeroLiquidity / SlippageExceeded / InvalidRatio / LockTimeNotExpired

LiquidityPoolFactory
  ├── createPool → new LiquidityPool(underlying, lockDuration)
  └── getPool    → mapping underlying → pool

FixedPointMath
  ├── convertToShares(assets, supply, totalAssets)
  ├── convertToAssets(shares, supply, totalAssets)
  └── accrueFeePerShare(fee, supply, acc) → acc + fee * 1e18 / supply
```

## 6. Solidity layout (LiquidityPool)

1. Imports / interfaces / libraries  
2. Contract `LiquidityPool`  
3. Immutables (`underlying`, `lockDuration`)  
4. State: `totalAssets`, `accFeePerShare`, `lockUntil`  
5. Events → Errors → Modifiers  
6. External: `deposit`, `withdraw`, `preview*`, `totalAssets`, `accrueFees`  
7. Internal: `_depositEffects`, `_withdrawEffects`, `_syncTotalAssets`, `_mint`, `_burn`

## 7. Relationship with module 06 (Token Swap)

```mermaid
classDiagram
    direction LR

    class TokenSwapPair {
        <<module 06>>
        +mint()
        +burn()
        +swap()
    }

    class LiquidityPool {
        <<module 07>>
        +deposit()
        +withdraw()
        +accrueFees()
    }

    note for TokenSwapPair "AMM x*y=k\nGeometric LP + swap"
    note for LiquidityPool "LP tokenization\nUD60x18 fee distribution\nAnti-inflation guard"
```

Module 07 abstracts **tokenization and fee distribution** as a standalone primitive; it can later be integrated with the module 06 AMM pairs.
