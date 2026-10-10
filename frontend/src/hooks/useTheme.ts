"use client";

import { useCallback, useEffect, useState } from "react";

export type ThemeMode = "dark" | "light";

const STORAGE_KEY = "lp-theme";

function resolveInitialTheme(): ThemeMode {
  if (typeof window === "undefined") return "dark";
  const stored = window.localStorage.getItem(STORAGE_KEY);
  if (stored === "light" || stored === "dark") return stored;
  return window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
}

function applyTheme(theme: ThemeMode): void {
  document.documentElement.setAttribute("data-theme", theme);
  window.localStorage.setItem(STORAGE_KEY, theme);
}

/**
 * Hook de tema claro/oscuro con persistencia.
 */
export function useTheme() {
  const [theme, setThemeState] = useState<ThemeMode>("dark");
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const initial = resolveInitialTheme();
    applyTheme(initial);
    setThemeState(initial);
    setReady(true);
  }, []);

  const setTheme = useCallback((next: ThemeMode) => {
    applyTheme(next);
    setThemeState(next);
  }, []);

  const toggleTheme = useCallback(() => {
    setTheme(theme === "dark" ? "light" : "dark");
  }, [theme, setTheme]);

  return { theme, toggleTheme, setTheme, ready };
}
