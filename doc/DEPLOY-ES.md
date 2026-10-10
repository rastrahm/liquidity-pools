# Deploy local — Liquidity Pools

🌐 **Español** · [English](./DEPLOY-EN.md) · [Índice](./README.md)

## Requisitos

- Anvil en `http://127.0.0.1:8545`
- Foundry (`forge`)
- Node ≥ 20.19

## Deploy contratos

```bash
export PATH="$HOME/.foundry/bin:$PATH"
anvil   # terminal 1

forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

Copiá del log:

| Variable | Log |
|----------|-----|
| `NEXT_PUBLIC_UNDERLYING_ADDRESS` | `Underlying` |
| `NEXT_PUBLIC_FACTORY_ADDRESS` | `Factory` |
| `NEXT_PUBLIC_POOL_ADDRESS` | `Pool` |

## Frontend

```bash
cd frontend
cp .env.example .env.local
# editar addresses del deploy
npm install
npm test
npm run dev
```

```env
NEXT_PUBLIC_RPC_URL=http://127.0.0.1:8545
NEXT_PUBLIC_CHAIN_ID=31337
NEXT_PUBLIC_FACTORY_ADDRESS=0x…
NEXT_PUBLIC_POOL_ADDRESS=0x…
NEXT_PUBLIC_UNDERLYING_ADDRESS=0x…
```

Abrir `http://127.0.0.1:3000` y conectar MetaMask (cuenta Anvil #0, red 31337).

Manual: `/ayuda` o botón **? Ayuda**.
