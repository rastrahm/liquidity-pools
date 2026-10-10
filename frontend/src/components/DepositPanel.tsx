"use client";

import { useState } from "react";
import { amountSchema } from "@/lib/schemas";

type DepositPanelProps = {
  symbol: string;
  disabled: boolean;
  onDeposit: (amount: string, slippageBps: number) => void;
};

/**
 * Formulario de depósito de underlying → LP shares.
 * @param props Symbol, disabled y callback.
 */
export function DepositPanel({ symbol, disabled, onDeposit }: DepositPanelProps) {
  const [amount, setAmount] = useState("100");
  const [slippage, setSlippage] = useState("50");
  const [localError, setLocalError] = useState<string | null>(null);

  function submit() {
    const parsed = amountSchema.safeParse(amount);
    if (!parsed.success) {
      setLocalError(parsed.error.issues[0]?.message ?? "Monto inválido");
      return;
    }
    setLocalError(null);
    onDeposit(parsed.data, Number(slippage) || 0);
  }

  return (
    <section className="panel" aria-labelledby="deposit-title">
      <h2 id="deposit-title" className="panel-title">
        Depositar
      </h2>
      <label className="field" htmlFor="deposit-amount">
        Monto {symbol}
        <input
          id="deposit-amount"
          inputMode="decimal"
          placeholder="100"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          aria-label={`Monto de ${symbol} a depositar`}
        />
      </label>
      <label className="field" htmlFor="deposit-slippage">
        Slippage (bps)
        <input
          id="deposit-slippage"
          inputMode="numeric"
          value={slippage}
          onChange={(e) => setSlippage(e.target.value)}
          aria-label="Slippage en basis points"
        />
      </label>
      <div className="actions">
        <button type="button" className="btn btn-primary" disabled={disabled} onClick={submit}>
          Depositar
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
