"use client";

/**
 * Error boundary de la app.
 * @param props.error Error capturado.
 * @param props.reset Función para reintentar.
 */
export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <section className="panel" role="alert">
      <h2 className="panel-title">Error</h2>
      <p className="muted">{error.message}</p>
      <button type="button" className="btn btn-primary" onClick={reset}>
        Reintentar
      </button>
    </section>
  );
}
