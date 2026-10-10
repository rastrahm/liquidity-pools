"use client";

import { useCallback, useEffect, useState } from "react";
import type { Signer } from "ethers";
import { createReadContracts, createWriteContracts } from "@/lib/contracts";
import { formatContractError } from "@/lib/errors";
import { applySlippage, parseTokenInput } from "@/lib/format";
import type { PublicEnv } from "@/lib/env";

export type PoolSnapshot = {
  symbol: string;
  totalAssets: bigint;
  totalSupply: bigint;
  userShares: bigint;
  userUnderlying: bigint;
  lockUntil: bigint;
  lockDuration: bigint;
  previewDeposit: bigint;
  previewWithdraw: bigint;
};

const emptySnap: PoolSnapshot = {
  symbol: "UND",
  totalAssets: 0n,
  totalSupply: 0n,
  userShares: 0n,
  userUnderlying: 0n,
  lockUntil: 0n,
  lockDuration: 0n,
  previewDeposit: 0n,
  previewWithdraw: 0n,
};

/**
 * Hook de lectura/escritura del LiquidityPool.
 * @param env Config pública.
 * @param address Address de la wallet.
 * @param signer Signer opcional.
 */
export function usePool(env: PublicEnv | null, address: string | null, signer: Signer | null) {
  const [snap, setSnap] = useState<PoolSnapshot>(emptySnap);
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const refresh = useCallback(async () => {
    if (!env) return;
    try {
      const { pool, underlying } = createReadContracts(env);
      const [symbol, totalAssets, totalSupply, lockDuration] = await Promise.all([
        underlying.symbol() as Promise<string>,
        pool.totalAssets() as Promise<bigint>,
        pool.totalSupply() as Promise<bigint>,
        pool.lockDuration() as Promise<bigint>,
      ]);

      let userShares = 0n;
      let userUnderlying = 0n;
      let lockUntil = 0n;
      let previewDeposit = 0n;
      let previewWithdraw = 0n;

      if (address) {
        [userShares, userUnderlying, lockUntil] = await Promise.all([
          pool.balanceOf(address) as Promise<bigint>,
          underlying.balanceOf(address) as Promise<bigint>,
          pool.lockUntil(address) as Promise<bigint>,
        ]);
        if (userShares > 0n) {
          previewWithdraw = (await pool.previewWithdraw(userShares)) as bigint;
        }
      }
      previewDeposit = (await pool.previewDeposit(parseTokenInput("1"))) as bigint;

      setSnap({
        symbol,
        totalAssets,
        totalSupply,
        userShares,
        userUnderlying,
        lockUntil,
        lockDuration,
        previewDeposit,
        previewWithdraw,
      });
      setError(null);
    } catch (err) {
      setError(formatContractError(err));
    }
  }, [env, address]);

  useEffect(() => {
    void refresh();
    const id = setInterval(() => void refresh(), 12_000);
    return () => clearInterval(id);
  }, [refresh]);

  const run = useCallback(
    async (label: string, fn: () => Promise<void>) => {
      if (!env || !signer) {
        setError("Conectá la wallet primero");
        return;
      }
      setBusy(true);
      setStatus(label);
      setError(null);
      try {
        await fn();
        setStatus("OK");
        await refresh();
      } catch (err) {
        setError(formatContractError(err));
        setStatus(null);
      } finally {
        setBusy(false);
      }
    },
    [env, signer, refresh],
  );

  const mintDemo = useCallback(() => {
    void run("Mint demo…", async () => {
      const { underlying } = createWriteContracts(env!, signer!);
      const tx = await underlying.mint(await signer!.getAddress(), parseTokenInput("10000"));
      await tx.wait();
    });
  }, [env, signer, run]);

  const deposit = useCallback(
    (amountStr: string, slippageBps: number) => {
      void run("Depositando…", async () => {
        const assets = parseTokenInput(amountStr);
        const { pool, underlying } = createWriteContracts(env!, signer!);
        const preview = (await pool.previewDeposit(assets)) as bigint;
        const minShares = applySlippage(preview, slippageBps);
        const approveTx = await underlying.approve(env!.NEXT_PUBLIC_POOL_ADDRESS, assets);
        await approveTx.wait();
        const to = await signer!.getAddress();
        const tx = await pool.deposit(assets, to, minShares);
        await tx.wait();
      });
    },
    [env, signer, run],
  );

  const withdraw = useCallback(
    (sharesStr: string, slippageBps: number) => {
      void run("Retirando…", async () => {
        const shares = parseTokenInput(sharesStr);
        const { pool } = createWriteContracts(env!, signer!);
        const preview = (await pool.previewWithdraw(shares)) as bigint;
        const minAssets = applySlippage(preview, slippageBps);
        const to = await signer!.getAddress();
        const tx = await pool.withdraw(shares, to, minAssets);
        await tx.wait();
      });
    },
    [env, signer, run],
  );

  const accrueFees = useCallback(
    (amountStr: string) => {
      void run("Acreditando fees…", async () => {
        const amount = parseTokenInput(amountStr);
        const { pool, underlying } = createWriteContracts(env!, signer!);
        if (amount > 0n) {
          const approveTx = await underlying.approve(env!.NEXT_PUBLIC_POOL_ADDRESS, amount);
          await approveTx.wait();
        }
        const tx = await pool.accrueFees(amount);
        await tx.wait();
      });
    },
    [env, signer, run],
  );

  return { snap, status, error, busy, refresh, mintDemo, deposit, withdraw, accrueFees };
}
