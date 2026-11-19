// Partner account helpers used by the Manage Users page: the administrator creates the owner login, hands over a
// one-time temporary password, and can see (not edit) each partner's properties.
import { badge, confirmDialog, copyButton, date, field, h, input, modal, num, showErrors, stars, successDialog, table, toast, validate } from '/dashboard/js/ui.js';

function credentials(title, email, password, notice, details = []) {
  const portalUrl = `${location.origin}/partner`;
  successDialog({
    title,
    message: 'Hand these credentials to the partner. They will be prompted to set their own password on first sign-in.',
    details,
    buttonLabel: 'I have copied the credentials',
    extra: h('div', { class: 'stack', style: 'text-align:left;width:100%' },
      h('div', { class: 'notice' }, notice),
      h('div', { class: 'stack', style: 'gap:6px' }, h('div', { class: 'small muted' }, 'Partner sign-in page'), h('div', { class: 'row' }, h('span', { class: 'secret grow' }, portalUrl), copyButton(portalUrl))),
      h('div', { class: 'stack', style: 'gap:6px' }, h('div', { class: 'small muted' }, 'Owner login email'), h('div', { class: 'row' }, h('span', { class: 'secret grow' }, email), copyButton(email))),
      h('div', { class: 'stack', style: 'gap:6px' }, h('div', { class: 'small muted' }, 'One-time temporary password'), h('div', { class: 'row' }, h('span', { class: 'secret grow' }, password), copyButton(password)))),
  });
}

/** Opens the "Create partner account" modal in place. `onCreated` runs after a successful create. */
export function createPartnerModal({ api, onCreated }) {
  const business = input({ required: true, maxlength: 100, placeholder: 'e.g. Sokha Bungalows' });
  const owner = input({ required: true, maxlength: 80, placeholder: 'Owner full name' });
  const email = input({ type: 'email', required: true, maxlength: 160, placeholder: 'owner@example.com' });
  const phone = input({ maxlength: 30, placeholder: 'Optional, e.g. +855 12 345 678' });
  const pw = input({ type: 'password', required: true, minlength: 8, maxlength: 100, placeholder: 'Min 8 characters (letters & numbers)' });
  const errors = h('div', { 'aria-live': 'polite' });
  const m = modal({
    title: 'Create partner account', width: 560,
    body: h('div', { class: 'stack' },
      h('p', { class: 'muted small' }, 'Creates the partner business and owner login account so they can sign in to the Partner Dashboard to manage properties, rooms, prices and QR payment.'),
      h('div', { class: 'form-grid' },
        field('Business name', business, { full: true, required: true }),
        field('Owner name', owner, { required: true }),
        field('Phone', phone),
        field('Owner email (the login)', email, { full: true, required: true }),
        field('Password', pw, { full: true, required: true })),
      errors),
    actions: [
      h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
      h('button', {
        class: 'btn primary',
        type: 'button',
        onclick: async () => {
          if (!validate([
            { input: business, label: 'Business name', required: true, minLen: 2, maxLen: 100 },
            { input: owner, label: 'Owner name', required: true, minLen: 2, maxLen: 80 },
            { input: phone, label: 'Phone', maxLen: 30 },
            { input: email, label: 'Owner email', required: true, email: true, maxLen: 160 },
            { input: pw, label: 'Password', required: true, minLen: 8, maxLen: 100 },
          ], errors)) return;
          m.setBusy(true);
          try {
            const r = await api.post('/admin/partners', {
              businessName: business.value.trim(),
              ownerName: owner.value.trim(),
              email: email.value.trim(),
              phone: phone.value.trim() || null,
              password: pw.value,
            });
            m.close();
            await onCreated?.();
            credentials(
              'Partner account created',
              r.owner_email,
              r.temporaryPassword || pw.value,
              r.notice || 'Account created with the password you set. Give these credentials to the partner.',
              [['Business', business.value.trim()], ['Owner', owner.value.trim()]],
            );
          } catch (e) {
            showErrors(errors, e);
            m.setBusy(false);
          }
        },
      }, 'Create partner account'),
    ],
  });
}

/** Read-only partner business detail, with password reset for administrators. */
export async function partnerDetailModal({ api, id, isAdmin, onChanged }) {
  const p = await api.get(`/admin/partners/${id}`).catch((e) => { toast(e.message, 'bad'); return null; });
  if (!p) return;
  const dm = modal({
    title: p.name, width: 780,
    actions: isAdmin ? [h('button', { class: 'btn danger', type: 'button', onclick: async () => {
      if (!(await confirmDialog({ title: 'Delete partner account', message: `Delete the account for ${p.owner_email}? Their login is erased and they can no longer sign in. A partner who still has properties cannot be deleted. This cannot be undone.`, confirmLabel: 'Delete account', danger: true }))) return;
      try {
        await api.del(`/admin/users/${p.user_id}`);
        dm.close();
        await onChanged?.();
        toast('Partner account deleted', 'ok');
      } catch (e) { toast(e.message, 'bad'); }
    } }, 'Delete account'), h('button', { class: 'btn danger', type: 'button', onclick: async () => {
      if (!(await confirmDialog({ title: 'Reset password', message: `Reset the password for ${p.owner_email}? They are signed out everywhere and must choose a new one.`, confirmLabel: 'Reset password', danger: true }))) return;
      try {
        const r = await api.post(`/admin/partners/${id}/reset-password`);
        dm.close();
        await onChanged?.();
        credentials('Temporary password issued', r.ownerEmail, r.temporaryPassword, r.notice, [['Business', p.name]]);
      } catch (e) { toast(e.message, 'bad'); }
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

/** Columns for the partner businesses table shown in the Hotel Partners category. */
export function partnerColumns() {
  return [
    { label: 'Business', sortValue: (p) => p.name || '', render: (p) => h('div', {}, h('strong', {}, p.name), h('div', { class: 'muted small' }, p.contact_phone || '')) },
    { label: 'Owner login', sortValue: (p) => p.owner_name || '', render: (p) => h('div', {}, p.owner_name, h('div', { class: 'muted small' }, p.owner_email)) },
    { label: 'Properties', num: true, sortValue: (p) => Number(p.hotels || 0), render: (p) => num(p.hotels) },
    { label: 'Rooms', num: true, sortValue: (p) => Number(p.rooms || 0), render: (p) => num(p.rooms) },
    { label: 'Bookings', num: true, sortValue: (p) => Number(p.bookings || 0), render: (p) => num(p.bookings) },
    { label: 'QR payment', sortValue: (p) => (p.qr_configured ? 1 : 0), render: (p) => (p.qr_configured ? h('span', { class: 'badge ok' }, 'set up') : h('span', { class: 'badge neutral' }, 'not yet')) },
    { label: 'Account', sortValue: (p) => (p.must_change_password ? 0 : 1), render: (p) => (p.must_change_password ? h('span', { class: 'badge warn' }, 'never signed in') : h('span', { class: 'badge ok' }, 'active')) },
    { label: 'Created', sortValue: (p) => p.created_at || '', render: (p) => date(p.created_at) },
  ];
}
