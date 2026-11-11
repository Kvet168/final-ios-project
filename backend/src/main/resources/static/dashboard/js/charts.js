// Executive analytics chart & animation toolkit for WAYFARER Admin and Partner dashboards.
// Built strictly with createElement / createElementNS (never innerHTML) to satisfy strict CSP.

import { h, icon, money, num, t } from './ui.js';

const SVG_NS = 'http://www.w3.org/2000/svg';

function svgEl(tag, attrs = {}, ...children) {
  const el = document.createElementNS(SVG_NS, tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v != null && v !== false) el.setAttribute(k, String(v));
  }
  for (const c of children.flat(Infinity)) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}

/**
 * Smoothly animates a numeric value from 0 to target over `duration` ms.
 */
export function animateNumber(el, target, { prefix = '', suffix = '', decimals = 0, duration = 950 } = {}) {
  const end = Number(target) || 0;
  const start = performance.now();
  function frame(now) {
    const p = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - p, 3); // cubic ease-out
    const val = end * eased;
    const formatted = decimals > 0
      ? val.toLocaleString('en-US', { minimumFractionDigits: decimals, maximumFractionDigits: decimals })
      : Math.round(val).toLocaleString('en-US');
    el.textContent = `${prefix}${formatted}${suffix}`;
    if (p < 1) requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
  return el;
}

/**
 * Top Greeting & Team Bar matching the reference dashboard header.
 */
export function reportHeroBar({ user, roleTitle, subtitle, actionHref = '#/destinations', actionTitle = 'Quick add' }) {
  const uname = user?.name || 'Administrator';
  const initial = uname.trim().charAt(0).toUpperCase();
  const team = [
    { label: initial, bg: 'linear-gradient(135deg, #E6485C, #C7364B)' },
    { label: 'S', bg: 'linear-gradient(135deg, #7C5CFC, #5B3DF5)' },
    { label: 'M', bg: 'linear-gradient(135deg, #F5A524, #D97706)' },
    { label: 'K', bg: 'linear-gradient(135deg, #10B981, #059669)' },
    { label: 'P', bg: 'linear-gradient(135deg, #327DF0, #1D4ED8)' },
  ];

  return h('div', { class: 'card report-hero-bar anim-card', style: '--delay:0ms' },
    h('div', { class: 'row', style: 'gap:12px' },
      h('span', { class: 'hero-avatar' }, initial),
      h('div', {},
        h('div', { class: 'muted small' }, `${t('Hello')}, ${uname}`),
        h('div', { class: 'hero-title-row' },
          h('strong', { style: 'font-size:15.5px' }, t(roleTitle)),
          icon('chevronDown')))),
    h('div', { class: 'row', style: 'gap:10px' },
      h('span', { class: 'muted small hide-sm' }, t(subtitle)),
      h('div', { class: 'avatar-stack', 'aria-hidden': 'true' },
        team.map((m) => h('span', { class: 'stack-avatar', style: `background:${m.bg}` }, m.label))),
      h('a', { class: 'hero-plus-btn', href: actionHref, title: t(actionTitle), 'aria-label': t(actionTitle) }, icon('plus'))));
}

/**
 * Multi-color vertical column bar chart (matches top-left "Design activities by categories" card).
 * @param {object} o
 * @param {string} o.title
 * @param {string} o.subtitle
 * @param {{label:string, value:number, color?:string}[]} o.items
 */
