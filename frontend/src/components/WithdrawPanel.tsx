"use client";

import { useState } from "react";
import { amountSchema } from "@/lib/schemas";
import { formatTokens } from "@/lib/format";

type WithdrawPanelProps = {
  userShares: bigint;
  disabled: boolean;
  onWithdraw: (shares: string, slippageBps: number) => void;
};

/**
 * Formulario de retiro: quema LP → underlying.
 * @param props Shares del usuario, disabled y callback.
 */
export function WithdrawPanel({ userShares, disabled, onWithdraw }: WithdrawPanelProps) {
  const [shares, setShares] = useState("");
  const [slippage, setSlippage] = useState("50");
  const [localError, setLocalError] = useState<string | null>(null);

  function submit() {
    const value = shares.trim() || formatTokens(userShares);
    const parsed = amountSchema.safeParse(value);
    if (!parsed.success) {
      setLocalError(parsed.error.issues[0]?.message ?? "Shares inválidas");
      return;
    }
    setLocalError(null);
    onWithdraw(parsed.data, Number(slippage) || 0);
  }

  return (
    <section className="panel" aria-labelledby="withdraw-title">
      <h2 id="withdraw-title" className="panel-title">
        Retirar
      </h2>
      <p className="muted tiny">Disponible: {formatTokens(userShares)} LP</p>
      <label className="field" htmlFor="withdraw-shares">
        Shares LP
        <input
          id="withdraw-shares"
          inputMode="decimal"
          placeholder={formatTokens(userShares)}
          value={shares}
          onChange={(e) => setShares(e.target.value)}
          aria-label="Cantidad de shares LP a retirar"
        />
      </label>
      <label className="field" htmlFor="withdraw-slippage">
        Slippage (bps)
        <input
          id="withdraw-slippage"
          inputMode="numeric"
          value={slippage}
          onChange={(e) => setSlippage(e.target.value)}
          aria-label="Slippage en basis points para retiro"
        />
      </label>
      <div className="actions">
        <button type="button" className="btn btn-primary" disabled={disabled || userShares === 0n} onClick={submit}>
          Retirar
        </button>
      </div>
      {localError && (
        <p className="warn" role="alert">
          {localError}
        </p>
      )}
    </section>
  );
}
