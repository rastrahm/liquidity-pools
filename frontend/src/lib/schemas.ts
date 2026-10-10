import { z } from "zod";

/**
 * Esquema de monto decimal positivo para formularios.
 */
export const amountSchema = z
  .string()
  .trim()
  .min(1, "Ingresá un monto")
  .regex(/^\d+(\.\d+)?$/, "Monto inválido")
  .refine((v) => Number(v) > 0, "El monto debe ser mayor a 0");

/**
 * Esquema de address Ethereum.
 */
export const addressInputSchema = z
  .string()
  .trim()
  .regex(/^0x[a-fA-F0-9]{40}$/, "Address inválida");

/**
 * Slippage en basis points (0–5000 = 0–50%).
 */
export const slippageBpsSchema = z.coerce.number().int().min(0).max(5000);

export type AmountInput = z.infer<typeof amountSchema>;
