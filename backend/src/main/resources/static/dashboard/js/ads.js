// Business-side advertising screens (used by the Business portal and by the Partner dashboard for hotel owners).
import { confirmDialog, copyButton, date, dateTime, field, h, icon, imagePicker, input, modal, num, select, showErrors, successDialog, table, textarea, toast, validate, t } from './ui.js';
import { reportHeroBar } from './charts.js';
import {
  CATEGORIES, L, PLACEMENTS, amountOf, dailyBars, pct, preview, riel, statCard, statusBadge, thumb, usd,
} from './ads-common.js';

const todayIso = () => new Date().toISOString().slice(0, 10);
const addDays = (iso, n) => { const d = new Date(`${iso}T00:00:00`); d.setDate(d.getDate() + n); return d.toISOString().slice(0, 10); };

/* ---------------- account creation (shown on the sign-in screen) ---------------- */
export function registerBusinessModal(onDone) {
  const owner = input({ required: true, maxlength: 80, autocomplete: 'name' });
  const business = input({ required: true, maxlength: 100 });
  const category = select(CATEGORIES, 'hotel');
  const email = input({ type: 'email', required: true, maxlength: 160, autocomplete: 'username' });
  const phone = input({ maxlength: 30, placeholder: '+855 ...' });
  const pw = input({ type: 'password', required: true, minlength: 10, maxlength: 128, autocomplete: 'new-password', placeholder: '10+ characters, letters and a number' });
  const errors = h('div', { 'aria-live': 'polite' });
  const m = modal({
    title: 'Create a business account', width: 560,
    body: h('div', { class: 'stack' },
      h('p', { class: 'muted small' }, 'Hotels, restaurants, cafés, camping sites, tour operators and other travel businesses can promote themselves inside WAYFARER. Our team verifies every business before its first campaign goes live.'),
      h('div', { class: 'form-grid' },
        field('Business name', business, { required: true, full: true }),
        field('Business type', category),
        field('Phone', phone),
        field('Your name', owner, { required: true }),
        field('Email', email, { required: true }),
        field('Password', pw, { required: true, full: true })),
      errors),
    actions: [
      h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
      h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        if (!validate([
          { input: business, label: 'Business name', required: true, minLen: 2, maxLen: 100 },
          { input: owner, label: 'Your name', required: true, minLen: 2, maxLen: 80 },
          { input: email, label: 'Email', required: true, email: true },
          { input: pw, label: 'Password', required: true, minLen: 10, maxLen: 128, custom: (v) => (/[A-Za-z]/.test(v) && /\d/.test(v) ? null : 'Use letters and at least one number') },
        ], errors)) return;
        m.setBusy(true);
        try {
          const res = await fetch('/api/business/register', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: email.value.trim(), password: pw.value, ownerName: owner.value.trim(), businessName: business.value.trim(), category: category.value, phone: phone.value.trim() || null }),
          });
          const data = await res.json().catch(() => null);
          if (!res.ok) throw new Error(data?.error?.message || 'Could not create the account');
          m.close();
          onDone(data);
        } catch (e) { showErrors(errors, e); m.setBusy(false); }
      } }, icon('check'), 'Create a business account'),
    ],
  });
}

