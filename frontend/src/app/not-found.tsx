import Link from "next/link";

/**
 * Página 404.
 */
export default function NotFoundPage() {
  return (
    <section className="panel">
      <h2 className="panel-title">No encontrado</h2>
      <p className="muted">Esa ruta no existe.</p>
      <Link href="/" className="btn btn-primary">
        Volver al inicio
      </Link>
    </section>
  );
}
