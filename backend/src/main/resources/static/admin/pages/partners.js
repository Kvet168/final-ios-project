// Partner accounts: the administrator creates the owner login, hands over a one-time temporary password, and can see (not edit) each partner's properties.
import { badge, confirmDialog, copyButton, date, debounce, field, h, icon, input, modal, num, pager, showErrors, stars, table, toast } from '/dashboard/js/ui.js';

export function partnersPage({ api, user }) {
  const state = { page: 1, q: '' };
  const box = h('div', { class: 'card' });
  const isAdmin = user.role === 'admin';

  async function load() {
    const r = await api.get('/admin/partners', { page: state.page, pageSize: 15, q: state.q });
    box.replaceChildren(table({
      empty: 'No partners yet. Create the first partner account.', onRowClick: (p) => detail(p.id),
      columns: [
        { label: 'Business', render: (p) => h('div', {}, h('strong', {}, p.name), h('div', { class: 'muted small' }, p.contact_phone || '')) },
        { label: 'Owner login', render: (p) => h('div', {}, p.owner_name, h('div', { class: 'muted small' }, p.owner_email)) },
        { label: 'Properties', num: true, render: (p) => num(p.hotels) }, { label: 'Rooms', num: true, render: (p) => num(p.rooms) }, { label: 'Bookings', num: true, render: (p) => num(p.bookings) },
        { label: 'QR payment', render: (p) => (p.qr_configured ? h('span', { class: 'badge ok' }, 'set up') : h('span', { class: 'badge neutral' }, 'not yet')) },
        { label: 'Account', render: (p) => (p.must_change_password ? h('span', { class: 'badge warn' }, 'never signed in') : h('span', { class: 'badge ok' }, 'active')) },
        { label: 'Created', render: (p) => date(p.created_at) }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (pg) => { state.page = pg; load(); } }));
  }

  function credentials(title, email, password, notice) {
    modal({ title, width: 520, body: h('div', { class: 'stack' }, h('div', { class: 'notice' }, notice),
      h('div', { class: 'stack', style: 'gap:6px' }, h('div', { class: 'small muted' }, 'Sign-in page'), h('div', { class: 'row' }, h('span', { class: 'secret' }, `${location.origin}/partner`), copyButton(`${location.origin}/partner`))),
      h('div', { class: 'stack', style: 'gap:6px' }, h('div', { class: 'small muted' }, 'Email'), h('div', { class: 'row' }, h('span', { class: 'secret' }, email), copyButton(email))),
      h('div', { class: 'stack', style: 'gap:6px' }, h('div', { class: 'small muted' }, 'Temporary password'), h('div', { class: 'row' }, h('span', { class: 'secret' }, password), copyButton(password)))) });
  }

  function createForm() {
    const business = input({ required: true, maxlength: 100, placeholder: 'e.g. Sokha Bungalows' }), owner = input({ required: true, maxlength: 80, placeholder: 'Owner full name' });
    const email = input({ type: 'email', required: true, maxlength: 160, placeholder: 'owner@example.com' }), phone = input({ maxlength: 30, placeholder: 'Optional' });
    const errors = h('div', { 'aria-live': 'polite' });
    const m = modal({
      title: 'Create partner account', width: 560,
      body: h('div', { class: 'stack' }, h('p', { class: 'muted small' }, 'This creates the owner login and the business. A one-time temporary password is shown next; the partner must replace it at first sign-in, then adds their own properties, rooms, prices and QR payment.'),
        h('div', { class: 'form-grid' }, field('Business name', business, { full: true }), field('Owner name', owner), field('Phone', phone), field('Owner email (the login)', email, { full: true })), errors),
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        m.setBusy(true);
        try {
          const r = await api.post('/admin/partners', { businessName: business.value.trim(), ownerName: owner.value.trim(), email: email.value.trim(), phone: phone.value.trim() || null });
          m.close(); await load(); credentials('Partner account created', r.owner_email, r.temporaryPassword, 'Copy these now. The password is shown only once. Send it to the partner through a private channel.');
        } catch (e) { showErrors(errors, e); m.setBusy(false); }
      } }, 'Create account')],
    });
  }

  async function detail(id) {
    const p = await api.get(`/admin/partners/${id}`).catch((e) => { toast(e.message, 'bad'); return null; });
    if (!p) return;
    modal({
      title: p.name, width: 780,
      actions: isAdmin ? [h('button', { class: 'btn', type: 'button', onclick: async () => {
        if (!(await confirmDialog({ title: 'Reset password', message: `Reset the password for ${p.owner_email}? They are signed out everywhere and must choose a new one.`, confirmLabel: 'Reset password', danger: true }))) return;
        try { const r = await api.post(`/admin/partners/${id}/reset-password`); credentials('New temporary password', r.ownerEmail, r.temporaryPassword, r.notice); await load(); } catch (e) { toast(e.message, 'bad'); }
      } }, 'Reset password')] : [],
      body: h('div', { class: 'stack' }, h('dl', { class: 'kv' }, h('dt', {}, 'Owner'), h('dd', {}, `${p.owner_name} (${p.owner_email})`), h('dt', {}, 'Phone'), h('dd', {}, p.contact_phone || '-'),
        h('dt', {}, 'QR payment'), h('dd', {}, p.qr_configured ? `Set up${p.payment_bank ? `: ${p.payment_bank}` : ''}${p.payment_account_name ? `, ${p.payment_account_name}` : ''}` : 'Not set up'),
        h('dt', {}, 'Account'), h('dd', {}, p.must_change_password ? 'Has not signed in yet (still on the temporary password)' : 'Active'), h('dt', {}, 'Since'), h('dd', {}, date(p.created_at))),
      h('div', { class: 'notice info' }, 'Read-only view. Rooms, prices and stock are managed by the partner in their own dashboard.'),
      h('div', {}, h('h3', {}, `Properties (${p.hotels.length})`), table({ empty: 'No properties yet', columns: [
        { label: 'Name', key: 'name' }, { label: 'Type', render: (x) => badge(x.type) }, { label: 'Stars', render: (x) => stars(x.stars) }, { label: 'Destination', key: 'destination_name' },
        { label: 'Rooms', num: true, key: 'rooms' }, { label: 'From (USD)', num: true, render: (x) => Number(x.from_price_usd).toFixed(2) }], rows: p.hotels }))),
    });
  }

  const search = debounce((v) => { state.q = v; state.page = 1; load(); });
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' }, h('div', { class: 'row between' },
    h('input', { class: 'input', type: 'search', placeholder: 'Search business, owner or email', 'aria-label': 'Search partners', style: 'max-width:300px', oninput: (e) => search(e.target.value) }),
    isAdmin ? h('button', { class: 'btn primary', type: 'button', onclick: createForm }, icon('plus'), 'Create partner account') : h('span', { class: 'muted small' }, 'Only administrators can create partner accounts.')), box);
}
