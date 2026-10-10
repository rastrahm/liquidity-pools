"use client";

import { useMemo } from "react";
import { AppToolbar } from "@/components/AppToolbar";
import { DepositPanel } from "@/components/DepositPanel";
import { FeesPanel } from "@/components/FeesPanel";
import { PoolStats } from "@/components/PoolStats";
import { WithdrawPanel } from "@/components/WithdrawPanel";
import { usePool } from "@/hooks/usePool";
import { useWallet } from "@/hooks/useWallet";
import { safeParsePublicEnv, type PublicEnv } from "@/lib/env";
import { shortAddress } from "@/lib/format";

/**
 * Demo UI: wallet, deposit, withdraw y fees sobre Anvil.
 */
export function LiquidityPoolApp() {
  const envResult = useMemo(() => safeParsePublicEnv(), []);
  const env: PublicEnv | null = envResult.success ? envResult.data : null;
  const wallet = useWallet(env);
  const pool = usePool(env, wallet.address, wallet.signer);

  if (!envResult.success || !env) {
    return (
      <div className="app-grid">
        <AppToolbar />
        <section className="panel" role="alert">
          <h2 className="panel-title">Falta configuración</h2>
          <p className="muted">
            Copiá <code>.env.example</code> → <code>.env.local</code> con las addresses del deploy. Ver{" "}
            <a href="/ayuda">/ayuda</a>.
          </p>
          <pre className="error-box">{envResult.success ? "Env incompleto" : envResult.error.message}</pre>
        </section>
      </div>
    );
  }

  const locked =
    wallet.address != null &&
    pool.snap.lockUntil > 0n &&
    BigInt(Math.floor(Date.now() / 1000)) < pool.snap.lockUntil;

  return (
    <div className="app-grid">
      <header className="hero">
        <AppToolbar />
        <p className="brand">Liquidity Pool</p>
        <h1 className="headline">Fee distribution LP</h1>
        <p className="lede">Depósito, retiro y fees proporcionales · anti-inflation · lock time</p>
        <div className="cta-row">
          {!wallet.address ? (
            <button
              type="button"
              className="btn btn-primary"
              onClick={() => void wallet.connect()}
              disabled={wallet.connecting}
            >
              {wallet.connecting ? "Conectando…" : "Conectar wallet"}
            </button>
          ) : (
            <>
              <span className="pill" data-testid="wallet-address">
                {shortAddress(wallet.address)}
              </span>
              <button type="button" className="btn btn-ghost" onClick={wallet.disconnect}>
                Desconectar
              </button>
              <button type="button" className="btn btn-ghost" disabled={pool.busy} onClick={pool.mintDemo}>
                Mint demo 10k
              </button>
            </>
          )}
        </div>
        {(wallet.error || wallet.wrongChain) && (
          <p className="warn" role="status">
            {wallet.wrongChain ? `Red incorrecta (esperada ${env.NEXT_PUBLIC_CHAIN_ID})` : wallet.error}
          </p>
        )}
        {pool.status && (
          <p className="muted tiny" role="status">
            {pool.status}
          </p>
        )}
        {pool.error && (
          <pre className="error-box" role="alert">
            {pool.error}
          </pre>
        )}
      </header>

      <PoolStats snap={pool.snap} poolAddress={env.NEXT_PUBLIC_POOL_ADDRESS} />

      <DepositPanel
        symbol={pool.snap.symbol}
        disabled={!wallet.address || pool.busy || wallet.wrongChain}
        onDeposit={pool.deposit}
      />

      <WithdrawPanel
        userShares={pool.snap.userShares}
        disabled={!wallet.address || pool.busy || wallet.wrongChain || locked}
        onWithdraw={pool.withdraw}
      />
      {locked && (
        <p className="warn" role="status">
          Lock time activo — el retiro estará disponible al expirar.
        </p>
      )}

      <FeesPanel
        symbol={pool.snap.symbol}
        disabled={!wallet.address || pool.busy || wallet.wrongChain}
        onAccrue={pool.accrueFees}
      />
    </div>
  );
}