/* ---------------- overview ---------------- */
export async function adsDashboardPage({ api, user }) {
  const [a, profile] = await Promise.all([api.get('/business/analytics'), api.get('/business/profile')]);
  const tot = a.totals;
  const unverified = profile.verification_status !== 'verified';
  return h('div', { class: 'stack report-page' },
    reportHeroBar({ user, roleTitle: 'Ad performance', subtitle: 'Impressions, clicks and spend for your campaigns', actionHref: '#/campaigns', actionTitle: 'New campaign' }),
    unverified ? h('div', { class: `notice ${profile.verification_status === 'pending' ? 'info' : ''}` },
      profile.verification_status === 'pending'
        ? 'Your business is waiting for verification. You can prepare campaigns now and submit them once our team has verified your business.'
        : `Verification: ${profile.verification_status}. ${profile.verification_note || ''}`) : null,
    h('div', { class: 'stats' },
      statCard('Impressions', num(tot.impressions), 'Times travellers saw your ads'),
      statCard('Clicks', num(tot.clicks), 'Taps on your ads'),
      statCard('Click rate', pct(tot.ctr), 'Clicks ÷ impressions'),
      statCard('Total spent', usd(tot.spent_usd), 'Verified payments'),
      statCard('Active campaigns', num(tot.active_campaigns), `${num(tot.scheduled_campaigns)} scheduled · ${num(tot.expired_campaigns)} expired`),
      Number(tot.pending_usd) > 0 ? statCard('Awaiting payment', usd(tot.pending_usd), 'Open payments') : null),
    h('section', { class: 'card' },
      h('div', { class: 'card-head' }, h('div', {}, h('h2', {}, 'Impressions and clicks per day'), h('p', { class: 'muted small' }, 'Last 30 days'))),
      h('div', { class: 'card-pad' }, dailyBars(a.daily))),
    h('section', { class: 'card' },
      h('div', { class: 'card-head' }, h('h2', {}, 'Campaigns')),
      campaignTable(a.campaigns, (c) => { location.hash = `#/campaigns/${c.id}`; })),
    h('p', { class: 'muted small' }, 'Paid placements are always labelled Sponsored in the app.'));
}

function campaignTable(items, onClick) {
  return table({
    empty: 'No campaigns yet',
    rows: items,
    onRowClick: onClick,
    columns: [
      { label: 'Campaign', render: (c) => h('div', { class: 'cell-title' }, thumb(c.image_url), h('div', {}, h('strong', {}, L(c.title_en, c.title_km)), h('span', {}, L(c.package_name_en, c.package_name_km)))) },
      { label: 'Dates', render: (c) => `${date(c.start_date)} – ${date(c.end_date)}` },
      { label: 'Status', render: (c) => statusBadge(c.status) },
      { label: 'Impressions', num: true, render: (c) => num(c.impressions) },
      { label: 'Clicks', num: true, render: (c) => num(c.clicks) },
      { label: 'Click rate', num: true, render: (c) => pct(c.ctr) },
      { label: 'Price', num: true, render: (c) => usd(c.price_usd) },
    ],
  });
}

/* ---------------- campaigns list + detail ---------------- */
export async function campaignsPage({ api, params, refresh }) {
  if (params && params[0]) return campaignDetail({ api, id: params[0], refresh });
  const res = await api.get('/business/campaigns');
  const root = h('div', { class: 'stack' });
  root.append(
    h('div', { class: 'row between' },
      h('p', { class: 'muted' }, 'Create a campaign, pay by KHQR or bank transfer, and it goes live on the dates you choose.'),
      h('button', { class: 'btn primary', type: 'button', onclick: () => campaignForm({ api, refresh }) }, icon('plus'), 'New campaign')),
    h('section', { class: 'card' }, campaignTable(res.items, (c) => { location.hash = `#/campaigns/${c.id}`; })));
  return root;
}

