import { dateTime, debounce, h, pager, table } from '/dashboard/js/ui.js';

export function auditPage({ api }) {
  const state = { page: 1, action: '' };
  const box = h('div', { class: 'card' });
  async function load() {
    const r = await api.get('/admin/audit-logs', { page: state.page, pageSize: 20, action: state.action });
    box.replaceChildren(table({ empty: 'No audit records', columns: [
      { label: 'When', render: (l) => dateTime(l.created_at) }, { label: 'Action', render: (l) => h('span', { class: 'mono' }, l.action) },
      { label: 'Who', render: (l) => l.actor_email || 'system' }, { label: 'Entity', render: (l) => `${l.entity}${l.entity_id ? ` ${String(l.entity_id).slice(0, 8)}` : ''}` },
      { label: 'Details', render: (l) => h('span', { class: 'mono muted' }, JSON.stringify(l.meta)) }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } }));
  }
  const search = debounce((v) => { state.action = v; state.page = 1; load(); });
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' }, h('div', { class: 'toolbar' }, h('input', { class: 'input', type: 'search', placeholder: 'Filter by action, e.g. booking', 'aria-label': 'Filter by action', oninput: (e) => search(e.target.value) })), box);
}
