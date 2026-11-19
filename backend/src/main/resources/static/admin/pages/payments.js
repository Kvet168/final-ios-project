// OTA Settlement, Commission & Payment Ledger (Agoda / Booking.com model)
import { badge, dateTime, h, icon, money, num, pager, select, table } from '/dashboard/js/ui.js';

export function paymentsPage({ api }) {
  const state = { page: 1, status: '' };
  const kpiBar = h('div', { class: 'cat-tabs-grid' });
  const box = h('div', { class: 'card' });

  function renderKpis(items, total) {
    let grossCollected = 0;
    let platformCommission = 0;
    let partnerPayout = 0;
    let refundedTotal = 0;

    for (const p of items) {
      const amt = Number(p.amount_usd || 0);
      const fee = Number(p.fees_usd || amt * 0.05);
      if (p.status === 'SUCCESS') {
        grossCollected += amt;
        platformCommission += fee;
        partnerPayout += Math.max(0, amt - fee);
      } else if (p.status === 'REFUNDED') {
        refundedTotal += Number(p.refunded_usd || amt);
      }
    }

    const cards = [
      { id: '', label: 'All Transactions', val: num(total || items.length), sub: 'Card & KHQR payments', color: '#E6485C', icon: 'card' },
      { id: 'SUCCESS', label: 'Gross Booking Value (GBV)', val: money(grossCollected), sub: 'Confirmed guest payments', color: '#10B981', icon: 'chart' },
      { id: 'SUCCESS', label: 'Travel OTA Commission', val: money(platformCommission), sub: 'Platform service fees (5%)', color: '#6347F9', icon: 'compass' },
      { id: 'SUCCESS', label: 'Net Partner Payouts', val: money(partnerPayout), sub: 'Settled to hotel partners', color: '#3B82F6', icon: 'bed' },
      { id: 'REFUNDED', label: 'Customer Refunds', val: money(refundedTotal), sub: 'Free-cancellation refunds', color: '#F59E0B', icon: 'refresh' },
    ];

    kpiBar.replaceChildren(...cards.map((c) => h('button', {
      class: `card cat-tab-btn ${state.status === c.id && c.label === 'All Transactions' ? 'active' : ''}`.trim(),
      type: 'button',
      style: `--cat-color:${c.color}`,
      onclick: () => {
        state.status = c.id;
        state.page = 1;
        load();
      },
    },
    h('span', { class: 'cat-tab-icon', style: `background:${c.color}18;color:${c.color}` }, icon(c.icon)),
    h('div', { class: 'cat-tab-copy' },
      h('span', { class: 'cat-tab-label' }, c.label),
      h('strong', { class: 'cat-tab-count' }, c.val),
      h('span', { class: 'muted small', style: 'font-size:11px' }, c.sub)))));
  }

  async function load() {
    const r = await api.get('/admin/payments', { page: state.page, pageSize: 15, status: state.status });
    const items = r.items || [];
    renderKpis(items, r.total);

    box.replaceChildren(
      h('div', { class: 'card-head' },
        h('div', {},
          h('h2', {}, 'OTA Payment Ledger, Commission & Partner Payouts'),
          h('p', { class: 'muted small' }, 'Agoda / Booking.com financial flow: tracks gross traveler payments, Travel platform commission fees, net hotel partner payouts, and customer refunds.')),
        h('span', { class: 'badge neutral' }, `${num(r.total)} transactions`)),
      table({
        empty: 'No payments match this filter',
        columns: [
          {
            label: 'Booking & Guest',
            sortValue: (p) => p.reference || '',
            render: (p) => h('div', {},
              h('span', { class: 'mono', style: 'font-weight:700' }, p.reference),
              p.guest_name ? h('div', { class: 'muted small' }, p.guest_name) : null),
          },
          {
            label: 'Property & Partner',
            sortValue: (p) => p.accommodation_name || '',
            render: (p) => h('div', {},
              h('strong', {}, p.accommodation_name || '-'),
              p.partner_name ? h('div', { class: 'muted small' }, p.partner_name) : null),
          },
          {
            label: 'Transaction Ref',
            sortValue: (p) => p.provider_ref || '',
            render: (p) => h('span', { class: 'mono' }, p.provider_ref),
          },
          {
            label: 'Gross Paid',
            num: true,
            sortValue: (p) => Number(p.amount_usd || 0),
            render: (p) => money(p.amount_usd),
          },
          {
            label: 'OTA Fee',
            num: true,
            sortValue: (p) => Number(p.fees_usd || Number(p.amount_usd || 0) * 0.05),
            render: (p) => {
              const amt = Number(p.amount_usd || 0);
              const fee = Number(p.fees_usd || amt * 0.05);
              return h('span', { style: 'color:var(--brand-deep);font-weight:600' }, money(fee));
            },
          },
          {
            label: 'Partner Net',
            num: true,
            sortValue: (p) => {
              const amt = Number(p.amount_usd || 0);
              const fee = Number(p.fees_usd || amt * 0.05);
              return Math.max(0, amt - fee);
            },
            render: (p) => {
              const amt = Number(p.amount_usd || 0);
              const fee = Number(p.fees_usd || amt * 0.05);
              return h('strong', { style: 'color:var(--ok)' }, money(Math.max(0, amt - fee)));
            },
          },
          {
            label: 'Refunded',
            num: true,
            sortValue: (p) => Number(p.refunded_usd || 0),
            render: (p) => (Number(p.refunded_usd) ? money(p.refunded_usd) : '-'),
          },
          {
            label: 'Channel',
            sortValue: (p) => p.provider || '',
            render: (p) => (p.provider === 'khqr'
              ? h('span', { class: 'badge ok' }, 'KHQR Direct')
              : p.simulated
                ? h('span', { class: 'badge neutral' }, 'Card (OTA)')
                : p.provider),
          },
          {
            label: 'Status',
            sortValue: (p) => p.status || '',
            render: (p) => badge(p.status),
          },
          {
            label: 'When',
            sortValue: (p) => p.created_at || '',
            render: (p) => dateTime(p.created_at),
          },
        ],
        rows: items,
      }),
      pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } }));
  }

  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' },
    h('div', { class: 'toolbar row between' },
      h('div', { class: 'row' },
        select([['', 'All statuses'], 'PENDING', 'SUCCESS', 'FAILED', 'CANCELLED', 'REFUNDED'], state.status, {
          'aria-label': 'Status',
          onchange: (e) => { state.status = e.target.value; state.page = 1; load(); },
        }),
        h('button', { class: 'btn', type: 'button', onclick: () => load() }, icon('refresh'), 'Refresh')),
      h('span', { class: 'badge neutral' }, 'OTA Financial Settlement & Audit')),
    kpiBar,
    box);
}
