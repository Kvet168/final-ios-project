import { badge, dateTime, h, table } from '/dashboard/js/ui.js';

export async function aiPage({ api }) {
  const r = await api.get('/admin/ai-usage');
  return h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Latest 100 AI calls')),
    table({ empty: 'No AI calls yet', columns: [{ label: 'When', render: (e) => dateTime(e.created_at) }, { label: 'Feature', key: 'kind' }, { label: 'Mode', render: (e) => badge(e.mode) },
      { label: 'Provider', render: (e) => e.provider || 'none (rules)' }, { label: 'Latency', num: true, render: (e) => `${e.latency_ms ?? '-'} ms` },
      { label: 'Result', render: (e) => h('span', { class: `badge ${e.ok ? 'ok' : 'warn'}` }, e.ok ? 'grounded' : 'no answer') }], rows: r.items }));
}
