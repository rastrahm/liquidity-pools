import { formatEther, Interface } from "ethers";
import { erc20Abi, poolAbi } from "@/lib/contracts";

const REVERT_IFACE = new Interface([...poolAbi, ...erc20Abi]);

type EthersLikeError = {
  shortMessage?: string;
  reason?: string;
  message?: string;
  data?: unknown;
  info?: { error?: { data?: unknown } };
  error?: { data?: unknown };
};

/**
 * Busca datos de revert anidados (ethers / MetaMask RPC).
 * @param err Error desconocido.
 */
function extractRevertData(err: unknown): string | null {
  if (!err || typeof err !== "object") return null;
  const e = err as EthersLikeError;
  const candidates = [e.data, e.info?.error?.data, e.error?.data];
  for (const value of candidates) {
    if (typeof value === "string" && value.startsWith("0x") && value.length >= 10) {
      return value;
    }
  }
  return null;
}

/**
 * Traduce custom errors del pool / ERC-20 a mensajes legibles.
 * @param data Hex de revert.
 */
function decodeRevertData(data: string): string | null {
  try {
    const parsed = REVERT_IFACE.parseError(data);
    if (!parsed) return null;

    switch (parsed.name) {
      case "ERC20InsufficientAllowance":
        return `Aprobación insuficiente (tenés ${formatEther(parsed.args.allowance as bigint)}, se necesitan ${formatEther(parsed.args.needed as bigint)}).`;
      case "ERC20InsufficientBalance":
        return `Saldo insuficiente (tenés ${formatEther(parsed.args.balance as bigint)}, se necesitan ${formatEther(parsed.args.needed as bigint)}). Usá «Mint demo».`;
      case "SafeTransferFailed":
        return "La transferencia de tokens falló. Revisá saldo y aprobación.";
      case "ZeroLiquidity":
        return "Cantidad de liquidez o shares resultantes es cero.";
      case "SlippageExceeded":
        return "Slippage excedido: el resultado es menor al mínimo aceptado.";
      case "LockTimeNotExpired":
        return "Todavía no expiró el lock time. Esperá para retirar.";
      case "InvalidRatio":
        return "Ratio de depósito inválido.";
      case "ZeroAddress":
        return "Address cero no permitida.";
      case "PoolExists":
        return "Ya existe un pool para ese underlying.";
      default:
        return `${parsed.name}()`;
    }
  } catch {
    return null;
  }
}

/**
 * Extrae mensaje legible de errores ethers / wallet.
 * @param err Error desconocido.
 */
export function formatContractError(err: unknown): string {
  const data = extractRevertData(err);
  if (data) {
    const decoded = decodeRevertData(data);
    if (decoded) return decoded;
  }

  if (err instanceof Error || (err && typeof err === "object" && "shortMessage" in err)) {
    const nested = err as Error & EthersLikeError;
    if (nested.shortMessage?.includes("unknown custom error")) {
      return "La transacción fue revertida. Revisá saldo, aprobación y lock time.";
    }
    if (nested.shortMessage) return nested.shortMessage;
    if (nested.reason) return nested.reason;
    if (err instanceof Error) return nested.message;
  }
  return String(err);
}
