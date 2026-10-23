// QR payments: the partner uploads their payment QR code, guests scan it, and the partner confirms the money arrived.
import { badge, confirmDialog, dateTime, date, field, h, imagePicker, input, modal, money, pager, select, showErrors, table, textarea, toast } from '/dashboard/js/ui.js';

export async function paymentsPage({ api }) {
  const profile = await api.get('/partner/profile');
  const root = h('div', { class: 'stack' });
  const up = (f) => api.upload(f);

  /* ---------- settings ---------- */
  const qr = imagePicker({ current: profile.qrImageUrl, label: 'Upload QR code', upload: up });
  const business = input({ value: profile.name || '', maxlength: 100 }), phone = input({ value: profile.contactPhone || '', maxlength: 30 });
  const account = input({ value: profile.accountName || '', maxlength: 100, placeholder: 'Name shown when the QR is scanned' });
  const bank = input({ value: profile.bank || '', maxlength: 100, placeholder: 'e.g. ABA, ACLEDA, Wing' });
  const note = textarea({ maxlength: 300, placeholder: 'Optional: anything guests should know when paying' }); note.value = profile.note || '';
  const errors = h('div', { 'aria-live': 'polite' });
  const save = h('button', { class: 'btn primary', type: 'button', onclick: async () => {
    save.disabled = true;
    try {
      const url = qr.get();
      const mediaId = url ? url.split('/').pop() : null;
      await api.put('/partner/profile', { name: business.value.trim(), contactPhone: phone.value.trim(), qrMediaId: mediaId, accountName: account.value.trim(), bank: bank.value.trim(), note: note.value.trim() });
      showErrors(errors, null); toast('Payment settings saved', 'ok');
    } catch (e) { showErrors(errors, e); } finally { save.disabled = false; }
  } }, 'Save settings');
  const settings = h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Your payment QR code')),
    h('div', { class: 'card-pad stack' },
      h('div', { class: 'notice info' }, 'Guests who book your property can pay by scanning this QR code in their banking app. After they pay, they tap "I have paid" and you confirm below once the money is in your account.'),
      h('div', { class: 'form-grid' }, h('div', { class: 'full' }, h('label', { class: 'small muted' }, 'QR code image (KHQR, ABA, ACLEDA, Wing ...)'), qr.el),
        field('Account name', account, { hint: 'Required with a QR code, so guests can check who they are paying' }), field('Bank / wallet', bank),
        field('Business name', business), field('Contact phone', phone), field('Instructions for guests', note, { full: true })), errors, h('div', {}, save)));

  /* ---------- payments to confirm ---------- */
  const state = { page: 1, status: 'PENDING' };
  const box = h('div', { class: 'card' });
  async function load() {
    const r = await api.get('/partner/payments', { method: 'qr', status: state.status, page: state.page, pageSize: 10 });
    const decide = async (p, ok) => {
      if (ok) {
        if (!(await confirmDialog({ title: 'Confirm payment', message: `Confirm that ${money(p.amount_usd)} for booking ${p.reference} arrived in your account? The guest's booking becomes confirmed.`, confirmLabel: 'Money received' }))) return;
        try { await api.post(`/partner/payments/${p.id}/confirm`); toast('Payment confirmed. Booking confirmed.', 'ok'); await load(); } catch (e) { toast(e.message, 'bad'); }
      } else {
        const reason = input({ placeholder: 'Reason (optional), e.g. amount does not match', maxlength: 200 });
        const m = modal({ title: 'Reject payment', width: 480, body: h('div', { class: 'stack' }, h('p', { class: 'muted' }, `The guest is told the payment for ${p.reference} was not found and can try again.`), field('Reason', reason)),
          actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), h('button', { class: 'btn danger', type: 'button', onclick: async () => {
            try { await api.post(`/partner/payments/${p.id}/reject`, { reason: reason.value.trim() }); toast('Payment rejected', 'ok'); m.close(); await load(); } catch (e) { toast(e.message, 'bad'); }
          } }, 'Reject')] });
      }
    };
    box.replaceChildren(table({ empty: state.status === 'PENDING' ? 'No QR payments are waiting for you' : 'Nothing here', columns: [
      { label: 'Booking', render: (p) => h('div', {}, h('span', { class: 'mono' }, p.reference), h('div', { class: 'muted small' }, p.guest_name)) },
      { label: 'Stay', render: (p) => `${p.accommodation_name}, ${date(p.check_in)}` }, { label: 'Amount', num: true, render: (p) => money(p.amount_usd) },
      { label: 'Guest says', render: (p) => (p.claimed_at ? h('span', { class: 'badge ok' }, `paid ${dateTime(p.claimed_at)}`) : h('span', { class: 'badge neutral' }, 'not yet')) },
      { label: 'Status', render: (p) => badge(p.status) },
      { label: '', render: (p) => (p.status === 'PENDING' ? h('div', { class: 'row' }, h('button', { class: 'btn small primary', type: 'button', onclick: () => decide(p, true) }, 'Money received'),
        h('button', { class: 'btn small danger', type: 'button', onclick: () => decide(p, false) }, 'Reject')) : (p.failure_reason || '')) }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (pg) => { state.page = pg; load(); } }));
  }
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  root.append(settings, h('section', { class: 'stack' }, h('div', { class: 'row between' }, h('h2', {}, 'Guest QR payments'),
    select([['PENDING', 'Waiting for you'], ['SUCCESS', 'Confirmed'], ['FAILED', 'Rejected'], ['', 'All']], state.status, { 'aria-label': 'Status', onchange: (e) => { state.status = e.target.value; state.page = 1; load(); } })), box));
  return root;
}
