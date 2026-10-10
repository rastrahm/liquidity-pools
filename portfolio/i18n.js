const I18N = {
  es: {
    'html.lang': 'es',
    'meta.title': 'Liquidity Pools & Fee Distribution — Rolando Strahm',
    'meta.description':
      'Vault LP single-asset con fees proporcionales, anti-inflation, gas documentado y auditoría SWC. Foundry · Solidity 0.8.24.',

    'nav.overview': 'Proyecto',
    'nav.pillars': 'Pilares',
    'nav.gas': 'Gas',
    'nav.swc': 'SWC',
    'nav.process': 'Proceso',
    'nav.attacks': 'Ataques',
    'nav.repos': 'Repos',
    'nav.close': '← Cerrar',

    'hero.tag': '// MÓDULO 07 · PORTFOLIO WEB3',
    'hero.title': 'LIQUIDITY POOLS<br>FEE DISTRIBUTION',
    'hero.role': 'Solidity 0.8.24 · Foundry · Gas · SWC',
    'hero.sub':
      'Vault single-asset con LP shares, fees proporcionales (UD60x18), anti-inflation, lock time, gas documentado y campañas defensivas SWC.',
    'hero.cta1': 'Ver en GitHub',
    'hero.cta2': 'Ver en GitLab',

    'ov.eyebrow': '// 01 — CONTEXTO',
    'ov.title': 'Por qué este proyecto',
    'ov.lead':
      'Después del AMM (módulo 06), construí un <strong>vault de un solo asset</strong>: depositás underlying, recibís LP shares, los fees suben el share price. El foco no es “otro Uniswap”: es <strong>contabilidad correcta</strong>, <strong>anti-inflation del primer depositante</strong>, <strong>gas</strong> y <strong>SWC</strong> con tests que demuestran que el ataque falla.',

    'pi.eyebrow': '// 02 — TRES PILARES',
    'pi.title': 'Qué entrega el módulo',
    'p1.num': '// PILAR_01',
    'p1.title': 'Vault LP + fees',
    'p1.desc':
      'LiquidityPool + Factory: deposit/withdraw con slippage, accrueFees, LP ERC-20 interno, lock time y MINIMUM_LIQUIDITY.',
    'p1.l1': 'accFeePerShare UD60x18',
    'p1.l2': 'Burn 1000 wei → address(0)',
    'p1.l3': 'CEI + ReentrancyGuard',
    'p2.num': '// PILAR_02',
    'p2.title': 'Optimización de gas',
    'p2.desc':
      'Immutables, constants, SafeTransfer propio, unchecked post-checks y snapshot Foundry documentado en doc/GAS-ES.md.',
    'p2.l1': 'underlying / lockDuration immutable',
    'p2.l2': 'Cache en _syncFees',
    'p2.l3': '.gas-snapshot + gas-report',
    'p3.num': '// PILAR_03',
    'p3.title': 'Verificación SWC',
    'p3.desc':
      'Matriz SWC-100–136, FirstDepositAttack, ReentrancyAttack, fuzz ≥ 1000 e invariantes de solvencia.',
    'p3.l1': '0 vulnerabilidades explotables',
    'p3.l2': '33 mitigados / N/A · 3 info',
    'p3.l3': '78 tests Foundry PASS',

    'gas.eyebrow': '// 03 — OPTIMIZACIÓN DE GAS',
    'gas.title': 'Hot path barato, tradeoffs claros',
    'gas.lead':
      'Fase 8: baseline en <code>doc/GAS-ES.md</code> y <code>.gas-snapshot</code>. Medianas: <strong>deposit ~177k</strong>, <strong>withdraw ~46k</strong>, <strong>accrueFees ~69k</strong>. Cada técnica tiene tradeoff explícito — no micro-ahorros a ciegas.',
    'gas.th1': 'Optimización',
    'gas.th2': 'Tradeoff / efecto',
    'gas.r1a': 'immutable underlying + lockDuration',
    'gas.r1b': 'Lecturas ~100 gas vs ~2100 SLOAD; fijos en deploy',
    'gas.r2a': 'constant MINIMUM_LIQUIDITY (1000)',
    'gas.r2b': 'Sin SLOAD en conversiones shares/assets',
    'gas.r3a': 'SafeTransfer (call + bubble revert)',
    'gas.r3b': 'SWC-104; propaga guard en reentrancy tests (vs OZ SafeERC20)',
    'gas.r4a': 'unchecked totalAssets +=/−= post-checks',
    'gas.r4b': 'Overflow imposible tras validaciones; menos gas en hot path',
    'gas.r5a': 'Cache locals en _syncFees',
    'gas.r5b': 'Menos lecturas storage de balance / supply / assets',
    'gas.r6a': 'Custom errors (external API)',
    'gas.r6b': 'Reverts compactos vs require strings',
    'gas.r7a': 'optimizer_runs = 200',
    'gas.r7b': 'Balance deploy (~1M pool) vs runtime frecuente',

    'swc.eyebrow': '// 04 — VERIFICACIÓN SWC',
    'swc.title': 'SWC Registry · EIP-1470',
    'swc.lead':
      'Matriz <strong>SWC-100 → SWC-136</strong> sobre LiquidityPool / Factory / FixedPointMath. Informe: <code>doc/SWC-AUDIT-ES.md</code>. Conclusión: <strong>0 vulnerabilidades explotables</strong> en el alcance v1 (single-asset).',
    'swc.s1': 'Mitigados / N/A',
    'swc.s2': 'Informativos (diseño)',
    'swc.s3': 'Vulnerables',
    'swc.th1': 'SWC clave',
    'swc.th2': 'Mitigación en el contrato',
    'swc.r101': 'Overflow: Solidity 0.8.24 + FixedPointMath.mulDiv con check',
    'swc.r103': 'Floating pragma: pragma solidity 0.8.24 fijo',
    'swc.r104': 'Unchecked return: SafeTransfer con bubble-revert',
    'swc.r107': 'Reentrancy: CEI + nonReentrant; suite ReentrancyAttack',
    'swc.r114': 'Tx order / MEV: minSharesOut · minAssetsOut + lock time',
    'swc.r123': 'Requirements: custom errors + unit/fuzz/invariant/attack',
    'swc.info': 'INFORMATIVO',
    'swc.i1t': 'MEV en deposit/withdraw',
    'swc.i1d':
      'Front-run puede mover el share price entre preview y tx. Mitigación: slippage on-chain + lockDuration.',
    'swc.i2t': 'Donación / first deposit',
    'swc.i2d':
      'Contabilidad totalAssets explícita + MINIMUM_LIQUIDITY a address(0). Cubierto por FirstDepositAttack.',

    'pr.eyebrow': '// 05 — PROCESO',
    'pr.title': 'Fases 0–8 cerradas',
    'pr.lead':
      'TDD por gates: scaffold, tests rojos, FixedPointMath, deposit, withdraw, fees, factory, fuzz/invariant/attack, gas + SafeTransfer.',
    'ph.02': 'Scaffold + TDD + FixedPoint',
    'ph.34': 'deposit + withdraw + lock',
    'ph.56': 'fees + Factory / Deploy',
    'ph.7': 'Fuzz · invariant · attack · SWC',
    'ph.8': 'Gas snapshot + SafeTransfer',
    'st.1': 'Fases',
    'st.2': 'Tests PASS',
    'st.3': 'SWC críticos',
    'st.4': 'Attack suites',
    'term.label': 'rolando@strahm:~/07-liquidity-pools',
    'term.1': 'forge test',
    'term.2': '[PASS] suite · 78 passed',
    'term.3': 'cat doc/SWC-AUDIT-ES.md | head',
    'term.4': 'Vulnerable: 0 · Informativos: 3 · Mitigados/N/A: 33',
    'term.5': 'echo status',
    'term.6': 'MODULE_07_CLOSED · GAS_SWC_CLOSED',

    'at.eyebrow': '// 06 — CAMPAÑAS DE ATAQUE',
    'at.title': 'Defensivo, no ofensivo',
    'at.lead':
      'Suites en test/attack, fuzz e invariant: el “éxito” del ataque es que revierte o no drena al siguiente LP. Sin PoCs de exploit.',
    'cA.t': 'First deposit',
    'cA.d': 'Inflation / donation no drena al segundo LP.',
    'cB.t': 'Reentrancy',
    'cB.d': 'Callback malicioso falla con nonReentrant + CEI.',
    'cC.t': 'Slippage',
    'cC.d': 'minSharesOut / minAssetsOut → SlippageExceeded.',
    'cD.t': 'Fuzz / inv',
    'cD.d': 'Solvencia, LP locked, balance vs totalAssets.',
    'cE.t': 'N/A',
    'cE.d': 'Sin ETH, selfdestruct, delegatecall, firmas.',

    're.eyebrow': '// 07 — CÓDIGO ABIERTO',
    're.title': 'Repositorios',
    're.lead':
      'Mismo código en GitHub y GitLab: contratos, tests, GAS-ES.md, SWC-AUDIT-ES.md y demo UI opcional.',
    're.cta': 'Contactar',
    're.linkedin': 'LinkedIn',

    'ft.left': 'ROLANDO STRAHM — Liquidity Pools · Portfolio',
    'ft.right': 'FOUNDRY · SOLC 0.8.24 · ALL_SYSTEMS_OPERATIONAL',
  },

  en: {
    'html.lang': 'en',
    'meta.title': 'Liquidity Pools & Fee Distribution — Rolando Strahm',
    'meta.description':
      'Single-asset LP vault with proportional fees, anti-inflation, documented gas, and SWC audit. Foundry · Solidity 0.8.24.',

    'nav.overview': 'Project',
    'nav.pillars': 'Pillars',
    'nav.gas': 'Gas',
    'nav.swc': 'SWC',
    'nav.process': 'Process',
    'nav.attacks': 'Attacks',
    'nav.repos': 'Repos',
    'nav.close': '← Close',

    'hero.tag': '// MODULE 07 · WEB3 PORTFOLIO',
    'hero.title': 'LIQUIDITY POOLS<br>FEE DISTRIBUTION',
    'hero.role': 'Solidity 0.8.24 · Foundry · Gas · SWC',
    'hero.sub':
      'Single-asset vault with LP shares, proportional fees (UD60x18), anti-inflation, lock time, documented gas, and defensive SWC campaigns.',
    'hero.cta1': 'View on GitHub',
    'hero.cta2': 'View on GitLab',

    'ov.eyebrow': '// 01 — CONTEXT',
    'ov.title': 'Why this project',
    'ov.lead':
      'After the AMM (module 06), I built a <strong>single-asset vault</strong>: deposit underlying, receive LP shares, fees raise the share price. The point is not “another Uniswap” — it is <strong>correct accounting</strong>, <strong>first-depositor anti-inflation</strong>, <strong>gas</strong>, and <strong>SWC</strong> with tests that prove the attack fails.',

    'pi.eyebrow': '// 02 — THREE PILLARS',
    'pi.title': 'What the module ships',
    'p1.num': '// PILLAR_01',
    'p1.title': 'LP vault + fees',
    'p1.desc':
      'LiquidityPool + Factory: deposit/withdraw with slippage, accrueFees, internal LP ERC-20, lock time, and MINIMUM_LIQUIDITY.',
    'p1.l1': 'accFeePerShare UD60x18',
    'p1.l2': 'Burn 1000 wei → address(0)',
    'p1.l3': 'CEI + ReentrancyGuard',
    'p2.num': '// PILLAR_02',
    'p2.title': 'Gas optimization',
    'p2.desc':
      'Immutables, constants, custom SafeTransfer, unchecked after checks, and a Foundry snapshot in doc/GAS-EN.md.',
    'p2.l1': 'underlying / lockDuration immutable',
    'p2.l2': 'Locals cached in _syncFees',
    'p2.l3': '.gas-snapshot + gas-report',
    'p3.num': '// PILLAR_03',
    'p3.title': 'SWC verification',
    'p3.desc':
      'SWC-100–136 matrix, FirstDepositAttack, ReentrancyAttack, fuzz ≥ 1000, and solvency invariants.',
    'p3.l1': '0 exploitable vulnerabilities',
    'p3.l2': '33 mitigated / N/A · 3 info',
    'p3.l3': '78 Foundry tests PASS',

    'gas.eyebrow': '// 03 — GAS OPTIMIZATION',
    'gas.title': 'Cheap hot path, clear tradeoffs',
    'gas.lead':
      'Phase 8: baseline in <code>doc/GAS-EN.md</code> and <code>.gas-snapshot</code>. Medians: <strong>deposit ~177k</strong>, <strong>withdraw ~46k</strong>, <strong>accrueFees ~69k</strong>. Every technique has an explicit tradeoff — no blind micro-savings.',
    'gas.th1': 'Optimization',
    'gas.th2': 'Tradeoff / effect',
    'gas.r1a': 'immutable underlying + lockDuration',
    'gas.r1b': 'Reads ~100 gas vs ~2100 SLOAD; fixed at deploy',
    'gas.r2a': 'constant MINIMUM_LIQUIDITY (1000)',
    'gas.r2b': 'No SLOAD in share/asset conversions',
    'gas.r3a': 'SafeTransfer (call + bubble revert)',
    'gas.r3b': 'SWC-104; propagates guard in reentrancy tests (vs OZ SafeERC20)',
    'gas.r4a': 'unchecked totalAssets +=/−= after checks',
    'gas.r4b': 'Overflow impossible after validation; cheaper hot path',
    'gas.r5a': 'Local caches in _syncFees',
    'gas.r5b': 'Fewer storage reads for balance / supply / assets',
    'gas.r6a': 'Custom errors (external API)',
    'gas.r6b': 'Compact reverts vs require strings',
    'gas.r7a': 'optimizer_runs = 200',
    'gas.r7b': 'Balance deploy (~1M pool) vs frequent runtime',

    'swc.eyebrow': '// 04 — SWC VERIFICATION',
    'swc.title': 'SWC Registry · EIP-1470',
    'swc.lead':
      'Full matrix <strong>SWC-100 → SWC-136</strong> on LiquidityPool / Factory / FixedPointMath. Report: <code>doc/SWC-AUDIT-EN.md</code>. Conclusion: <strong>0 exploitable vulnerabilities</strong> in v1 scope (single-asset).',
    'swc.s1': 'Mitigated / N/A',
    'swc.s2': 'Informational (design)',
    'swc.s3': 'Vulnerable',
    'swc.th1': 'Key SWC',
    'swc.th2': 'Mitigation in the contract',
    'swc.r101': 'Overflow: Solidity 0.8.24 + FixedPointMath.mulDiv with check',
    'swc.r103': 'Floating pragma: fixed pragma solidity 0.8.24',
    'swc.r104': 'Unchecked return: SafeTransfer with bubble-revert',
    'swc.r107': 'Reentrancy: CEI + nonReentrant; ReentrancyAttack suite',
    'swc.r114': 'Tx order / MEV: minSharesOut · minAssetsOut + lock time',
    'swc.r123': 'Requirements: custom errors + unit/fuzz/invariant/attack',
    'swc.info': 'INFORMATIONAL',
    'swc.i1t': 'MEV on deposit/withdraw',
    'swc.i1d':
      'A front-run can move share price between preview and tx. Mitigation: on-chain slippage + lockDuration.',
    'swc.i2t': 'Donation / first deposit',
    'swc.i2d':
      'Explicit totalAssets accounting + MINIMUM_LIQUIDITY to address(0). Covered by FirstDepositAttack.',

    'pr.eyebrow': '// 05 — PROCESS',
    'pr.title': 'Phases 0–8 closed',
    'pr.lead':
      'Gate-based TDD: scaffold, red tests, FixedPointMath, deposit, withdraw, fees, factory, fuzz/invariant/attack, gas + SafeTransfer.',
    'ph.02': 'Scaffold + TDD + FixedPoint',
    'ph.34': 'deposit + withdraw + lock',
    'ph.56': 'fees + Factory / Deploy',
    'ph.7': 'Fuzz · invariant · attack · SWC',
    'ph.8': 'Gas snapshot + SafeTransfer',
    'st.1': 'Phases',
    'st.2': 'Tests PASS',
    'st.3': 'Critical SWC',
    'st.4': 'Attack suites',
    'term.label': 'rolando@strahm:~/07-liquidity-pools',
    'term.1': 'forge test',
    'term.2': '[PASS] suite · 78 passed',
    'term.3': 'cat doc/SWC-AUDIT-EN.md | head',
    'term.4': 'Vulnerable: 0 · Informational: 3 · Mitigated/N/A: 33',
    'term.5': 'echo status',
    'term.6': 'MODULE_07_CLOSED · GAS_SWC_CLOSED',

    'at.eyebrow': '// 06 — ATTACK CAMPAIGNS',
    'at.title': 'Defensive, not offensive',
    'at.lead':
      'Suites under test/attack, fuzz, and invariant: a successful “attack” means it reverts or fails to drain the next LP. No exploit PoCs.',
    'cA.t': 'First deposit',
    'cA.d': 'Inflation / donation does not drain the second LP.',
    'cB.t': 'Reentrancy',
    'cB.d': 'Malicious callback fails with nonReentrant + CEI.',
    'cC.t': 'Slippage',
    'cC.d': 'minSharesOut / minAssetsOut → SlippageExceeded.',
    'cD.t': 'Fuzz / inv',
    'cD.d': 'Solvency, locked LP, balance vs totalAssets.',
    'cE.t': 'N/A',
    'cE.d': 'No ETH, selfdestruct, delegatecall, signatures.',

    're.eyebrow': '// 07 — OPEN SOURCE',
    're.title': 'Repositories',
    're.lead':
      'Same codebase on GitHub and GitLab: contracts, tests, GAS-EN.md, SWC-AUDIT-EN.md, and optional UI demo.',
    're.cta': 'Contact',
    're.linkedin': 'LinkedIn',

    'ft.left': 'ROLANDO STRAHM — Liquidity Pools · Portfolio',
    'ft.right': 'FOUNDRY · SOLC 0.8.24 · ALL_SYSTEMS_OPERATIONAL',
  },
};