async function campaignDetail({ api, id, refresh }) {
  const c = await api.get(`/business/campaigns/${id}`);
  const root = h('div', { class: 'stack' });
  const act = (label, ic, fn, cls = '') => h('button', { class: `btn ${cls}`.trim(), type: 'button', onclick: fn }, ic ? icon(ic) : null, label);
  const run = async (fn, msg) => { try { await fn(); if (msg) toast(msg, 'ok'); refresh(); } catch (e) { toast(e.message, 'bad'); } };

  const actions = [
    act('Back', 'log', () => { location.hash = '#/campaigns'; }),
    c.can_edit ? act('Edit', 'edit', () => campaignForm({ api, refresh, existing: c })) : null,
    c.can_edit ? act('Submit for review', 'check', () => run(() => api.post(`/business/campaigns/${id}/submit`), 'Submitted for review'), 'primary') : null,
    c.can_pay ? act('Pay now', 'card', () => payFlow({ api, campaign: c, refresh }), 'primary') : null,
    c.can_renew ? act('Renew', 'refresh', () => renewFlow({ api, campaign: c, refresh })) : null,
    c.can_cancel ? act('Cancel campaign', 'trash', async () => {
      if (await confirmDialog({ title: 'Cancel campaign', message: 'Cancel this campaign? You can create a new one at any time.', confirmLabel: 'Cancel campaign', danger: true })) run(() => api.post(`/business/campaigns/${id}/cancel`), 'Campaign cancelled');
    }, 'danger') : null,
  ];

  root.append(
    h('div', { class: 'row between' }, h('div', { class: 'row' }, h('h2', { style: 'margin:0' }, L(c.title_en, c.title_km)), statusBadge(c.status)), h('div', { class: 'row' }, actions)),
    c.review_note && (c.status === 'rejected' || c.status === 'cancelled') ? h('div', { class: 'notice' }, `${t('Reason')}: ${c.review_note}`) : null,
    h('div', { class: 'grid-2' },
      h('section', { class: 'card card-pad stack' }, preview(c), h('dl', { class: 'kv' },
        h('dt', {}, 'Package'), h('dd', {}, L(c.package_name_en, c.package_name_km)),
        h('dt', {}, 'Dates'), h('dd', {}, `${date(c.start_date)} – ${date(c.end_date)}`),
        h('dt', {}, 'Price'), h('dd', {}, usd(c.price_usd)),
        h('dt', {}, 'Impressions'), h('dd', {}, num(c.impressions)),
        h('dt', {}, 'Clicks'), h('dd', {}, `${num(c.clicks)} (${pct(c.ctr)})`))),
      h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Impressions and clicks per day')), h('div', { class: 'card-pad' }, c.daily.length ? dailyBars(c.daily) : h('p', { class: 'muted' }, 'Nothing to show')))));
  return root;
}

/* ---------------- create / edit ---------------- */
async function campaignForm({ api, refresh, existing }) {
  const [pk, dest] = await Promise.all([api.get('/business/packages'), api.get('/destinations', { pageSize: 40, sort: 'name' })]);
  const packages = pk.items;
  let pkg = packages.find((p) => p.id === existing?.package_id) || packages[0];
  const e = existing || {};
  const title = input({ value: e.title_en || '', maxlength: 90, required: true });
  const titleKm = input({ value: e.title_km || '', maxlength: 90 });
  const body = textarea({ maxlength: 300, rows: 2 }); body.value = e.body_en || '';
  const bodyKm = textarea({ maxlength: 300, rows: 2 }); bodyKm.value = e.body_km || '';
  const offer = input({ value: e.offer_en || '', maxlength: 120, placeholder: 'e.g. 10% off for WAYFARER travellers' });
  const offerKm = input({ value: e.offer_km || '', maxlength: 120 });
  const link = input({ value: e.cta_url || '', maxlength: 500, placeholder: 'https://...' });
  const article = textarea({ maxlength: 6000, rows: 8 }); article.value = e.article_en || '';
  const articleKm = textarea({ maxlength: 6000, rows: 8 }); articleKm.value = e.article_km || '';
  const festival = input({ value: e.festival_name_en || '', maxlength: 80, placeholder: 'e.g. Khmer New Year' });
  const festivalKm = input({ value: e.festival_name_km || '', maxlength: 80 });
  const keywords = input({ value: (e.keywords || []).join(', '), maxlength: 300, placeholder: 'coffee, brunch, breakfast' });
  const image = imagePicker({ current: e.image_url || null, label: 'Choose image', upload: (f) => api.upload(f) });
  const start = input({ type: 'date', value: e.start_date ? String(e.start_date).slice(0, 10) : addDays(todayIso(), 3), min: todayIso() });
  const units = input({ type: 'number', min: 1, max: 52, value: e.units || 1 });
  const targets = new Set((e.target_destination_ids || []).map(String));
  const chips = h('div', { class: 'chips' });
  const allBox = h('input', { type: 'checkbox', checked: targets.size === 0 });
  const errors = h('div', { 'aria-live': 'polite' });
  const quoteBox = h('div', { class: 'quote-box' });
  const pkgGrid = h('div', { class: 'pkg-grid' });
  const extra = h('div', { class: 'stack' });

  const drawChips = () => {
    chips.replaceChildren(h('label', { class: 'check' }, allBox, 'All Cambodia'),
      ...dest.items.map((d) => {
        const cb = h('input', { type: 'checkbox', checked: targets.has(String(d.id)), disabled: allBox.checked,
          onchange: () => { if (cb.checked) targets.add(String(d.id)); else targets.delete(String(d.id)); } });
        return h('label', { class: 'check' }, cb, d.name);
      }));
  };
  allBox.addEventListener('change', () => { if (allBox.checked) targets.clear(); drawChips(); });

  const drawExtra = () => {
    const pl = pkg.placement;
    extra.replaceChildren(
      pl === 'sponsored_article' ? h('div', { class: 'form-grid' }, field('Article (English)', article, { full: true, required: true }), field('Article (Khmer)', articleKm, { full: true })) : null,
      pl === 'festival' ? h('div', { class: 'form-grid' }, field('Festival name (English)', festival, { required: true }), field('Festival name (Khmer)', festivalKm)) : null,
      pl === 'top_search' ? h('div', { class: 'form-grid' }, field('Keywords', keywords, { full: true, hint: 'Words that make your business relevant when a traveller searches' })) : null);
  };

  const drawPackages = () => {
    pkgGrid.replaceChildren(...packages.map((p) => h('button', {
      class: 'pkg', type: 'button', 'aria-pressed': String(p.id === pkg.id),
      onclick: () => { pkg = p; units.min = p.min_units; units.max = p.max_units; if (Number(units.value) < p.min_units) units.value = p.min_units; drawPackages(); drawExtra(); quote(); },
    }, h('strong', {}, L(p.name_en, p.name_km)),
    h('span', { class: 'price' }, usd(p.unit_price_usd), h('small', {}, ` / ${p.unit}`)),
    h('span', { class: 'desc' }, L(p.description_en, p.description_km)))));
  };

  let quoteSeq = 0;
  const quote = async () => {
    const seq = ++quoteSeq;
    try {
      const q = await api.post('/business/quote', { packageId: pkg.id, units: Number(units.value) || 1, startDate: start.value, currency: 'USD' });
      if (seq !== quoteSeq) return;
      quoteBox.replaceChildren(
        h('div', { class: 'row between' }, h('span', {}, `${date(q.startDate)} – ${date(q.endDate)} · ${q.days} days`), h('span', { class: 'total' }, usd(q.priceUsd))),
        h('div', { class: 'muted small' }, `≈ ${riel(q.amountKhr)}`),
        h('div', { class: q.available ? 'ok' : 'bad' }, q.available ? `Free slots left: ${q.capacity - q.booked} of ${q.capacity}` : 'Full'));
    } catch (ex) { if (seq === quoteSeq) quoteBox.replaceChildren(h('div', { class: 'bad' }, ex.message)); }
  };
  [units, start].forEach((el) => el.addEventListener('change', quote));

  const save = async (submit, m) => {
    if (!validate([
      { input: title, label: 'Title (English)', required: true, maxLen: 90 },
      { input: start, label: 'Start date', required: true },
      { input: units, label: 'How long', required: true },
      { input: link, label: 'Link (https://...)', maxLen: 500, custom: (v) => (!v || /^https:\/\//i.test(v) || /^tel:/i.test(v) ? null : 'Use a link that starts with https://') },
    ], errors)) return;
    m.setBusy(true);
    const payload = {
      packageId: pkg.id, titleEn: title.value.trim(), titleKm: titleKm.value.trim() || null, bodyEn: body.value.trim() || null, bodyKm: bodyKm.value.trim() || null,
      offerEn: offer.value.trim() || null, offerKm: offerKm.value.trim() || null, articleEn: article.value.trim() || null, articleKm: articleKm.value.trim() || null,
      imageUrl: image.get(), ctaUrl: link.value.trim() || null, targetDestinationIds: [...targets], keywords: keywords.value.split(',').map((s) => s.trim()).filter(Boolean),
      festivalNameEn: festival.value.trim() || null, festivalNameKm: festivalKm.value.trim() || null, startDate: start.value, units: Number(units.value), submit,
    };
    try {
      const saved = existing ? await api.put(`/business/campaigns/${existing.id}`, payload) : await api.post('/business/campaigns', payload);
      m.close();
      toast(submit ? 'Submitted for review' : 'Draft saved', 'ok');
      location.hash = `#/campaigns/${saved.id}`;
      refresh();
    } catch (ex) { showErrors(errors, ex); m.setBusy(false); }
  };

  const m = modal({
    title: existing ? 'Edit campaign' : 'New campaign', width: 860,
    body: h('div', { class: 'stack' },
      h('section', { class: 'stack' }, h('h3', {}, 'Choose a package'), pkgGrid),
      h('div', { class: 'form-grid' },
        field('Start date', start, { required: true }),
        field('How long', units, { hint: 'Number of weeks, months or posts' }),
        h('div', { class: 'full' }, quoteBox)),
      h('section', { class: 'stack' }, h('h3', {}, 'Where should it appear?'), chips),
      h('div', { class: 'form-grid' },
        field('Title (English)', title, { required: true }), field('Title (Khmer)', titleKm),
        field('Short text (English)', body), field('Short text (Khmer)', bodyKm),
        field('Promotional offer (English)', offer), field('Promotional offer (Khmer)', offerKm),
        field('Link (https://...)', link, { full: true }),
        h('div', { class: 'full' }, h('label', { class: 'small muted' }, 'Image'), image.el)),
      extra, errors),
    actions: [
      h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
      h('button', { class: 'btn', type: 'button', onclick: () => save(false, m) }, 'Save draft'),
      h('button', { class: 'btn primary', type: 'button', onclick: () => save(true, m) }, icon('check'), 'Submit for review'),
    ],
  });
  drawPackages(); drawChips(); drawExtra(); quote();
}

/* ---------------- renew ---------------- */
function renewFlow({ api, campaign, refresh }) {
  const units = input({ type: 'number', min: 1, max: 52, value: campaign.units });
  const start = input({ type: 'date', min: todayIso(), value: addDays(String(campaign.end_date).slice(0, 10), 1) < todayIso() ? todayIso() : addDays(String(campaign.end_date).slice(0, 10), 1) });
  const errors = h('div', { 'aria-live': 'polite' });
  const m = modal({
    title: 'Renew', width: 480,
    body: h('div', { class: 'stack' }, h('p', { class: 'muted small' }, 'A renewal keeps the approved content and goes straight to payment.'),
      h('div', { class: 'form-grid' }, field('Start date', start), field('How long', units)), errors),
    actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
      h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        m.setBusy(true);
        try { const n = await api.post(`/business/campaigns/${campaign.id}/renew`, { units: Number(units.value), startDate: start.value }); m.close(); location.hash = `#/campaigns/${n.id}`; refresh(); } catch (ex) { showErrors(errors, ex); m.setBusy(false); }
      } }, icon('refresh'), 'Renew')],
  });
}

