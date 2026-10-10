# Local Deployment — Liquidity Pools

🌐 [Español](./DEPLOY-ES.md) · **English** · [Index](./README.md)

## Requirements

- Anvil at `http://127.0.0.1:8545`
- Foundry (`forge`)
- Node ≥ 20.19

## Deploy the contracts

```bash
export PATH="$HOME/.foundry/bin:$PATH"
anvil   # terminal 1

forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

Copy these values from the log:

| Variable | Log |
|----------|-----|
| `NEXT_PUBLIC_UNDERLYING_ADDRESS` | `Underlying` |
| `NEXT_PUBLIC_FACTORY_ADDRESS` | `Factory` |
| `NEXT_PUBLIC_POOL_ADDRESS` | `Pool` |

## Frontend

```bash
cd frontend
cp .env.example .env.local
# edit the deployed addresses
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

Open `http://127.0.0.1:3000` and connect MetaMask (Anvil account #0, network 31337).

User guide: `/ayuda` or the **? Ayuda** button (the in-app guide is in Spanish).
