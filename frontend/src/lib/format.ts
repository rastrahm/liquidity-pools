import { formatEther, parseEther } from "ethers";

/**
 * Acorta una address para UI.
 * @param address Address completa.
 */
export function shortAddress(address: string): string {
  if (address.length < 10) return address;
  return `${address.slice(0, 6)}…${address.slice(-4)}`;
}

/**
 * Formatea wei a tokens legibles (18 decimales).
 * @param wei Cantidad en wei.
 */
export function formatTokens(wei: bigint | string): string {
  const n = formatEther(wei);
  const num = Number(n);
  if (num >= 1_000_000) return `${(num / 1_000_000).toFixed(2)}M`;
  if (num >= 1_000) return `${(num / 1_000).toFixed(2)}k`;
  if (num >= 1) return num.toFixed(4);
  return num.toPrecision(4);
}

/**
 * Parsea input de usuario a wei.
 * @param amount String decimal.
 */
export function parseTokenInput(amount: string): bigint {
  return parseEther(amount.trim() || "0");
}

/**
 * Aplica slippage en bps a un monto (mínimo aceptable).
 * @param amount Monto esperado.
 * @param slippageBps Basis points (100 = 1%).
 */
export function applySlippage(amount: bigint, slippageBps: number): bigint {
  return (amount * BigInt(10_000 - slippageBps)) / 10_000n;
}

/**
 * Formatea timestamp Unix a fecha local corta.
 * @param unix Segundos Unix.
 */
export function formatUnlock(unix: bigint): string {
  if (unix === 0n) return "—";
  const d = new Date(Number(unix) * 1000);
  return d.toLocaleString();
}