/* ---------------- payment (KHQR / bank transfer, USD / KHR) ---------------- */
async function payFlow({ api, campaign, refresh }) {
  let method = 'khqr', currency = 'USD';
  const body = h('div', { class: 'stack' });
  const m = modal({ title: 'Pay now', width: 560, body, actions: [] });
  const seg = (opts, cur, on) => h('div', { class: 'seg' }, opts.map(([v, label]) => h('button', { type: 'button', 'aria-pressed': String(v === cur), onclick: () => on(v) }, label)));

  const pick = () => {
    body.replaceChildren(
      h('div', { class: 'quote-box' }, h('div', { class: 'row between' }, h('span', {}, L(campaign.title_en, campaign.title_km)), h('span', { class: 'total' }, usd(campaign.price_usd)))),
      h('div', { class: 'stack', style: 'gap:6px' }, h('label', { class: 'small muted' }, 'Method'), seg([['khqr', t('Pay with KHQR')], ['bank_transfer', t('Bank transfer')]], method, (v) => { method = v; pick(); })),
      h('div', { class: 'stack', style: 'gap:6px' }, h('label', { class: 'small muted' }, 'Currency'), seg([['USD', 'USD $'], ['KHR', 'KHR ៛']], currency, (v) => { currency = v; pick(); })),
      h('div', { class: 'row' }, h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
        h('button', { class: 'btn primary', type: 'button', onclick: async (ev) => {
          ev.target.disabled = true;
          try { show(await api.post(`/business/campaigns/${campaign.id}/payment`, { method, currency })); } catch (ex) { toast(ex.message, 'bad'); ev.target.disabled = false; }
        } }, 'Create payment')));
  };

  const show = (p) => {
    const ins = p.instructions || {};
    const txn = input({ maxlength: 64, placeholder: 'e.g. ACLEDA 77310452' });
    const proof = imagePicker({ label: 'Choose image', upload: (f) => api.upload(f) });
    const errors = h('div', { 'aria-live': 'polite' });
    body.replaceChildren(h('div', { class: 'pay-box' },
      h('div', { class: 'quote-box' }, h('span', { class: 'muted small' }, 'Amount to pay'), h('span', { class: 'total' }, amountOf(p.currency, p.amount_local)),
        p.currency === 'KHR' ? h('span', { class: 'muted small' }, `${usd(p.amount_usd)} · 1 USD = ${num(p.fx_rate)} ៛`) : null),
      h('div', {}, h('div', { class: 'small muted' }, 'Include this reference in the transfer note'), h('div', { class: 'row' }, h('span', { class: 'ref grow' }, p.reference), copyButton(p.reference))),
      p.method === 'khqr'
        ? (ins.khqrImageUrl ? h('img', { class: 'qr', src: ins.khqrImageUrl, alt: 'KHQR' }) : h('div', { class: 'notice' }, 'The KHQR code has not been published yet. Use bank transfer.'))
        : null,
      h('dl', { class: 'kv' }, h('dt', {}, 'Account name'), h('dd', {}, ins.accountName || '-'), h('dt', {}, 'Bank'), h('dd', {}, ins.bankName || '-'), ins.accountNumber ? [h('dt', {}, 'Account number'), h('dd', {}, ins.accountNumber)] : null),
      ins.instructions ? h('p', { class: 'muted small' }, ins.instructions) : null,
      h('div', { class: 'form-grid' }, field('Bank transaction reference', txn, { required: true, full: true, hint: 'From your banking app receipt' }), h('div', { class: 'full' }, h('label', { class: 'small muted' }, 'Payment proof (optional)'), proof.el)),
      errors,
      h('div', { class: 'row' }, h('button', { class: 'btn', type: 'button', onclick: () => { m.close(); refresh(); } }, 'Close'),
        h('button', { class: 'btn primary', type: 'button', onclick: async (ev) => {
          if (!validate([{ input: txn, label: 'Bank transaction reference', required: true, minLen: 4, maxLen: 64 }], errors)) return;
          ev.target.disabled = true;
          try {
            await api.post(`/business/payments/${p.id}/claim`, { bankTxnRef: txn.value.trim(), proofUrl: proof.get() });
            m.close();
            await successDialog({ title: 'Payment submitted', message: 'We will check that the money arrived and then schedule your campaign.', details: [['Reference', p.reference]] });
            refresh();
          } catch (ex) { showErrors(errors, ex); ev.target.disabled = false; }
        } }, icon('check'), 'I have paid'))));
  };
  pick();
}

