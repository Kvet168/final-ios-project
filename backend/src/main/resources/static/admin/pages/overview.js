import { h, money, num, table } from '/dashboard/js/ui.js';

const SVG = 'http://www.w3.org/2000/svg';

function barChart(points) {
  const w = 600, hgt = 150, pad = 20;
  const svg = document.createElementNS(SVG, 'svg');
  svg.setAttribute('viewBox', `0 0 ${w} ${hgt + 20}`);
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', 'Bookings per day over the last 30 days');
  const max = Math.max(1, ...points.map((p) => p.bookings));
  const bw = (w - pad * 2) / Math.max(points.length, 1);
  const axis = document.createElementNS(SVG, 'line');
  for (const [k, v] of Object.entries({ x1: pad, x2: w - pad, y1: hgt, y2: hgt, class: 'axis' })) axis.setAttribute(k, v);
  svg.append(axis);
  points.forEach((p, i) => {
    const bh = (p.bookings / max) * (hgt - 14);
    const r = document.createElementNS(SVG, 'rect');
    for (const [k, v] of Object.entries({ x: pad + i * bw + 2, y: hgt - bh, width: Math.max(2, bw - 4), height: bh, rx: 3, class: 'bar' })) r.setAttribute(k, v);
    const t = document.createElementNS(SVG, 'title');
    t.textContent = `${p.day}: ${p.bookings} booking${p.bookings === 1 ? '' : 's'}`;
    r.append(t);
    svg.append(r);
  });
  [points[0], points[points.length - 1]].filter(Boolean).forEach((p, i) => {
    const t = document.createElementNS(SVG, 'text');
    t.setAttribute('x', i === 0 ? pad : w - pad);
    t.setAttribute('y', hgt + 14);
    t.setAttribute('text-anchor', i === 0 ? 'start' : 'end');
    t.textContent = p.day;
    svg.append(t);
  });
  return svg;
}

export async function overviewPage({ api }) {
  const o = await api.get('/admin/overview');
  const c = o.counts;
  const stat = (label, value, hint) => h('div', { class: 'card stat' }, h('div', { class: 'label' }, label), h('div', { class: 'value' }, value), hint ? h('div', { class: 'hint' }, hint) : null);
  const total = Math.max(1, ...o.bookingsByStatus.map((s) => s.count));
  return h('div', { class: 'stack' },
    h('div', { class: 'stats' },
      stat('Users', num(c.users)), stat('Bookings', num(c.bookings), `${num(o.bookingsByStatus.find((s) => s.status === 'CONFIRMED')?.count ?? 0)} confirmed`),
      stat('Revenue', money(o.revenueSimulatedUsd.usd), 'simulated payments only'), stat('Hotels', num(c.accommodations), `${num(c.room_types)} room types`),
      stat('Destinations', num(c.destinations), `${num(c.attractions)} places`), stat('Reviews', num(c.reviews)), stat('Trips saved', num(c.itineraries))),
    h('div', { class: 'grid-2' },
      h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Bookings by status')),
        h('div', { class: 'bars' }, o.bookingsByStatus.length ? o.bookingsByStatus.map((s) => h('div', { class: 'bar-row' }, h('span', {}, s.status.replaceAll('_', ' ').toLowerCase()),
          h('div', { class: 'bar-track' }, h('div', { class: 'bar-fill', style: `width:${(s.count / total) * 100}%` })), h('span', { class: 'right' }, num(s.count)))) : h('div', { class: 'empty' }, 'No bookings yet'))),
      h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Bookings, last 30 days')),
        h('div', { class: 'chart' }, o.bookingsLast30Days.length ? barChart(o.bookingsLast30Days) : h('div', { class: 'empty' }, 'No bookings in the last 30 days')))),
    h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'AI usage')),
      table({ empty: 'No AI calls yet', columns: [{ label: 'Feature', key: 'kind' }, { label: 'Mode', key: 'mode' }, { label: 'Calls', num: true, render: (r) => num(r.calls) }, { label: 'Avg latency', num: true, render: (r) => `${r.avg_ms ?? '-'} ms` }], rows: o.aiUsage })),
    h('p', { class: 'muted small' }, o.note));
}