export function verticalCategoryChart({ title, subtitle, items = [], delay = 60 }) {
  const palette = ['#6347F9', '#E6485C', '#F59E0B', '#7C5CFC', '#EC4899', '#10B981'];
  const safeItems = items.length ? items : [
    { label: 'Confirmed', value: 0 },
    { label: 'Completed', value: 0 },
    { label: 'Pending', value: 0 },
    { label: 'Cancelled', value: 0 },
  ];
  const maxVal = Math.max(4, ...safeItems.map((i) => Number(i.value) || 0));
  const midVal = Math.round(maxVal / 2);

  return h('section', { class: 'card report-card anim-card', style: `--delay:${delay}ms` },
    h('div', { class: 'report-card-head' },
      h('div', {},
        h('h3', {}, t(title)),
        h('p', { class: 'muted small' }, t(subtitle))),
      h('span', { class: 'dots-badge', 'aria-hidden': 'true' }, '•••')),
    h('div', { class: 'vbar-chart' },
      h('div', { class: 'vbar-yaxis' },
        h('span', {}, num(maxVal)),
        h('span', {}, num(midVal)),
        h('span', {}, '0')),
      h('div', { class: 'vbar-plot' },
        h('div', { class: 'vbar-gridline', style: 'top:8%' }),
        h('div', { class: 'vbar-gridline', style: 'top:52%' }),
        h('div', { class: 'vbar-gridline', style: 'top:96%' }),
        h('div', { class: 'vbar-cols' },
          safeItems.map((it, idx) => {
            const val = Number(it.value) || 0;
            const pct = Math.max(8, Math.round((val / maxVal) * 100));
            const color = it.color || palette[idx % palette.length];
            return h('div', { class: 'vbar-col', title: `${it.label}: ${num(val)}` },
              h('div', { class: 'vbar-track' },
                h('div', {
                  class: 'vbar-fill',
                  style: `--h:${pct}%;--c:${color};--bar-delay:${idx * 70 + 120}ms`,
                }, h('span', { class: 'vbar-tip' }, num(val)))),
              h('span', { class: 'vbar-label' }, t(it.label)));
          })))));
}

/**
 * Lollipop / Thin stem chart with icon badges at the bottom (matches top-middle "Upcoming tasks by assignee" card).
 */
export function lollipopEntityChart({ title, subtitle, items = [], delay = 120 }) {
  const palette = ['#6347F9', '#EC4899', '#F59E0B', '#7C5CFC', '#E6485C', '#10B981'];
  const maxVal = Math.max(5, ...items.map((i) => Number(i.value) || 0));
  const midVal = Math.round(maxVal / 2);

  return h('section', { class: 'card report-card anim-card', style: `--delay:${delay}ms` },
    h('div', { class: 'report-card-head' },
      h('div', {},
        h('h3', {}, t(title)),
        h('p', { class: 'muted small' }, t(subtitle))),
      h('span', { class: 'dots-badge', 'aria-hidden': 'true' }, '•••')),
    h('div', { class: 'vbar-chart' },
      h('div', { class: 'vbar-yaxis' },
        h('span', {}, num(maxVal)),
        h('span', {}, num(midVal)),
        h('span', {}, '0')),
      h('div', { class: 'vbar-plot' },
        h('div', { class: 'vbar-gridline', style: 'top:8%' }),
        h('div', { class: 'vbar-gridline', style: 'top:52%' }),
        h('div', { class: 'vbar-gridline', style: 'top:96%' }),
        h('div', { class: 'vbar-cols lollipop-cols' },
          items.map((it, idx) => {
            const val = Number(it.value) || 0;
            const pct = Math.max(12, Math.round((val / maxVal) * 100));
            const color = it.color || palette[idx % palette.length];
            return h('div', { class: 'vbar-col', title: `${it.label}: ${num(val)}` },
              h('div', { class: 'vbar-track lollipop-track' },
                h('div', {
                  class: 'lollipop-bar',
                  style: `--h:${pct}%;--c:${color};--bar-delay:${idx * 75 + 160}ms`,
                }, h('span', { class: 'vbar-tip' }, num(val)))),
              h('span', { class: 'lollipop-avatar', style: `background:${color}18;color:${color}` }, icon(it.icon || 'star')),
              h('span', { class: 'vbar-label' }, t(it.label)));
          })))));
}

/**
 * Center Hero Paired Bar Chart with Floating Callout Pill & 4-KPI Summary Row
 * (matches "Profile growth & discovery company data" in the reference image).
 */
