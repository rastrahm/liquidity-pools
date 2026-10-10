"use client";

import { useTheme } from "@/hooks/useTheme";

/**
 * Toggle de tema claro/oscuro.
 */
export function ThemeToggle() {
  const { theme, toggleTheme, ready } = useTheme();

  return (
    <button
      type="button"
      className="btn btn-ghost theme-toggle"
      onClick={toggleTheme}
      aria-label={theme === "dark" ? "Cambiar a tema claro" : "Cambiar a tema oscuro"}
      disabled={!ready}
    >
      <span aria-hidden="true">{theme === "dark" ? "☀" : "☾"}</span>
      <span className="theme-toggle-label">{theme === "dark" ? "Claro" : "Oscuro"}</span>
    </button>
  );
}
