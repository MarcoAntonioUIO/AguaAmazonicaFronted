
import { useState } from 'react';

export default function ReactIntegrationTest() {
  const [count, setCount] = useState(0);

  return (
    <section className="react-test">
      <h2>La tienda está preparada para React</h2>

      <p>
        Este componente React funciona dentro de tu sitio Astro.
      </p>

      <button
        type="button"
        onClick={() => setCount((previous) => previous + 1)}
      >
        Prueba de interacción: {count}
      </button>

      <style>{`
        .react-test {
          padding: 1.5rem;
          border: 1px solid #d1d5db;
          border-radius: 12px;
          margin: 1rem 0;
        }

        .react-test button {
          padding: 0.7rem 1rem;
          border: 0;
          border-radius: 8px;
          background: #087f5b;
          color: white;
          cursor: pointer;
        }
      `}</style>
    </section>
  );
}