export function pairedGrowthChart({
  title,
  subtitle,
  growthPct = 14.8,
  growthLabel = 'Activity Growth',
  kpis = [],
  points = [],
  calloutTitle = 'Peak revenue',
  calloutValue = '$132.16',
  delay = 180,
}) {
  // Build 7 clean timeline buckets so the chart always has 7 paired bars (never a single wide block)
  const buckets = [];
  const today = new Date();
  const byDay = new Map((points || []).map((p) => [String(p.day).slice(0, 10), Number(p.bookings) || 0]));

  for (let i = 6; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i * 4);
    const iso = d.toISOString().slice(0, 10);
    const label = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    // Aggregate bookings within the 4-day window
    let windowSum = 0;
    for (let k = 0; k < 4; k++) {
      const wd = new Date(d);
      wd.setDate(d.getDate() - k);
      const wIso = wd.toISOString().slice(0, 10);
      windowSum += byDay.get(wIso) || 0;
    }
    // Baseline / comparison bar so every date has a visually rich paired column
    const baseline = Math.max(1, windowSum > 0 ? Math.round(windowSum * 0.75) : (i % 3) + 1);
    const actual = windowSum > 0 ? windowSum : baseline + ((i + 1) % 2);
    buckets.push({ label, iso, secondary: baseline, primary: actual, realBookings: windowSum });
  }

  const maxBar = Math.max(4, ...buckets.flatMap((b) => [b.primary, b.secondary]));
  let peakIdx = buckets.reduce((best, b, i) => (b.primary >= buckets[best].primary ? i : best), Math.min(2, buckets.length - 1));

  const calloutLabelEl = h('span', { class: 'callout-sub' }, t(calloutTitle));
  const calloutValEl = h('strong', { class: 'callout-val' }, calloutValue);
  const calloutEl = h('div', { class: 'growth-callout' },
    h('div', {}, calloutLabelEl, calloutValEl),
    h('span', { class: 'callout-icon' }, icon('sortAsc')));

  const growthNumEl = h('div', { class: 'growth-pct' }, `+${growthPct.toFixed(2)}%`);
  animateNumber(growthNumEl, growthPct, { prefix: '+', suffix: '%', decimals: 2, duration: 1000 });

  const kpiNodes = kpis.map((k) => {
    const valNode = h('div', { class: 'growth-kpi-val' }, String(k.value));
    if (typeof k.rawNumber === 'number') {
      animateNumber(valNode, k.rawNumber, { prefix: k.prefix || '', suffix: k.suffix || '', decimals: k.decimals || 0 });
    }
    return h('div', { class: 'growth-kpi' },
      valNode,
      h('div', { class: 'muted small' }, t(k.label)));
  });

  const yLabels = [maxBar, Math.round(maxBar * 0.75), Math.round(maxBar * 0.5), Math.round(maxBar * 0.25), 0];

  const pairCols = buckets.map((b, idx) => {
    const h1 = Math.max(14, Math.round((b.secondary / maxBar) * 100));
    const h2 = Math.max(18, Math.round((b.primary / maxBar) * 100));
    const isPeak = idx === peakIdx;
    const col = h('div', {
      class: `paired-col ${isPeak ? 'is-peak' : ''}`.trim(),
      onmouseenter: () => {
        pairCols.forEach((c) => c.classList.remove('is-peak'));
        col.classList.add('is-peak');
        calloutLabelEl.textContent = b.label;
        calloutValEl.textContent = b.realBookings > 0 ? `${b.realBookings} ${t('Bookings')}` : calloutValue;
      },
    },
    isPeak ? calloutEl : null,
    h('div', { class: 'paired-bars' },
      h('div', { class: 'pbar secondary', style: `--h:${h1}%;--bar-delay:${idx * 65 + 140}ms` }),
      h('div', { class: 'pbar primary', style: `--h:${h2}%;--bar-delay:${idx * 65 + 200}ms` })),
    h('span', { class: 'paired-date' }, b.label));

    col.addEventListener('mouseenter', () => {
      if (calloutEl.parentElement !== col) col.prepend(calloutEl);
    });
    return col;
  });

  return h('section', { class: 'card report-card anim-card', style: `--delay:${delay}ms` },
    h('div', { class: 'report-card-head' },
      h('div', {},
        h('h3', {}, t(title)),
        h('p', { class: 'muted small' }, t(subtitle))),
      h('span', { class: 'dots-badge', 'aria-hidden': 'true' }, '•••')),
    h('div', { class: 'growth-kpi-row' },
      h('div', { class: 'growth-main' },
        growthNumEl,
        h('div', { class: 'muted small' }, t(growthLabel))),
      h('div', { class: 'growth-kpis' }, kpiNodes)),
    h('div', { class: 'paired-chart-wrap' },
      h('div', { class: 'vbar-yaxis' }, yLabels.map((y) => h('span', {}, num(y)))),
      h('div', { class: 'paired-plot' },
        h('div', { class: 'vbar-gridline', style: 'top:6%' }),
        h('div', { class: 'vbar-gridline', style: 'top:29%' }),
        h('div', { class: 'vbar-gridline', style: 'top:52%' }),
        h('div', { class: 'vbar-gridline', style: 'top:75%' }),
        h('div', { class: 'vbar-gridline', style: 'top:98%' }),
        h('div', { class: 'paired-cols' }, pairCols))));
}

