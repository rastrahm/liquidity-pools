"use client";

import Link from "next/link";
import { ThemeToggle } from "@/components/ThemeToggle";

/**
 * Barra superior: ayuda + tema.
 */
export function AppToolbar() {
  return (
    <div className="hero-top toolbar">
      <Link href="/ayuda" className="btn btn-ghost" aria-label="Ayuda">
        ? Ayuda
      </Link>
      <ThemeToggle />
    </div>
  );
}
