import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Liquidity Pool — demo LP",
  description: "Demo UI de pool tokenizado con deposit, withdraw, fees y tema claro/oscuro",
  icons: { icon: "/favicon.svg" },
};

const themeBootScript = `
(function(){
  try {
    var k='lp-theme';
    var t=localStorage.getItem(k);
    if(t!=='light'&&t!=='dark'){
      t=window.matchMedia('(prefers-color-scheme: light)').matches?'light':'dark';
    }
    document.documentElement.setAttribute('data-theme', t);
  } catch(e) {
    document.documentElement.setAttribute('data-theme', 'dark');
  }
})();
`;

/**
 * Layout raíz (Server Component).
 * @param props.children Contenido de la ruta.
 */
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeBootScript }} />
      </head>
      <body>
        <main className="shell">{children}</main>
      </body>
    </html>
  );
}