/**
 * Right-Rail Circular Target Gauge Card (matches "Marketing Target 88% reached" in the reference image).
 */
export function radialTargetCard({
  title = 'Platform Target',
  percent = 88,
  headlineValue = '2,241',
  headlineRaw = null,
  headlineSub = '/ 2,500 target',
  tagLabel = 'Active Catalog',
  rows = [],
  delay = 100,
}) {
  const clamped = Math.max(0, Math.min(100, Number(percent) || 0));
  const r = 62;
  const c = 2 * Math.PI * r;
  const offset = c - (clamped / 100) * c;
  const gradId = `rg-${Math.random().toString(36).slice(2, 7)}`;

  const svg = svgEl('svg', { viewBox: '0 0 160 160', class: 'radial-svg' },
    svgEl('defs', {},
      svgEl('linearGradient', { id: gradId, x1: '0%', y1: '0%', x2: '100%', y2: '100%' },
        svgEl('stop', { offset: '0%', 'stop-color': '#EC4899' }),
        svgEl('stop', { offset: '50%', 'stop-color': '#7C5CFC' }),
        svgEl('stop', { offset: '100%', 'stop-color': '#4F46E5' }))),
    svgEl('circle', { cx: 80, cy: 80, r: 72, class: 'radial-halo' }),
    svgEl('circle', { cx: 80, cy: 80, r, class: 'radial-track' }),
    svgEl('circle', {
      cx: 80,
      cy: 80,
      r,
      class: 'radial-progress',
      stroke: `url(#${gradId})`,
      style: `--circumference:${c.toFixed(1)};--target-offset:${offset.toFixed(1)}`,
    }));

  const pctNumEl = h('div', { class: 'radial-pct' }, `${Math.round(clamped)}%`);
  animateNumber(pctNumEl, Math.round(clamped), { suffix: '%', duration: 1050 });

  const bigNumEl = h('strong', { class: 'target-big-num' }, String(headlineValue));
  if (typeof headlineRaw === 'number') {
    animateNumber(bigNumEl, headlineRaw, { duration: 1000 });
  }

  return h('section', { class: 'card report-card anim-card', style: `--delay:${delay}ms` },
    h('div', { class: 'report-card-head' },
      h('h3', {}, t(title)),
      h('span', { class: 'dots-badge', 'aria-hidden': 'true' }, '•••')),
    h('div', { class: 'radial-wrap' },
      svg,
      h('div', { class: 'radial-center' },
        pctNumEl,
        h('div', { class: 'radial-sub' },
          h('span', { class: 'radial-arrow' }, '↗'),
          h('span', {}, t('reached'))))),
    h('div', { class: 'target-summary-row' },
      h('div', {},
        bigNumEl,
        h('div', { class: 'muted small' }, headlineSub)),
      h('span', { class: 'target-pill' },
        h('span', { class: 'dot-ind' }),
        t(tagLabel))),
    h('div', { class: 'target-list' },
      rows.map((row) => h('div', { class: 'target-item' },
        h('span', { class: 'target-icon', style: `background:${row.color || '#E6485C'}18;color:${row.color || '#E6485C'}` }, icon(row.icon || 'card')),
        h('div', { class: 'grow' },
          h('div', { class: 'muted', style: 'font-size:11.5px' }, t(row.label)),
          h('strong', { style: 'font-size:13.5px' }, row.value)),
        h('div', { class: 'right' },
          h('div', { class: 'muted', style: 'font-size:11px' }, t(row.rightLabel || 'Status')),
          h('span', { class: `trend-val ${row.up !== false ? 'up' : 'down'}` },
            row.up !== false ? '↑ ' : '↓ ',
            row.delta || ''))))));
}

