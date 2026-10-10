import { BrowserProvider, Contract, JsonRpcProvider, type Signer } from "ethers";
import factoryAbiJson from "../../abi/LiquidityPoolFactory.json";
import poolAbiJson from "../../abi/LiquidityPool.json";
import erc20AbiJson from "../../abi/MockERC20.json";
import type { PublicEnv } from "./env";

export const factoryAbi = factoryAbiJson.abi;
export const poolAbi = poolAbiJson.abi;
export const erc20Abi = erc20AbiJson.abi;

export type PoolEnv = Pick<
  PublicEnv,
  | "NEXT_PUBLIC_RPC_URL"
  | "NEXT_PUBLIC_FACTORY_ADDRESS"
  | "NEXT_PUBLIC_POOL_ADDRESS"
  | "NEXT_PUBLIC_UNDERLYING_ADDRESS"
>;

/**
 * Provider de solo lectura hacia el RPC configurado.
 * @param rpcUrl URL del nodo.
 */
export function createReadProvider(rpcUrl: string): JsonRpcProvider {
  return new JsonRpcProvider(rpcUrl);
}

/**
 * Contratos de lectura (sin signer).
 * @param env Config pública.
 * @param provider Provider opcional.
 */
export function createReadContracts(env: PoolEnv, provider?: JsonRpcProvider) {
  const p = provider ?? createReadProvider(env.NEXT_PUBLIC_RPC_URL);
  return {
    provider: p,
    factory: new Contract(env.NEXT_PUBLIC_FACTORY_ADDRESS, factoryAbi, p),
    pool: new Contract(env.NEXT_PUBLIC_POOL_ADDRESS, poolAbi, p),
    underlying: new Contract(env.NEXT_PUBLIC_UNDERLYING_ADDRESS, erc20Abi, p),
  };
}

/**
 * Contratos conectados a un signer (wallet).
 * @param env Config pública.
 * @param signer Signer de la wallet.
 */
export function createWriteContracts(env: PoolEnv, signer: Signer) {
  return {
    factory: new Contract(env.NEXT_PUBLIC_FACTORY_ADDRESS, factoryAbi, signer),
    pool: new Contract(env.NEXT_PUBLIC_POOL_ADDRESS, poolAbi, signer),
    underlying: new Contract(env.NEXT_PUBLIC_UNDERLYING_ADDRESS, erc20Abi, signer),
  };
}

/**
 * Obtiene BrowserProvider desde `window.ethereum`.
 */
export function getBrowserProvider(): BrowserProvider {
  const eth = typeof window !== "undefined" ? window.ethereum : undefined;
  if (!eth) {
    throw new Error("No hay wallet inyectada (instala MetaMask u otra).");
  }
  return new BrowserProvider(eth);
}

declare global {
  interface Window {
    ethereum?: {
      request: (args: { method: string; params?: unknown[] }) => Promise<unknown>;
      on?: (event: string, handler: (...args: unknown[]) => void) => void;
      removeListener?: (event: string, handler: (...args: unknown[]) => void) => void;
    };
  }
}
