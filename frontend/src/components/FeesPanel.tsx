"use client";

import { useState } from "react";
import { amountSchema } from "@/lib/schemas";

type FeesPanelProps = {
  symbol: string;
  disabled: boolean;
  onAccrue: (amount: string) => void;
};

/**
 * Formulario para acreditar fees al pool (share price ↑).
 * @param props Symbol, disabled y callback.
 */
export function FeesPanel({ symbol, disabled, onAccrue }: FeesPanelProps) {
  const [amount, setAmount] = useState("10");
  const [localError, setLocalError] = useState<string | null>(null);

  function submit() {
    const parsed = amountSchema.safeParse(amount);
    if (!parsed.success) {
      setLocalError(parsed.error.issues[0]?.message ?? "Monto inválido");
      return;
    }
    setLocalError(null);
    onAccrue(parsed.data);
  }

  return (
    <section className="panel" aria-labelledby="fees-title">
      <h2 id="fees-title" className="panel-title">
        Fees
      </h2>
      <p className="muted tiny">Envía {symbol} al pool y actualiza accFeePerShare.</p>
      <label className="field" htmlFor="fee-amount">
        Monto fee
        <input
          id="fee-amount"
          inputMode="decimal"
          placeholder="10"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          aria-label={`Monto de fee en ${symbol}`}
        />
      </label>
      <div className="actions">
        <button type="button" className="btn btn-primary" disabled={disabled} onClick={submit}>
          Accrue fees
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