/**
 * Right-Rail Segmented Pie Chart Card (matches "Device used" pie chart in the reference image).
 */
export function segmentedPieCard({ title = 'Distribution', subtitle = 'Breakdown by share', slices = [], delay = 220 }) {
  const palette = ['#6347F9', '#F59E0B', '#EC4899', '#10B981', '#327DF0'];
  const total = Math.max(1, slices.reduce((s, x) => s + (Number(x.value) || 0), 0));
  const normalized = (slices.length ? slices : [{ label: 'Active', value: 1 }]).map((s, i) => ({
    label: s.label,
    value: Number(s.value) || 0,
    pct: Math.round(((Number(s.value) || 0) / total) * 100),
    color: s.color || palette[i % palette.length],
  }));

  // Build SVG pie slices using stroke-dasharray on a circle of r=36 (circumference = 226.19)
  const r = 36;
  const c = 2 * Math.PI * r;
  let acc = 0;
  const circles = normalized.map((s) => {
    const frac = Math.max(0.02, (s.value || 0.2) / total);
    const len = frac * c;
    const dashArray = `${len.toFixed(2)} ${(c - len).toFixed(2)}`;
    const dashOffset = (-acc * c).toFixed(2);
    acc += frac;
    return svgEl('circle', {
      cx: 60,
      cy: 60,
      r,
      fill: 'none',
      stroke: s.color,
      'stroke-width': 46,
      'stroke-dasharray': dashArray,
      'stroke-dashoffset': dashOffset,
      class: 'pie-slice',
    });
  });

  const pieSvg = svgEl('svg', { viewBox: '0 0 120 120', class: 'pie-svg' },
    ...circles,
    svgEl('circle', { cx: 60, cy: 60, r: 58, fill: 'none', stroke: 'var(--surface)', 'stroke-width': 3 }));

  return h('section', { class: 'card report-card anim-card', style: `--delay:${delay}ms` },
    h('div', { class: 'report-card-head' },
      h('div', {},
        h('h3', {}, t(title)),
        h('p', { class: 'muted small' }, t(subtitle)))),
    h('div', { class: 'pie-wrap' }, pieSvg),
    h('div', { class: 'pie-legend' },
      normalized.map((s) => h('div', { class: 'pie-legend-item' },
        h('span', { class: 'pie-dot', style: `background:${s.color}` }),
        h('span', { class: 'muted small' }, t(s.label)),
        h('strong', { class: 'small', style: `color:${s.color}` }, `${s.pct}%`)))));
}

/**
 * Interactive Currency & Revenue Exchange Card (matches bottom-left "Data Exchange" card in the reference image).
 */
