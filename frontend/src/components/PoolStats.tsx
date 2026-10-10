"use client";

import { formatTokens, formatUnlock, shortAddress } from "@/lib/format";
import type { PoolSnapshot } from "@/hooks/usePool";

type PoolStatsProps = {
  snap: PoolSnapshot;
  poolAddress: string;
};

/**
 * Estadísticas on-chain del pool y posición del LP.
 * @param props Snapshot y address del pool.
 */
export function PoolStats({ snap, poolAddress }: PoolStatsProps) {
  return (
    <section className="panel" aria-labelledby="stats-title">
      <h2 id="stats-title" className="panel-title">
        Pool · {snap.symbol}
      </h2>
      <dl className="stats">
        <div>
          <dt>Total assets</dt>
          <dd data-testid="total-assets">{formatTokens(snap.totalAssets)}</dd>
        </div>
        <div>
          <dt>LP supply</dt>
          <dd data-testid="total-supply">{formatTokens(snap.totalSupply)}</dd>
        </div>
        <div>
          <dt>Tus shares</dt>
          <dd data-testid="user-shares">{formatTokens(snap.userShares)}</dd>
        </div>
        <div>
          <dt>Tu saldo {snap.symbol}</dt>
          <dd data-testid="user-underlying">{formatTokens(snap.userUnderlying)}</dd>
        </div>
        <div>
          <dt>Lock hasta</dt>
          <dd data-testid="lock-until">{formatUnlock(snap.lockUntil)}</dd>
        </div>
        <div>
          <dt>Pool</dt>
          <dd title={poolAddress}>{shortAddress(poolAddress)}</dd>
        </div>
      </dl>
    </section>
  );
}
