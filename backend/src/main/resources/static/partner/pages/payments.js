// Partner Extranet Payouts, Settlements & KHQR Payment Confirmation (Agoda YCS / Booking.com Extranet style)
import { badge, confirmDialog, dateTime, date, field, h, icon, imagePicker, input, modal, money, num, pager, select, showErrors, successDialog, table, textarea, toast, validate } from '/dashboard/js/ui.js';

export async function paymentsPage({ api }) {
  const profile = await api.get('/partner/profile');
  const root = h('div', { class: 'stack' });
  const up = (f) => api.upload(f);

  /* ---------- KPI summary bar ---------- */
  const kpiBar = h('div', { class: 'cat-tabs-grid' });

  /* ---------- settings ---------- */
  const qr = imagePicker({ current: profile.qrImageUrl, label: 'Upload QR code', upload: up });
  const business = input({ value: profile.name || '', maxlength: 100, required: true }), phone = input({ value: profile.contactPhone || '', maxlength: 30 });
  const account = input({ value: profile.accountName || '', maxlength: 100, placeholder: 'Name shown when the QR is scanned' });
  const bank = input({ value: profile.bank || '', maxlength: 100, placeholder: 'e.g. ABA, ACLEDA, Wing' });
  const note = textarea({ maxlength: 300, placeholder: 'Optional: anything guests should know when paying' }); note.value = profile.note || '';
  const errors = h('div', { 'aria-live': 'polite' });
  const save = h('button', { class: 'btn primary', type: 'button', onclick: async () => {
    const url = qr.get();
    if (!validate([
      { input: business, label: 'Business name', required: true, minLen: 2, maxLen: 100 },
      {
        input: account,
        label: 'Account name',
        maxLen: 100,
        custom: (v) => (url && !v ? 'Account name is required when a QR code image is set so guests can verify the recipient.' : null),
      },
      { input: bank, label: 'Bank / wallet', maxLen: 100 },
      { input: phone, label: 'Contact phone', maxLen: 30 },
      { input: note, label: 'Instructions for guests', maxLen: 300 },
    ], errors)) return;

    save.disabled = true;
    try {
      const mediaId = url ? url.split('/').pop() : null;
      await api.put('/partner/profile', { name: business.value.trim(), contactPhone: phone.value.trim(), qrMediaId: mediaId, accountName: account.value.trim(), bank: bank.value.trim(), note: note.value.trim() });
      showErrors(errors, null);
      await successDialog({
        title: 'Payout & QR settings saved',
        message: url
          ? 'Guests booking your properties can now pay via your KHQR / bank account or OTA card checkout.'
          : 'Your partner payout profile details have been updated.',
        details: [
          ['Business', business.value.trim()],
          ['KHQR Direct Payment', url ? 'Active' : 'Not configured'],
          account.value.trim() ? ['Account holder', account.value.trim()] : null,
          bank.value.trim() ? ['Bank / wallet', bank.value.trim()] : null,
        ],
      });
    } catch (e) { showErrors(errors, e); } finally { save.disabled = false; }
  } }, 'Save settings');

  const settings = h('section', { class: 'card' },
    h('div', { class: 'card-head' },
      h('div', {},
        h('h2', {}, 'Partner Bank & KHQR Payout Setup'),
        h('p', { class: 'muted small' }, 'Configure your bank account & KHQR code for direct guest QR transfers and OTA payout settlements.')),
      profile.acceptsQr ? h('span', { class: 'badge ok' }, 'KHQR Active') : h('span', { class: 'badge warn' }, 'KHQR Not Set')),
    h('div', { class: 'card-pad stack' },
      h('div', { class: 'notice info' }, 'Like Agoda / Booking.com: travelers can pay either via OTA Card Checkout or directly to your bank account using your KHQR code below. When a guest pays by KHQR, confirm receipt in the table below to issue their voucher immediately.'),
      h('div', { class: 'form-grid' },
        h('div', { class: 'full' }, h('label', { class: 'small muted' }, 'QR code image (KHQR, ABA, ACLEDA, Wing ...)'), qr.el),
        field('Account name', account, { hint: 'Required with a QR code, so guests can check who they are paying' }),
        field('Bank / wallet', bank),
        field('Business name', business, { required: true }),
        field('Contact phone', phone),
        field('Instructions for guests', note, { full: true })),
      errors,
      h('div', {}, save)));

  /* ---------- payments & settlements table ---------- */
  const state = { page: 1, status: '', method: '' };
  const box = h('div', { class: 'card' });

  function renderKpis(items, total) {
    let waitingQr = 0;
    let grossConfirmed = 0;
    let otaFeeTotal = 0;
    let netEarnings = 0;

    for (const p of items) {
      const amt = Number(p.amount_usd || 0);
      const fee = Number(p.fees_usd || amt * 0.05);
      if (p.status === 'PENDING' && p.method === 'qr') waitingQr++;
      if (p.status === 'SUCCESS') {
        grossConfirmed += amt;
        otaFeeTotal += fee;
        netEarnings += Math.max(0, amt - fee);
      }
    }

    const cards = [
      { id: '', label: 'All Property Payments', val: num(total || items.length), sub: 'Card (OTA) & KHQR Direct', color: '#E6485C', icon: 'card' },
      { id: 'PENDING', label: 'Awaiting Confirmation', val: num(waitingQr), sub: 'Guest tapped "I have paid"', color: '#F59E0B', icon: 'clock' },
      { id: 'SUCCESS', label: 'Gross Room Revenue', val: money(grossConfirmed), sub: 'Confirmed payments', color: '#3B82F6', icon: 'chart' },
      { id: 'SUCCESS', label: 'Net Partner Earnings', val: money(netEarnings), sub: `After ${money(otaFeeTotal)} OTA fee`, color: '#10B981', icon: 'bed' },
    ];

    kpiBar.replaceChildren(...cards.map((c) => h('button', {
      class: `card cat-tab-btn ${state.status === c.id && c.label !== 'Net Partner Earnings' ? 'active' : ''}`.trim(),
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
    const r = await api.get('/partner/payments', {
      method: state.method || undefined,
      status: state.status || undefined,
      page: state.page,
      pageSize: 12,
    });
    const items = r.items || [];
    renderKpis(items, r.total);

    const decide = async (p, ok) => {
      if (ok) {
        if (!(await confirmDialog({
          title: 'Confirm payment received',
          message: `Confirm that ${money(p.amount_usd)} for booking ${p.reference} arrived in your bank account? The guest's booking voucher becomes confirmed immediately.`,
          confirmLabel: 'Money received',
        }))) return;
        try {
          await api.post(`/partner/payments/${p.id}/confirm`);
          await load();
          await successDialog({
            title: 'KHQR payment confirmed',
            message: `Booking ${p.reference} is now confirmed and the guest has received their voucher.`,
            details: [
              ['Booking ref', p.reference],
              ['Guest', p.guest_name],
              ['Property', p.accommodation_name],
              ['Amount received', money(p.amount_usd)],
            ],
          });
        } catch (e) { toast(e.message, 'bad'); }
      } else {
        const reason = input({ placeholder: 'Reason (optional), e.g. transfer not found in bank statement', maxlength: 200 });
        const m = modal({
          title: 'Reject QR payment',
          width: 480,
          body: h('div', { class: 'stack' },
            h('p', { class: 'muted' }, `The guest is notified that the payment for ${p.reference} was not found and can retry before the hold expires.`),
            field('Reason', reason)),
          actions: [
            h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
            h('button', {
              class: 'btn danger',
              type: 'button',
              onclick: async () => {
                try {
                  await api.post(`/partner/payments/${p.id}/reject`, { reason: reason.value.trim() });
                  toast('Payment rejected', 'ok');
                  m.close();
                  await load();
                } catch (e) { toast(e.message, 'bad'); }
              },
            }, 'Reject'),
          ],
        });
      }
    };

    box.replaceChildren(
      h('div', { class: 'card-head' },
        h('div', {},
          h('h2', {}, 'Guest Payments & OTA Settlement Statement'),
          h('p', { class: 'muted small' }, 'Confirm incoming KHQR bank transfers and track your net payout after platform commission.')),
        h('div', { class: 'row' },
          select([['', 'All channels'], ['qr', 'KHQR Direct'], ['card', 'OTA Card']], state.method, {
            'aria-label': 'Channel',
            onchange: (e) => { state.method = e.target.value; state.page = 1; load(); },
          }),
          select([['', 'All statuses'], ['PENDING', 'Waiting for you'], ['SUCCESS', 'Confirmed'], ['FAILED', 'Rejected']], state.status, {
            'aria-label': 'Status',
            onchange: (e) => { state.status = e.target.value; state.page = 1; load(); },
          }))),
      table({
        empty: state.status === 'PENDING' ? 'No QR payments are waiting for your confirmation' : 'No payment records found',
        columns: [
          {
            label: 'Booking & Guest',
            sortValue: (p) => p.reference || '',
            render: (p) => h('div', {},
              h('span', { class: 'mono', style: 'font-weight:700' }, p.reference),
              h('div', { class: 'muted small' }, p.guest_name)),
          },
          {
            label: 'Property & Stay',
            sortValue: (p) => p.check_in || '',
            render: (p) => h('div', {},
              h('strong', {}, p.accommodation_name),
              h('div', { class: 'muted small' }, `${date(p.check_in)} → ${date(p.check_out)}`)),
          },
          {
            label: 'Channel',
            sortValue: (p) => p.method || '',
            render: (p) => (p.method === 'qr'
              ? h('span', { class: 'badge ok' }, 'KHQR Direct')
              : h('span', { class: 'badge neutral' }, 'OTA Card')),
          },
          {
            label: 'Gross Paid',
            num: true,
            sortValue: (p) => Number(p.amount_usd || 0),
            render: (p) => money(p.amount_usd),
          },
          {
            label: 'Net Payout',
            num: true,
            sortValue: (p) => {
              const amt = Number(p.amount_usd || 0);
              const fee = Number(p.fees_usd || amt * 0.05);
              return Math.max(0, amt - fee);
            },
            render: (p) => {
              const amt = Number(p.amount_usd || 0);
              const fee = Number(p.fees_usd || amt * 0.05);
              return h('div', {},
                h('strong', { style: 'color:var(--ok)' }, money(Math.max(0, amt - fee))),
                h('div', { class: 'muted small' }, `Fee ${money(fee)}`));
            },
          },
          {
            label: 'Guest Claim',
            sortValue: (p) => p.claimed_at || '',
            render: (p) => (p.method === 'qr'
              ? (p.claimed_at ? h('span', { class: 'badge ok' }, `Paid ${dateTime(p.claimed_at)}`) : h('span', { class: 'badge neutral' }, 'Unclaimed'))
              : h('span', { class: 'muted small' }, 'Auto-verified')),
          },
          {
            label: 'Status',
            sortValue: (p) => p.status || '',
            render: (p) => badge(p.status),
          },
          {
            label: 'Action',
            sortable: false,
            render: (p) => (p.status === 'PENDING' && p.method === 'qr'
              ? h('div', { class: 'row' },
                h('button', { class: 'btn small primary', type: 'button', onclick: () => decide(p, true) }, 'Money received'),
                h('button', { class: 'btn small danger', type: 'button', onclick: () => decide(p, false) }, 'Reject'))
              : (p.failure_reason || h('span', { class: 'muted small' }, 'Settled'))),
          },
        ],
        rows: items,
      }),
      pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (pg) => { state.page = pg; load(); } }));
  }

  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  root.append(kpiBar, box, settings);
  return root;
}
