import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { DepositPanel } from "@/components/DepositPanel";

describe("DepositPanel", () => {
  it("muestra el formulario de depósito por rol", () => {
    render(<DepositPanel symbol="UND" disabled={false} onDeposit={() => undefined} />);
    expect(screen.getByRole("heading", { name: /depositar/i })).toBeInTheDocument();
    expect(screen.getByLabelText(/monto de und a depositar/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /depositar/i })).toBeEnabled();
  });
});
