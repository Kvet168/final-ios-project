// OTA-style (Agoda / Booking.com) Reservations & Front-Desk Management shared by Admin Console and Partner Extranet.
import { badge, confirmDialog, date, dateTime, debounce, h, icon, modal, money, num, pager, select, successDialog, table, toast } from './ui.js';

const PIPELINE_STEPS = [
  { key: 'PENDING_CONFIRMATION', label: 'Awaiting Payment' },
  { key: 'CONFIRMED', label: 'Booking Confirmed' },
  { key: 'CHECKED_IN', label: 'Checked-In (In-House)' },
  { key: 'COMPLETED', label: 'Checked-Out (Completed)' },
];

/**
 * @param {object} o
 * @param {'admin'|'partner'} o.scope
 */
export function bookingsPage({ api, scope }) {
  const state = { page: 1, status: '', q: '' };
  const summaryBar = h('div', { class: 'cat-tabs-grid' });
  const box = h('div', { class: 'card' });
  const list = scope === 'admin' ? '/admin/bookings' : '/partner/bookings';
  const statuses = ['', 'PENDING_CONFIRMATION', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED', 'EXPIRED', 'REFUNDED'];

  function renderSummaryCards(items, total) {
    const counts = {
      ALL: total || items.length,
      PENDING_CONFIRMATION: 0,
      CONFIRMED: 0,
      CHECKED_IN: 0,
      COMPLETED: 0,
      CANCELLED: 0,
    };
    let grossUsd = 0;
    let netPartnerUsd = 0;
    let platformFeeUsd = 0;

    for (const b of items) {
      counts[b.status] = (counts[b.status] || 0) + 1;
      if (['CONFIRMED', 'CHECKED_IN', 'COMPLETED'].includes(b.status)) {
        const tot = Number(b.total_usd || 0);
        const fee = Number(b.fees_usd || tot * 0.05);
        grossUsd += tot;
        platformFeeUsd += fee;
        netPartnerUsd += Math.max(0, tot - fee);
      }
    }

    const tabs = [
      { id: '', label: scope === 'partner' ? 'All Reservations' : 'All OTA Bookings', count: num(counts.ALL), sub: `Gross ${money(grossUsd)}`, color: '#E6485C', icon: 'ticket' },
      { id: 'PENDING_CONFIRMATION', label: 'Awaiting Payment', count: num(counts.PENDING_CONFIRMATION), sub: 'Room hold active', color: '#F59E0B', icon: 'clock' },
      { id: 'CONFIRMED', label: 'Ready for Check-In', count: num(counts.CONFIRMED), sub: 'Paid & guaranteed', color: '#6347F9', icon: 'bed' },
      { id: 'CHECKED_IN', label: 'In-House Guests', count: num(counts.CHECKED_IN), sub: 'Currently staying', color: '#3B82F6', icon: 'users' },
      { id: 'COMPLETED', label: 'Completed Stays', count: num(counts.COMPLETED), sub: scope === 'partner' ? `Net ${money(netPartnerUsd)}` : `Fee ${money(platformFeeUsd)}`, color: '#10B981', icon: 'chart' },
    ];

    summaryBar.replaceChildren(...tabs.map((tb) => {
      const active = state.status === tb.id;
      return h('button', {
        class: `card cat-tab-btn ${active ? 'active' : ''}`.trim(),
        type: 'button',
        style: `--cat-color:${tb.color}`,
        onclick: () => {
          state.status = tb.id;
          state.page = 1;
          load().catch(fail);
        },
      },
      h('span', { class: 'cat-tab-icon', style: `background:${tb.color}18;color:${tb.color}` }, icon(tb.icon)),
      h('div', { class: 'cat-tab-copy' },
        h('span', { class: 'cat-tab-label' }, tb.label),
        h('strong', { class: 'cat-tab-count' }, tb.count),
        h('span', { class: 'muted small', style: 'font-size:11px' }, tb.sub)));
    }));
  }

  async function load() {
    const r = await api.get(list, { page: state.page, pageSize: 15, status: state.status, q: scope === 'admin' ? state.q : undefined });
    const items = r.items || [];
    renderSummaryCards(items, r.total);

    const cols = [
      {
        label: 'Reference',
        sortValue: (b) => b.reference || '',
        render: (b) => h('div', {},
          h('span', { class: 'mono', style: 'font-weight:700' }, b.reference),
          b.created_at ? h('div', { class: 'muted small' }, date(b.created_at)) : null),
      },
      {
        label: 'Guest',
        sortValue: (b) => b.guest_name || '',
        render: (b) => h('div', {},
          h('strong', {}, b.guest_name || '-'),
          b.guest_email ? h('div', { class: 'muted small' }, b.guest_email) : null),
      },
      {
        label: 'Property & Room',
        sortValue: (b) => b.accommodation_name || '',
        render: (b) => h('div', {},
          h('strong', {}, b.accommodation_name || '-'),
          h('div', { class: 'muted small' }, `${b.room_name || 'Standard Room'}${b.rooms ? ` × ${b.rooms}` : ''}${scope === 'admin' && b.partner_name ? ` · ${b.partner_name}` : ''}`)),
      },
      {
        label: 'Check-In → Check-Out',
        sortValue: (b) => b.check_in || '',
        render: (b) => h('div', {},
          h('div', {}, `${date(b.check_in)} → ${date(b.check_out)}`),
          h('div', { class: 'muted small' }, `${b.nights || 1} night${Number(b.nights) === 1 ? '' : 's'} · ${b.adults || 1} adult${Number(b.adults) === 1 ? '' : 's'}`)),
      },
      {
        label: 'Gross Total',
        num: true,
        sortValue: (b) => Number(b.total_usd || 0),
        render: (b) => money(b.total_usd),
      },
      scope === 'partner'
        ? {
          label: 'Net Payout',
          num: true,
          sortValue: (b) => Number(b.total_usd || 0) - Number(b.fees_usd || Number(b.total_usd || 0) * 0.05),
          render: (b) => {
            const tot = Number(b.total_usd || 0);
            const fee = Number(b.fees_usd || tot * 0.05);
            return h('div', {},
              h('strong', { style: 'color:var(--ok)' }, money(Math.max(0, tot - fee))),
              h('div', { class: 'muted small' }, `- ${money(fee)} OTA fee`));
          },
        }
        : {
          label: 'OTA Commission',
          num: true,
          sortValue: (b) => Number(b.fees_usd || Number(b.total_usd || 0) * 0.05),
          render: (b) => {
            const tot = Number(b.total_usd || 0);
            const fee = Number(b.fees_usd || tot * 0.05);
            return h('div', {},
              h('strong', { style: 'color:var(--brand-deep)' }, money(fee)),
              h('div', { class: 'muted small' }, `Payout ${money(Math.max(0, tot - fee))}`));
          },
        },
      {
        label: 'Status',
        sortValue: (b) => b.status || '',
        render: (b) => badge(b.status),
      },
      {
        label: 'Front Desk Action',
        sortable: false,
        render: (b) => {
          if (b.status === 'CONFIRMED') {
            return h('button', {
              class: 'btn small primary',
              type: 'button',
              onclick: (ev) => {
                ev.stopPropagation();
                quickTransition(b, 'CHECKED_IN', 'Check guest in');
              },
            }, 'Check guest in');
          }
          if (b.status === 'CHECKED_IN') {
            return h('button', {
              class: 'btn small primary',
              type: 'button',
              onclick: (ev) => {
                ev.stopPropagation();
                quickTransition(b, 'COMPLETED', 'Complete stay');
              },
            }, 'Complete stay');
          }
          return h('button', {
            class: 'btn small',
            type: 'button',
            onclick: (ev) => {
              ev.stopPropagation();
              openDetail(b.id);
            },
          }, 'View voucher');
        },
      },
    ];

    box.replaceChildren(
      h('div', { class: 'card-head' },
        h('div', {},
          h('h2', {}, scope === 'partner' ? 'Property Reservations & Front Desk (Extranet)' : 'Global OTA Reservations & Customer Support'),
          h('p', { class: 'muted small' }, scope === 'partner'
            ? 'Like Agoda YCS / Booking.com Extranet: manage guest arrivals, check-ins, check-outs, and view your net payout per stay.'
            : 'Like Agoda / Booking.com Central Operations: monitor platform-wide reservations, platform commission fees, and assist travelers or partners with cancellations & refunds.')),
        h('span', { class: 'badge neutral' }, `${num(r.total)} bookings`)),
      table({
        empty: 'No bookings match these filters',
        onRowClick: (b) => openDetail(b.id),
        columns: cols,
        rows: items,
      }),
      pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load().catch(fail); } }));
  }

  const fail = (e) => box.replaceChildren(h('div', { class: 'empty', role: 'alert' }, e.message));

  async function quickTransition(b, to, label) {
    const ok = await confirmDialog({
      title: label,
      message: `${label} for ${b.guest_name} (${b.reference}) at ${b.accommodation_name}?`,
      confirmLabel: label,
    });
    if (!ok) return;
    try {
      await api.post(`/${scope}/bookings/${b.id}/transition`, { to });
      await load();
      await successDialog({
        title: to === 'CHECKED_IN' ? 'Guest Checked In' : 'Stay Completed (Checked Out)',
        message: `Reservation ${b.reference} has been updated in real time and the traveler was notified.`,
        details: [
          ['Booking Ref', b.reference],
          ['Guest', b.guest_name],
          ['Property', b.accommodation_name],
          ['New Stage', to.replaceAll('_', ' ')],
        ],
      });
    } catch (e) {
      toast(e.message, 'bad');
    }
  }

  function renderStepper(status) {
    const activeIdx = PIPELINE_STEPS.findIndex((s) => s.key === status);
    if (activeIdx === -1) {
      return h('div', { class: 'notice warn' }, `Reservation status: ${status.replaceAll('_', ' ')}`);
    }
    return h('div', {
      style: 'display:grid;grid-template-columns:repeat(4,1fr);gap:8px;padding:12px;background:var(--surface-2);border-radius:var(--radius-sm);border:1px solid var(--line)',
    }, PIPELINE_STEPS.map((st, idx) => {
      const done = idx <= activeIdx;
      const current = idx === activeIdx;
      return h('div', {
        style: `padding:8px 10px;border-radius:6px;border:1px solid ${current ? 'var(--brand)' : done ? 'var(--ok)' : 'var(--line)'};background:${current ? 'var(--tint)' : 'var(--surface)'}`,
      },
      h('div', { class: 'small muted', style: 'font-size:10.5px;font-weight:700;text-transform:uppercase' }, `Step ${idx + 1}`),
      h('div', { style: `font-weight:700;font-size:12.5px;color:${done ? 'var(--ink)' : 'var(--muted)'}` }, st.label));
    }));
  }

  async function openDetail(id) {
    const b = await api.get(`/bookings/${id}`).catch((e) => { toast(e.message, 'bad'); return null; });
    if (!b) return;
    const act = async (title, newStatus, fn) => {
      try {
        await fn();
        m.close();
        await load();
        await successDialog({
          title,
          message: `Booking ${b.reference} has been updated.`,
          details: [
            ['Reference', b.reference],
            ['Guest', b.guest_name],
            ['Property', b.accommodation_name],
            ['New status', newStatus.replaceAll('_', ' ')],
          ],
        });
      } catch (e) { toast(e.message, 'bad'); }
    };
    const transition = (to, label) => h('button', {
      class: 'btn primary',
      type: 'button',
      onclick: () => act(to === 'CHECKED_IN' ? 'Guest checked in' : to === 'COMPLETED' ? 'Stay completed' : 'Booking confirmed', to, () => api.post(`/${scope}/bookings/${id}/transition`, { to })),
    }, label);

    const actions = [];
    if (b.status === 'CONFIRMED') actions.push(transition('CHECKED_IN', 'Check guest in'));
    if (b.status === 'CHECKED_IN') actions.push(transition('COMPLETED', 'Complete stay'));
    if (b.cancellable) {
      actions.unshift(h('button', { class: 'btn danger', type: 'button', onclick: async () => {
        if (await confirmDialog({
          title: 'Cancel reservation',
          message: `Cancel ${b.reference}? Rooms are immediately released back to inventory and an automatic refund is issued if within the free-cancellation window.`,
          confirmLabel: 'Cancel booking',
          danger: true,
        })) {
          act('Booking cancelled', 'CANCELLED', () => api.post(`/${scope}/bookings/${id}/cancel`));
        }
      } }, 'Cancel booking'));
    }

    const subtotal = Number(b.subtotal_usd || 0);
    const taxes = Number(b.taxes_usd || 0);
    const fees = Number(b.fees_usd || 0);
    const total = Number(b.total_usd || 0);
    const netPartner = Math.max(0, total - fees);

    const m = modal({
      title: `OTA Booking Voucher · ${b.reference}`, width: 760, actions,
      body: h('div', { class: 'stack' },
        h('div', { class: 'row between' },
          h('div', { class: 'row' },
            badge(b.status),
            b.freeCancellation ? h('span', { class: 'badge ok' }, 'Free cancellation active') : null,
            b.is_demo ? h('span', { class: 'badge neutral' }, 'demo data') : null),
          h('span', { class: 'muted small' }, `Booked ${dateTime(b.created_at)}`)),
        renderStepper(b.status),
        h('dl', { class: 'kv' },
          h('dt', {}, 'Guest'), h('dd', {}, `${b.guest_name} (${b.guest_email}${b.guest_phone ? ` · ${b.guest_phone}` : ''})`),
          h('dt', {}, 'Property'), h('dd', {}, `${b.accommodation_name}, ${b.destination_name}${b.partner_name ? ` (Partner: ${b.partner_name})` : ''}`),
          h('dt', {}, 'Room & Occupancy'), h('dd', {}, `${b.room_name} × ${b.rooms} room(s) · ${b.adults} adults, ${b.children} children`),
          h('dt', {}, 'Check-In / Out'), h('dd', {}, `${date(b.check_in)} to ${date(b.check_out)} (${b.nights} nights)`),
          h('dt', {}, 'Gross Charge'), h('dd', {}, `${money(total)} (Room rate ${money(subtotal)} + Taxes ${money(taxes)} + OTA Service Fee ${money(fees)})`),
          h('dt', {}, 'OTA Settlement'), h('dd', {}, `Partner Net Payout: ${money(netPartner)} · WAYFARER Platform Fee: ${money(fees)}`),
          h('dt', {}, 'Cancellation Policy'), h('dd', {}, b.cancellation_policy || 'Standard policy'),
          b.special_requests ? [h('dt', {}, 'Guest Requests'), h('dd', {}, b.special_requests)] : null),
        h('div', {}, h('h3', {}, 'Payment Transactions'),
          table({ empty: 'No payment recorded yet', columns: [
            { label: 'Reference', render: (p) => h('span', { class: 'mono' }, p.provider_ref) },
            { label: 'Amount', num: true, render: (p) => money(p.amount_usd) },
            { label: 'Refunded', num: true, render: (p) => (Number(p.refunded_usd) ? money(p.refunded_usd) : '-') },
            { label: 'Status', render: (p) => badge(p.status) },
            { label: 'Channel', render: (p) => (p.simulated ? 'Card (Simulated)' : p.provider === 'khqr' ? 'KHQR Direct' : p.provider) },
          ], rows: b.payments || [] })),
        h('div', {}, h('h3', {}, 'Reservation Audit Timeline'),
          h('ol', { class: 'timeline' }, (b.events || []).map((e) => h('li', {}, h('span', { class: 'dot' }),
            h('div', {}, h('strong', {}, `${e.from_status ? `${e.from_status.replaceAll('_', ' ')} → ` : ''}${e.to_status.replaceAll('_', ' ')}`),
              h('div', { class: 'muted small' }, `${dateTime(e.created_at)}${e.note ? ` · ${e.note}` : ''}`))))))),
    });
  }

  const search = debounce((v) => { state.q = v; state.page = 1; load().catch(fail); });
  const toolbar = h('div', { class: 'toolbar row between' },
    h('div', { class: 'row' },
      select(statuses.map((s) => [s, s ? s.replaceAll('_', ' ').toLowerCase() : 'All statuses']), state.status, {
        'aria-label': 'Status',
        onchange: (e) => { state.status = e.target.value; state.page = 1; load().catch(fail); },
      }),
      scope === 'admin'
        ? h('input', {
          class: 'input',
          type: 'search',
          placeholder: 'Search booking ref, guest name or email...',
          'aria-label': 'Search bookings',
          style: 'min-width:260px',
          oninput: (e) => search(e.target.value),
        })
        : null,
      h('button', { class: 'btn', type: 'button', onclick: () => load().catch(fail) }, icon('refresh'), 'Refresh')),
    h('span', { class: 'badge neutral' }, scope === 'partner' ? 'Partner Extranet · Live Inventory Sync' : 'OTA Central Desk'));
  load().catch(fail);
  return h('div', { class: 'stack' }, toolbar, summaryBar, box);
}
