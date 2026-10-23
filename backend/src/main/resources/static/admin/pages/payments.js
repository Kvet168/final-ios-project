import { badge, dateTime, h, money, pager, select, table } from '/dashboard/js/ui.js';

export function paymentsPage({ api }) {
  const state = { page: 1, status: '' };
  const box = h('div', { class: 'card' });
  async function load() {
    const r = await api.get('/admin/payments', { page: state.page, pageSize: 15, status: state.status });
    box.replaceChildren(table({ empty: 'No payments', columns: [
      { label: 'Booking', render: (p) => h('span', { class: 'mono' }, p.reference) }, { label: 'Provider ref', render: (p) => h('span', { class: 'mono' }, p.provider_ref) },
      { label: 'Amount', num: true, render: (p) => money(p.amount_usd) }, { label: 'Refunded', num: true, render: (p) => (Number(p.refunded_usd) ? money(p.refunded_usd) : '-') },
      { label: 'Mode', render: (p) => (p.simulated ? h('span', { class: 'badge neutral' }, 'simulated') : p.provider) }, { label: 'Status', render: (p) => badge(p.status) },
      { label: 'When', render: (p) => dateTime(p.created_at) }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } }));
  }
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' }, h('div', { class: 'toolbar' }, select([['', 'All statuses'], 'PENDING', 'SUCCESS', 'FAILED', 'CANCELLED', 'REFUNDED'], state.status,
    { 'aria-label': 'Status', onchange: (e) => { state.status = e.target.value; state.page = 1; load(); } })), box);
}