function setLanguage(lang) {
  const dict = I18N[lang] || I18N.es;
  document.documentElement.lang = dict['html.lang'];
  document.title = dict['meta.title'];

  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc && dict['meta.description']) {
    metaDesc.setAttribute('content', dict['meta.description']);
  }

  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    const val = dict[key];
    if (val == null) return;
    if (el.hasAttribute('data-i18n-html')) el.innerHTML = val;
    else el.textContent = val;
  });

  document.querySelectorAll('.lang-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.lang === lang);
  });

  localStorage.setItem('lp-portfolio-lang', lang);

  const url = new URL(window.location.href);
  url.searchParams.set('lang', lang);
  history.replaceState(null, '', url);
}

function initI18n() {
  const params = new URLSearchParams(window.location.search);
  const fromQuery = params.get('lang');
  const saved = localStorage.getItem('lp-portfolio-lang');
  const preferred =
    (fromQuery === 'en' || fromQuery === 'es' ? fromQuery : null) ||
    saved ||
    (navigator.language?.startsWith('en') ? 'en' : 'es');

  setLanguage(preferred);

  document.querySelectorAll('.lang-btn').forEach((btn) => {
    btn.addEventListener('click', () => setLanguage(btn.dataset.lang));
  });
}

document.addEventListener('DOMContentLoaded', initI18n);