/* ---------------- spend history ---------------- */
export async function adPaymentsPage({ api }) {
  const r = await api.get('/business/payments');
  const total = r.items.filter((p) => p.status === 'verified').reduce((s, p) => s + Number(p.amount_usd), 0);
  return h('div', { class: 'stack' },
    h('div', { class: 'stats' }, statCard('Total spent', usd(total), 'Verified payments'), statCard('Awaiting payment', usd(r.items.filter((p) => ['pending', 'claimed'].includes(p.status)).reduce((s, p) => s + Number(p.amount_usd), 0)), 'Open payments')),
    h('section', { class: 'card' }, table({
      empty: 'No payments yet', rows: r.items,
      columns: [
        { label: 'Reference', render: (p) => h('code', {}, p.reference) },
        { label: 'Campaign', key: 'campaign_title' },
        { label: 'Method', render: (p) => (p.method === 'khqr' ? 'KHQR' : t('Bank transfer')) },
        { label: 'Amount', num: true, render: (p) => amountOf(p.currency, p.amount_local) },
        { label: 'Status', render: (p) => statusBadge(p.status) },
        { label: 'Date', render: (p) => dateTime(p.created_at) },
      ],
    })));
}

/* ---------------- business profile ---------------- */
export async function businessProfilePage({ api, toast: say }) {
  const [b, dest] = await Promise.all([api.get('/business/profile'), api.get('/destinations', { pageSize: 40, sort: 'name' })]);
  const name = input({ value: b.name || '', maxlength: 100, required: true });
  const nameKm = input({ value: b.name_km || '', maxlength: 100 });
  const category = select(CATEGORIES, b.category);
  const desc = textarea({ maxlength: 1000, rows: 3 }); desc.value = b.description || '';
  const descKm = textarea({ maxlength: 1000, rows: 3 }); descKm.value = b.description_km || '';
  const phone = input({ value: b.phone || '', maxlength: 30 });
  const website = input({ value: b.website || '', maxlength: 200, placeholder: 'https://...' });
  const address = input({ value: b.address || '', maxlength: 200 });
  const location_ = select([['', '-'], ...dest.items.map((d) => [d.id, d.name])], b.destination_id || '');
  const logo = imagePicker({ current: b.logo_url, label: 'Choose image', round: true, upload: (f) => api.upload(f) });
  const errors = h('div', { 'aria-live': 'polite' });
  const tone = { verified: 'ok', pending: 'warn', rejected: 'bad', suspended: 'bad' }[b.verification_status] || 'neutral';
  return h('div', { class: 'stack' },
    h('section', { class: 'card card-pad row between' }, h('div', {}, h('strong', {}, 'Verification'), b.verification_note ? h('p', { class: 'muted small' }, b.verification_note) : null),
      h('span', { class: `badge ${tone}` }, b.verification_status)),
    h('section', { class: 'card card-pad stack' },
      h('div', { class: 'form-grid' },
        field('Business name', name, { required: true }), field('Business name (Khmer)', nameKm),
        field('Business type', category), field('Phone', phone),
        field('Description (English)', desc, { full: true }), field('Description (Khmer)', descKm, { full: true }),
        field('Website', website), field('Address', address), field('Main location', location_),
        h('div', { class: 'full' }, h('label', { class: 'small muted' }, 'Logo'), logo.el)),
      errors,
      h('div', {}, h('button', { class: 'btn primary', type: 'button', onclick: async (ev) => {
        if (!validate([{ input: name, label: 'Business name', required: true, minLen: 2, maxLen: 100 }, { input: website, label: 'Website', maxLen: 200 }], errors)) return;
        ev.target.disabled = true;
        try {
          await api.put('/business/profile', { name: name.value.trim(), nameKm: nameKm.value.trim() || null, category: category.value, description: desc.value.trim() || null, descriptionKm: descKm.value.trim() || null,
            phone: phone.value.trim() || null, website: website.value.trim() || null, address: address.value.trim() || null, destinationId: location_.value || null, logoUrl: logo.get() });
          showErrors(errors, null); (say || toast)('Saved', 'ok');
        } catch (ex) { showErrors(errors, ex); } finally { ev.target.disabled = false; }
      } }, 'Save'))));
}
