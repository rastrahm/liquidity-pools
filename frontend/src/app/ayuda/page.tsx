import Link from "next/link";

/**
 * Manual in-app: deploy, UI y opciones on-chain del LiquidityPool.
 */
export default function AyudaPage() {
  return (
    <div className="app-grid help-manual">
      <header className="hero">
        <div className="hero-top toolbar">
          <Link href="/" className="btn btn-ghost">
            ← Volver
          </Link>
        </div>
        <p className="brand">Ayuda</p>
        <h1 className="headline">Manual del Liquidity Pool</h1>
        <p className="lede">
          Guía para Anvil + MetaMask y explicación de cada opción del contrato: depósito, retiro,
          fees, lock time y protecciones.
        </p>
      </header>

      <nav className="panel" aria-label="Índice">
        <h2 className="panel-title">Índice</h2>
        <ul className="help-toc">
          <li>
            <a href="#setup">Instalación</a>
          </li>
          <li>
            <a href="#wallet">Wallet</a>
          </li>
          <li>
            <a href="#interfaz">Interfaz</a>
          </li>
          <li>
            <a href="#stats">Panel Pool</a>
          </li>
          <li>
            <a href="#deposit">Depositar</a>
          </li>
          <li>
            <a href="#withdraw">Retirar</a>
          </li>
          <li>
            <a href="#fees">Fees</a>
          </li>
          <li>
            <a href="#contrato">Opciones del contrato</a>
          </li>
          <li>
            <a href="#conceptos">Conceptos</a>
          </li>
          <li>
            <a href="#errores">Errores on-chain</a>
          </li>
          <li>
            <a href="#problemas">Problemas</a>
          </li>
        </ul>
      </nav>

      <section className="panel" id="setup">
        <h2 className="panel-title">1. Instalación local</h2>
        <p className="help-subtitle">Requisitos</p>
        <ul className="help-list">
          <li>
            <strong>Foundry</strong> (<code>anvil</code>, <code>forge</code>)
          </li>
          <li>
            <strong>Node ≥ 20.19</strong> (ver <code>frontend/.nvmrc</code>)
          </li>
          <li>
            <strong>MetaMask</strong> u otra wallet EIP-1193
          </li>
        </ul>
        <p className="help-subtitle">Pasos</p>
        <ol className="help-list">
          <li>
            Terminal 1 — cadena local: <code>anvil</code>
          </li>
          <li>
            Terminal 2 — deploy:
            <br />
            <code>
              forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
            </code>
          </li>
          <li>
            Copiá del log <strong>Underlying</strong>, <strong>Factory</strong> y <strong>Pool</strong> a{" "}
            <code>frontend/.env.local</code> (plantilla en <code>.env.example</code>). Detalle en{" "}
            <code>doc/DEPLOY-ES.md</code>.
          </li>
          <li>
            Terminal 3 — frontend: <code>cd frontend && npm install && npm run dev</code>
          </li>
          <li>
            Abrí <Link href="/">http://127.0.0.1:3000</Link>
          </li>
        </ol>
        <p className="help-callout">
          El deploy crea un <code>MockERC20</code> (UND), una <code>LiquidityPoolFactory</code> con
          lock de <strong>1 día</strong>, un pool inicial y minta 1&nbsp;000&nbsp;000 UND al deployer
          (cuenta Anvil #0).
        </p>
      </section>

      <section className="panel" id="wallet">
        <h2 className="panel-title">2. Conectar la wallet</h2>
        <ol className="help-steps">
          <li>
            En MetaMask, red personalizada: RPC <code>http://127.0.0.1:8545</code>, chain ID{" "}
            <strong>31337</strong>, símbolo ETH.
          </li>
          <li>
            Importá la cuenta Anvil #0 (la del deploy). Clave privada por defecto:
            <br />
            <code>0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80</code>
          </li>
          <li>
            Pulsá <strong>Conectar wallet</strong>. Si la red no coincide, la UI pedirá cambiar a
            31337.
          </li>
          <li>
            Tras conectar verás tu address acortada. Todas las txs (mint, deposit, withdraw, fees)
            requieren wallet.
          </li>
        </ol>
      </section>

      <section className="panel" id="interfaz">
        <h2 className="panel-title">3. Recorrido por la interfaz</h2>
        <table className="help-table">
          <thead>
            <tr>
              <th>Sección</th>
              <th>Para qué sirve</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Barra superior</td>
              <td>Abrir esta ayuda y alternar tema claro/oscuro.</td>
            </tr>
            <tr>
              <td>Mint demo 10k</td>
              <td>
                Acuña 10&nbsp;000 UND de prueba en tu wallet (solo <code>MockERC20</code> del deploy).
              </td>
            </tr>
            <tr>
              <td>Pool</td>
              <td>Reservas, supply LP, tu posición y fecha de desbloqueo.</td>
            </tr>
            <tr>
              <td>Depositar</td>
              <td>
                Envía underlying al pool y recibe LP shares (<code>deposit</code>).
              </td>
            </tr>
            <tr>
              <td>Retirar</td>
              <td>
                Quema LP y recupera underlying (<code>withdraw</code>), si el lock expiró.
              </td>
            </tr>
            <tr>
              <td>Fees</td>
              <td>
                Inyecta UND al pool y actualiza el share price (<code>accrueFees</code>).
              </td>
            </tr>
          </tbody>
        </table>
        <p className="help-callout">
          Flujo recomendado en la demo: <strong>Mint demo</strong> → <strong>Depositar</strong> →{" "}
          <strong>Accrue fees</strong> (sube el valor de cada share) → esperar lock (o usar{" "}
          <code>anvil_setNextBlockTimestamp</code> / reinicio con lock corto) →{" "}
          <strong>Retirar</strong>.
        </p>
      </section>

      <section className="panel" id="stats">
        <h2 className="panel-title">4. Panel Pool (lecturas on-chain)</h2>
        <dl className="help-dl">
          <div>
            <dt>Total assets</dt>
            <dd>
              Contabilidad interna de reservas (<code>totalAssets</code>): underlying depositado más
              fees ya sincronizados. Es la base del share price.
            </dd>
          </div>
          <div>
            <dt>LP supply</dt>
            <dd>
              Suministro total de shares LP (<code>totalSupply</code>), incluyendo las 1000 wei
              quemadas a <code>address(0)</code> en el primer depósito.
            </dd>
          </div>
          <div>
            <dt>Tus shares</dt>
            <dd>
              Balance LP de tu wallet. Representan tu proporción del pool: al retirar recibís{" "}
              <code>assets ≈ shares × totalAssets / totalSupply</code>.
            </dd>
          </div>
          <div>
            <dt>Tu saldo UND</dt>
            <dd>Balance del token subyacente en tu wallet (no incluye lo que está en el pool).</dd>
          </div>
          <div>
            <dt>Lock hasta</dt>
            <dd>
              Timestamp de <code>lockUntil(tuAddress)</code>. Cada depósito <strong>reinicia</strong>{" "}
              el reloj: no podés retirar hasta que expire <code>lockDuration</code> (1 día en el
              deploy).
            </dd>
          </div>
          <div>
            <dt>Pool</dt>
            <dd>Address del contrato <code>LiquidityPool</code> leída de <code>.env.local</code>.</dd>
          </div>
        </dl>
      </section>

      <section className="panel" id="deposit">
        <h2 className="panel-title">5. Depositar</h2>
        <p className="muted tiny">
          Llama a <code>deposit(assets, to, minSharesOut)</code> tras un <code>approve</code> del
          underlying al pool.
        </p>
        <dl className="help-dl">
          <div>
            <dt>Monto UND</dt>
            <dd>
              Cantidad de underlying a aportar (<code>assets</code>). Debe ser &gt; 0. La UI convierte
              a wei (18 decimales).
            </dd>
          </div>
          <div>
            <dt>Slippage (bps)</dt>
            <dd>
              Tolerancia en <strong>basis points</strong> (1 bps = 0,01&nbsp;%). Ejemplo:{" "}
              <code>50</code> = 0,5&nbsp;%. La app calcula el preview con{" "}
              <code>previewDeposit</code> y envía <code>minSharesOut</code> = shares esperadas × (1 −
              slippage). Si el pool cambia entre la estimación y la tx, y recibís menos shares, la tx
              revierte con <code>SlippageExceeded</code>.
            </dd>
          </div>
        </dl>
        <p className="help-subtitle">Qué hace el contrato</p>
        <ol className="help-steps">
          <li>
            Convierte assets → shares según el ratio actual (<code>_convertToShares</code>).
          </li>
          <li>
            En el <strong>primer depósito</strong> mint de <code>MINIMUM_LIQUIDITY</code> (1000 wei)
            a <code>address(0)</code> (anti-inflation) y el resto a <code>to</code> (vos).
          </li>
          <li>
            Actualiza <code>totalAssets</code> y pone{" "}
            <code>lockUntil[to] = now + lockDuration</code>.
          </li>
          <li>
            Pull del underlying con CEI: mint/estado primero, luego{" "}
            <code>safeTransferFrom</code>.
          </li>
        </ol>
        <p className="help-callout">
          El receptor de shares en la UI es tu propia address (<code>to = msg.sender</code>). Cada
          nuevo depósito alarga el lock de esa cuenta.
        </p>
      </section>

      <section className="panel" id="withdraw">
        <h2 className="panel-title">6. Retirar</h2>
        <p className="muted tiny">
          Llama a <code>withdraw(shares, to, minAssetsOut)</code>. Quema tus LP y te devuelve
          underlying.
        </p>
        <dl className="help-dl">
          <div>
            <dt>Shares LP</dt>
            <dd>
              Cantidad a quemar. Vacío = usar todo tu balance. Debe ser &gt; 0 y ≤ tus shares.
            </dd>
          </div>
          <div>
            <dt>Slippage (bps)</dt>
            <dd>
              Mínimo de underlying que aceptás. Preview con <code>previewWithdraw</code> →{" "}
              <code>minAssetsOut</code>. Si tras fees o cambios de estado recibirías menos, revierte{" "}
              <code>SlippageExceeded</code>.
            </dd>
          </div>
        </dl>
        <p className="help-subtitle">Qué hace el contrato</p>
        <ol className="help-steps">
          <li>
            Exige <code>block.timestamp ≥ lockUntil[msg.sender]</code>; si no,{" "}
            <code>LockTimeNotExpired</code>.
          </li>
          <li>
            Calcula assets con el share price actual (incluye fees ya accruals).
          </li>
          <li>
            Quema shares, resta <code>totalAssets</code> y transfiere underlying a <code>to</code>{" "}
            (CEI).
          </li>
        </ol>
        <p className="help-callout">
          Si depositaste y el lock aún no venció, el botón puede estar habilitado en UI pero la tx
          fallará on-chain. Revisá <strong>Lock hasta</strong> en el panel Pool.
        </p>
      </section>

      <section className="panel" id="fees">
        <h2 className="panel-title">7. Fees (accrueFees)</h2>
        <p className="muted tiny">
          Llama a <code>accrueFees(amount)</code>. En la demo simula ingresos del protocolo que
          benefician a los LPs.
        </p>
        <dl className="help-dl">
          <div>
            <dt>Monto fee</dt>
            <dd>
              Si <code>amount &gt; 0</code>, el contrato hace pull de ese UND desde tu wallet (hace
              falta approve). Si <code>amount == 0</code>, solo sincroniza donaciones ya enviadas al
              pool (balance on-chain &gt; <code>totalAssets</code>).
            </dd>
          </div>
        </dl>
        <p className="help-subtitle">Qué hace el contrato</p>
        <ol className="help-steps">
          <li>
            Opcionalmente recibe <code>amount</code> de underlying.
          </li>
          <li>
            <code>_syncFees</code>: compara balance real vs <code>totalAssets</code>; el delta es el
            fee.
          </li>
          <li>
            Sube <code>totalAssets</code> y, si hay supply LP, incrementa{" "}
            <code>accFeePerShare</code> (escala UD60x18) de forma proporcional.
          </li>
          <li>
            No minta shares nuevas: el share price sube, así que al retirar cada LP recibe más
            underlying por share.
          </li>
        </ol>
        <p className="help-callout">
          Sin LPs (<code>totalSupply == 0</code>), los fees quedan en reserva hasta el primer
          depósito; después se distribuyen vía el acumulador.
        </p>
      </section>

      <section className="panel" id="contrato">
        <h2 className="panel-title">8. Opciones y API del contrato</h2>
        <p className="help-subtitle">Funciones de escritura</p>
        <table className="help-table">
          <thead>
            <tr>
              <th>Función</th>
              <th>Parámetros</th>
              <th>Efecto</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <code>deposit</code>
              </td>
              <td>
                <code>assets</code>, <code>to</code>, <code>minSharesOut</code>
              </td>
              <td>Custodia underlying, minta LP, reinicia lock del receptor.</td>
            </tr>
            <tr>
              <td>
                <code>withdraw</code>
              </td>
              <td>
                <code>shares</code>, <code>to</code>, <code>minAssetsOut</code>
              </td>
              <td>Quema LP del caller, envía underlying si el lock expiró.</td>
            </tr>
            <tr>
              <td>
                <code>accrueFees</code>
              </td>
              <td>
                <code>amount</code>
              </td>
              <td>Inyecta / sincroniza fees y actualiza share price.</td>
            </tr>
          </tbody>
        </table>
        <p className="help-subtitle">Vistas útiles</p>
        <dl className="help-dl">
          <div>
            <dt>
              <code>previewDeposit(assets)</code>
            </dt>
            <dd>Shares estimadas sin cambiar estado. Base del cálculo de slippage en la UI.</dd>
          </div>
          <div>
            <dt>
              <code>previewWithdraw(shares)</code>
            </dt>
            <dd>Underlying estimado al quemar esas shares (incluye fees ya sync).</dd>
          </div>
          <div>
            <dt>
              <code>underlying</code> / <code>lockDuration</code>
            </dt>
            <dd>
              Inmutables: token custodiado y segundos de lock tras cada depósito (86400 en el
              deploy).
            </dd>
          </div>
          <div>
            <dt>
              <code>accFeePerShare</code>
            </dt>
            <dd>
              Acumulador de fees por share en punto fijo UD60x18. Sube con cada{" "}
              <code>accrueFees</code> exitoso cuando hay supply.
            </dd>
          </div>
          <div>
            <dt>
              <code>MINIMUM_LIQUIDITY()</code>
            </dt>
            <dd>
              Constante <code>1000</code>: tranche quemada en el primer mint para congelar el ratio
              share/reserva (mitiga el ataque de inflación del primer depositante).
            </dd>
          </div>
          <div>
            <dt>
              <code>lockUntil(account)</code>
            </dt>
            <dd>Unix timestamp hasta el cual <code>account</code> no puede retirar.</dd>
          </div>
        </dl>
        <p className="help-subtitle">Factory</p>
        <p className="muted tiny">
          <code>LiquidityPoolFactory.createPool(underlying)</code> despliega un nuevo pool con el{" "}
          <code>lockDuration</code> de la factory. La UI de esta demo apunta a un pool ya creado en
          el script de deploy (<code>NEXT_PUBLIC_POOL_ADDRESS</code>).
        </p>
      </section>

      <section className="panel" id="conceptos">
        <h2 className="panel-title">9. Conceptos del diseño</h2>
        <dl className="help-dl">
          <div>
            <dt>LP shares (ERC-20 interno)</dt>
            <dd>
              Certificado de participación. No hay swap AMM aquí: es un vault de un solo asset con
              fees proporcionales.
            </dd>
          </div>
          <div>
            <dt>Anti-inflation (primer depósito)</dt>
            <dd>
              Sin liquidez mínima quemada, un atacante podría donar underlying y diluir shares de
              los siguientes. Quemar 1000 wei a <code>address(0)</code> fija un floor del ratio.
            </dd>
          </div>
          <div>
            <dt>Lock time</dt>
            <dd>
              Reduce retiros inmediatos tipo flash / churn. Cada depósito reinicia el timer de esa
              cuenta.
            </dd>
          </div>
          <div>
            <dt>CEI + ReentrancyGuard</dt>
            <dd>
              Mint/burn y actualización de estado ocurren antes de transfers externos; más{" "}
              <code>nonReentrant</code> en escritura.
            </dd>
          </div>
          <div>
            <dt>Slippage on-chain</dt>
            <dd>
              <code>minSharesOut</code> / <code>minAssetsOut</code> son la protección real; el
              preview de la UI solo estima.
            </dd>
          </div>
        </dl>
      </section>

      <section className="panel" id="errores">
        <h2 className="panel-title">10. Errores custom del contrato</h2>
        <table className="help-table">
          <thead>
            <tr>
              <th>Error</th>
              <th>Cuándo aparece</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <code>ZeroLiquidity</code>
              </td>
              <td>Assets/shares cero, o conversión que redondea a cero.</td>
            </tr>
            <tr>
              <td>
                <code>SlippageExceeded</code>
              </td>
              <td>
                Shares o assets resultantes &lt; mínimo pedido (<code>minSharesOut</code> /{" "}
                <code>minAssetsOut</code>).
              </td>
            </tr>
            <tr>
              <td>
                <code>LockTimeNotExpired</code>
              </td>
              <td>Retiro antes de <code>lockUntil[msg.sender]</code>.</td>
            </tr>
            <tr>
              <td>
                <code>ZeroAddress</code>
              </td>
              <td>
                <code>to == address(0)</code> en deposit/withdraw, o underlying cero en el
                constructor.
              </td>
            </tr>
            <tr>
              <td>
                <code>InvalidRatio</code>
              </td>
              <td>Reservado en la interfaz para restricciones de ratio (no usado en el flujo básico).</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section className="panel" id="problemas">
        <h2 className="panel-title">11. Problemas frecuentes</h2>
        <dl className="help-dl">
          <div>
            <dt>«Red incorrecta»</dt>
            <dd>MetaMask en chain <strong>31337</strong> apuntando a Anvil.</dd>
          </div>
          <div>
            <dt>Retiro revierte por lock</dt>
            <dd>
              Esperá a <strong>Lock hasta</strong>, o en Anvil avanzá el tiempo (
              <code>evm_increaseTime</code> / <code>anvil_setNextBlockTimestamp</code> + mine).
            </dd>
          </div>
          <div>
            <dt>SlippageExceeded</dt>
            <dd>
              Subí bps o reducí el monto. Otro usuario pudo depositar/retirar o accruals entre el
              preview y la confirmación.
            </dd>
          </div>
          <div>
            <dt>Approve / saldo insuficiente</dt>
            <dd>
              Usá <strong>Mint demo 10k</strong> o la cuenta #0 del deploy. El deposit y accrueFees
              piden approve del underlying al pool.
            </dd>
          </div>
          <div>
            <dt>Anvil reiniciado</dt>
            <dd>
              Las addresses cambian. Actualizá <code>.env.local</code> y reiniciá{" "}
              <code>npm run dev</code>.
            </dd>
          </div>
          <div>
            <dt>Error 500 / caché Next</dt>
            <dd>
              Parás el server y en <code>frontend/</code> ejecutá <code>npm run dev:clean</code>.
            </dd>
          </div>
        </dl>
      </section>
    </div>
  );
}
