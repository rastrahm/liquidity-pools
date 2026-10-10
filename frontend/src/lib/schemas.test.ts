import { describe, expect, it } from "vitest";
import { amountSchema } from "./schemas";
import { applySlippage, formatTokens, shortAddress } from "./format";

describe("schemas", () => {
  it("acepta montos decimales positivos", () => {
    expect(amountSchema.parse("10.5")).toBe("10.5");
  });

  it("rechaza cero y texto", () => {
    expect(amountSchema.safeParse("0").success).toBe(false);
    expect(amountSchema.safeParse("abc").success).toBe(false);
  });
});

describe("format", () => {
  it("acorta addresses", () => {
    expect(shortAddress("0x1234567890abcdef1234567890abcdef12345678")).toBe("0x1234…5678");
  });

  it("formatea tokens", () => {
    expect(formatTokens(10n ** 18n)).toBe("1.0000");
  });

  it("aplica slippage", () => {
    expect(applySlippage(10_000n, 100)).toBe(9900n);
  });
});
