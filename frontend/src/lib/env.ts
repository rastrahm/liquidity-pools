import { z } from "zod";

const addressSchema = z
  .string()
  .regex(/^0x[a-fA-F0-9]{40}$/, "Debe ser address 0x + 40 hex");

/**
 * Esquema de variables públicas del frontend Liquidity Pool.
 */
const publicEnvSchema = z.object({
  NEXT_PUBLIC_RPC_URL: z.string().url(),
  NEXT_PUBLIC_CHAIN_ID: z.coerce.number().int().positive(),
  NEXT_PUBLIC_FACTORY_ADDRESS: addressSchema,
  NEXT_PUBLIC_POOL_ADDRESS: addressSchema,
  NEXT_PUBLIC_UNDERLYING_ADDRESS: addressSchema,
});

/** Config tipada leída de `process.env` (solo `NEXT_PUBLIC_*`). */
export type PublicEnv = z.infer<typeof publicEnvSchema>;

/**
 * Next solo inyecta `NEXT_PUBLIC_*` con acceso estático.
 */
function readBundledPublicEnv(): Record<string, string | undefined> {
  return {
    NEXT_PUBLIC_RPC_URL: process.env.NEXT_PUBLIC_RPC_URL,
    NEXT_PUBLIC_CHAIN_ID: process.env.NEXT_PUBLIC_CHAIN_ID,
    NEXT_PUBLIC_FACTORY_ADDRESS: process.env.NEXT_PUBLIC_FACTORY_ADDRESS,
    NEXT_PUBLIC_POOL_ADDRESS: process.env.NEXT_PUBLIC_POOL_ADDRESS,
    NEXT_PUBLIC_UNDERLYING_ADDRESS: process.env.NEXT_PUBLIC_UNDERLYING_ADDRESS,
  };
}

/**
 * Parsea el env público.
 * @param raw Variables de entorno.
 */
export function parsePublicEnv(
  raw: Record<string, string | undefined> = readBundledPublicEnv(),
): PublicEnv {
  return publicEnvSchema.parse(raw);
}

/**
 * Intenta parsear sin lanzar.
 */
export function safeParsePublicEnv(
  raw: Record<string, string | undefined> = readBundledPublicEnv(),
) {
  return publicEnvSchema.safeParse(raw);
}
