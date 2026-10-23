// Bookings list and detail, shared by the admin console and the partner dashboard (they differ only in endpoints and allowed actions).
import { badge, confirmDialog, date, dateTime, debounce, h, modal, money, pager, select, table, toast } from './ui.js';

/**
 * @param {object} o
 * @param {'admin'|'partner'} o.scope
 */
export function bookingsPage({ api, scope, refresh }) {
  const state = { page: 1, status: '', q: '' };
  const box = h('div', { class: 'card' });
  const list = scope === 'admin' ? '/admin/bookings' : '/partner/bookings';
  const statuses = ['', 'PENDING_CONFIRMATION', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED', 'EXPIRED', 'REFUNDED'];

  async function load() {
    const r = await api.get(list, { page: state.page, pageSize: 15, status: state.status, q: scope === 'admin' ? state.q : undefined });
    box.replaceChildren(
      table({
        empty: 'No bookings match these filters',
        onRowClick: (b) => openDetail(b.id),
        columns: [
          { label: 'Reference', render: (b) => h('span', { class: 'mono' }, b.reference) },
          { label: 'Guest', render: (b) => h('div', {}, b.guest_name, b.guest_email ? h('div', { class: 'muted small' }, b.guest_email) : null) },
          { label: 'Hotel', render: (b) => b.accommodation_name },
          { label: 'Stay', render: (b) => `${date(b.check_in)} to ${date(b.check_out)}` },
          { label: 'Total', num: true, render: (b) => money(b.total_usd) },
          { label: 'Status', render: (b) => badge(b.status) },
        ],
        rows: r.items,
      }),
      pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load().catch(fail); } }));
  }
  const fail = (e) => box.replaceChildren(h('div', { class: 'empty', role: 'alert' }, e.message));

  async function openDetail(id) {
    const b = await api.get(`/bookings/${id}`).catch((e) => { toast(e.message, 'bad'); return null; });
    if (!b) return;
    const act = async (label, fn) => {
      try { await fn(); toast(label, 'ok'); m.close(); await load(); } catch (e) { toast(e.message, 'bad'); }
    };
    const transition = (to, label) => h('button', { class: 'btn primary', type: 'button', onclick: () => act(label, () => api.post(`/${scope}/bookings/${id}/transition`, { to })) }, label);
    const actions = [];
    if (b.status === 'CONFIRMED') actions.push(transition('CHECKED_IN', 'Check guest in'));
    if (b.status === 'CHECKED_IN') actions.push(transition('COMPLETED', 'Complete stay'));
    if (scope === 'admin' && b.cancellable) {
      actions.unshift(h('button', { class: 'btn danger', type: 'button', onclick: async () => {
        if (await confirmDialog({ title: 'Cancel booking', message: `Cancel ${b.reference}? Rooms are released and a refund is issued when the free-cancellation window allows it.`, confirmLabel: 'Cancel booking', danger: true })) {
          act('Booking cancelled', () => api.post(`/admin/bookings/${id}/cancel`));
        }
      } }, 'Cancel booking'));
    }
    const m = modal({
      title: `Booking ${b.reference}`, width: 720, actions,
      body: h('div', { class: 'stack' },
        h('div', { class: 'row' }, badge(b.status), b.is_demo ? h('span', { class: 'badge neutral' }, 'demo data') : null),
        h('dl', { class: 'kv' },
          h('dt', {}, 'Guest'), h('dd', {}, `${b.guest_name} (${b.guest_email}${b.guest_phone ? `, ${b.guest_phone}` : ''})`),
          h('dt', {}, 'Hotel'), h('dd', {}, `${b.accommodation_name}, ${b.destination_name}`),
          h('dt', {}, 'Room'), h('dd', {}, `${b.room_name} x ${b.rooms}`),
          h('dt', {}, 'Stay'), h('dd', {}, `${date(b.check_in)} to ${date(b.check_out)} (${b.nights} nights)`),
          h('dt', {}, 'Party'), h('dd', {}, `${b.adults} adults, ${b.children} children`),
          h('dt', {}, 'Total'), h('dd', {}, `${money(b.total_usd)} (room ${money(b.subtotal_usd)}, taxes ${money(b.taxes_usd)}, fees ${money(b.fees_usd)})`),
          h('dt', {}, 'Policy'), h('dd', {}, b.cancellation_policy),
          b.special_requests ? [h('dt', {}, 'Requests'), h('dd', {}, b.special_requests)] : null),
        h('div', {}, h('h3', {}, 'Payments'),
          table({ empty: 'No payment yet', columns: [
            { label: 'Reference', render: (p) => h('span', { class: 'mono' }, p.provider_ref) }, { label: 'Amount', num: true, render: (p) => money(p.amount_usd) },
            { label: 'Status', render: (p) => badge(p.status) }, { label: 'Mode', render: (p) => (p.simulated ? 'simulated' : p.provider) }], rows: b.payments })),
        h('div', {}, h('h3', {}, 'History'),
          h('ol', { class: 'timeline' }, b.events.map((e) => h('li', {}, h('span', { class: 'dot' }),
            h('div', {}, h('strong', {}, `${e.from_status ? `${e.from_status.replaceAll('_', ' ')} to ` : ''}${e.to_status.replaceAll('_', ' ')}`),
              h('div', { class: 'muted small' }, `${dateTime(e.created_at)}${e.note ? ` · ${e.note}` : ''}`))))))),
    });
  }

  const search = debounce((v) => { state.q = v; state.page = 1; load().catch(fail); });
  const toolbar = h('div', { class: 'toolbar' },
    select(statuses.map((s) => [s, s ? s.replaceAll('_', ' ').toLowerCase() : 'All statuses']), state.status, { 'aria-label': 'Status', onchange: (e) => { state.status = e.target.value; state.page = 1; load().catch(fail); } }),
    scope === 'admin' ? h('input', { class: 'input', type: 'search', placeholder: 'Search reference, guest or email', 'aria-label': 'Search bookings', oninput: (e) => search(e.target.value) }) : null,
    h('button', { class: 'btn', type: 'button', onclick: () => load().catch(fail) }, 'Refresh'));
  load().catch(fail);
  return h('div', { class: 'stack' }, toolbar, box);
}