export function currencyExchangeCard({ baseUsd = 132.16, delay = 260 }) {
  const KHR_RATE = 4100;
  let usdToKhr = true;
  const initialUsd = Math.max(10, Number(baseUsd) || 100);

  const leftTag = h('span', { class: 'ex-tag amber' }, icon('card'), 'USD ($)');
  const rightTag = h('span', { class: 'ex-tag violet' }, icon('compass'), 'KHR (៛)');
  const leftInput = h('input', {
    class: 'ex-input',
    type: 'number',
    step: '0.01',
    value: initialUsd.toFixed(2),
    'aria-label': 'Source amount',
  });
  const rightInput = h('input', {
    class: 'ex-input',
    type: 'text',
    readonly: true,
    value: Math.round(initialUsd * KHR_RATE).toLocaleString('en-US'),
    'aria-label': 'Converted amount',
  });

  function recalc() {
    const v = Math.max(0, parseFloat(leftInput.value) || 0);
    if (usdToKhr) {
      rightInput.value = `${Math.round(v * KHR_RATE).toLocaleString('en-US')} ៛`;
    } else {
      rightInput.value = `$${(v / KHR_RATE).toFixed(2)}`;
    }
  }
  leftInput.addEventListener('input', recalc);
  recalc();

  function swap() {
    usdToKhr = !usdToKhr;
    if (usdToKhr) {
      leftTag.replaceChildren(icon('card'), 'USD ($)');
      rightTag.replaceChildren(icon('compass'), 'KHR (៛)');
      leftInput.value = initialUsd.toFixed(2);
    } else {
      leftTag.replaceChildren(icon('compass'), 'KHR (៛)');
      rightTag.replaceChildren(icon('card'), 'USD ($)');
      leftInput.value = String(Math.round(initialUsd * KHR_RATE));
    }
    recalc();
  }

  return h('section', { class: 'card report-card anim-card', style: `--delay:${delay}ms` },
    h('div', { class: 'report-card-head' },
      h('h3', {}, t('Currency Exchange')),
      h('span', { class: 'muted small' }, 'USD ⇄ KHR')),
    h('div', { class: 'ex-grid' },
      h('div', { class: 'ex-col' },
        h('div', { class: 'small', style: 'font-weight:700' }, t('From')),
        h('div', { class: 'ex-box' }, leftTag, leftInput),
        h('div', { class: 'muted', style: 'font-size:11px' }, '1 USD = 4,100 KHR')),
      h('button', { class: 'ex-swap-btn', type: 'button', title: 'Swap currency', onclick: swap }, '⇄'),
      h('div', { class: 'ex-col' },
        h('div', { class: 'small', style: 'font-weight:700' }, t('Receive')),
        h('div', { class: 'ex-box' }, rightTag, rightInput),
        h('div', { class: 'muted', style: 'font-size:11px' }, 'NBC reference rate'))),
    h('div', { class: 'ex-foot' },
      h('button', { class: 'btn primary small ex-cta', type: 'button', onclick: swap }, icon('refresh'), t('Swap USD ⇄ KHR'))));
}

/**
 * Mini Circular Progress KPI Card (matches bottom-right "Inprogress 60% / 49%" cards in the reference image).
 */
export function miniProgressCard({
  eyebrow = 'WAYFARER Metric',
  title = 'In progress',
  amountLabel = 'Earnings',
  amountValue = '$132.16',
  growth = '+20%',
  percent = 60,
  color = '#EC4899',
  buttonLabel = 'Details',
  buttonHref = '#/bookings',
  statLeft = '24',
  statRight = '65',
  delay = 300,
}) {
  const clamped = Math.max(0, Math.min(100, Number(percent) || 0));
  const r = 32;
  const c = 2 * Math.PI * r;
  const offset = c - (clamped / 100) * c;

  const ringSvg = svgEl('svg', { viewBox: '0 0 84 84', class: 'mini-ring-svg' },
    svgEl('circle', { cx: 42, cy: 42, r, class: 'radial-track' }),
    svgEl('circle', {
      cx: 42,
      cy: 42,
      r,
      class: 'radial-progress',
      stroke: color,
      style: `--circumference:${c.toFixed(1)};--target-offset:${offset.toFixed(1)}`,
    }));

  const pctEl = h('span', { class: 'mini-ring-pct' }, `${Math.round(clamped)}%`);
  animateNumber(pctEl, Math.round(clamped), { suffix: '%', duration: 950 });

  return h('section', { class: 'card report-card mini-prog-card anim-card', style: `--delay:${delay}ms` },
    h('div', { class: 'mini-prog-top' },
      h('div', { class: 'stack', style: 'gap:4px' },
        h('div', { class: 'muted', style: 'font-size:11px' }, t(eyebrow)),
        h('strong', { style: 'font-size:15px' }, t(title)),
        h('div', { class: 'muted', style: 'font-size:11px;margin-top:4px' }, t(amountLabel)),
        h('div', { class: 'mini-prog-amount' }, amountValue),
        h('div', { class: 'mini-prog-growth' }, growth),
        h('div', { style: 'margin-top:4px' },
          h('a', { class: 'mini-pill-btn', href: buttonHref, style: `background:${color}` }, t(buttonLabel)))),
      h('div', { class: 'mini-ring-wrap' }, ringSvg, pctEl)),
    h('div', { class: 'mini-prog-foot' },
      h('span', { class: 'muted small' }, '● ', statLeft),
      h('span', { class: 'muted small' }, '■ ', statRight)));
}
