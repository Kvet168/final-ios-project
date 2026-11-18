// Advertising administration: overview, businesses, campaigns, payments, packages and payment settings, placement planner.
import { confirmDialog, date, dateTime, field, h, icon, imagePicker, input, modal, num, pager, select, showErrors, table, textarea, toast, validate } from '/dashboard/js/ui.js';
import { reportHeroBar } from '/dashboard/js/charts.js';
import {
  CATEGORIES, L, PLACEMENTS, STATUS_OPTIONS, amountOf, dailyBars, pct, preview, revenueBars, statCard, statusBadge, thumb, usd,
} from '/dashboard/js/ads-common.js';

const isAdmin = (u) => u?.role === 'admin';

/** Asks for a reason, then runs `fn(reason)`. */
function reasonDialog({ title, label = 'Reason', confirmLabel, fn }) {
  const reason = textarea({ maxlength: 500, rows: 3, required: true });
  const errors = h('div', { 'aria-live': 'polite' });
  const m = modal({
    title, width: 480, body: h('div', { class: 'stack' }, field(label, reason, { required: true }), errors),
    actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
      h('button', { class: 'btn danger', type: 'button', onclick: async () => {
        if (!validate([{ input: reason, label, required: true, minLen: 3, maxLen: 500 }], errors)) return;
        m.setBusy(true);
        try { await fn(reason.value.trim()); m.close(); } catch (e) { showErrors(errors, e); m.setBusy(false); }
      } }, confirmLabel || 'Reject')],
  });
}

/* ---------------- overview ---------------- */
export async function adsOverviewPage({ api, user }) {
  const a = await api.get('/admin/ads/analytics');
  const t = a.totals;
  const link = (label, n, href) => h('a', { class: `queue-link ${n > 0 ? 'hot' : ''}`, href }, h('span', {}, label), h('strong', {}, num(n)));
  return h('div', { class: 'stack report-page' },
    reportHeroBar({ user, roleTitle: 'Advertising overview', subtitle: 'Revenue, campaigns and what needs your attention', actionHref: '#/ad-campaigns', actionTitle: 'Review campaigns' }),
    h('div', { class: 'grid-2' },
      link('To review', t.to_review, '#/ad-campaigns'),
      link('Payments to verify', t.payments_to_verify, '#/ad-payments'),
      link('Businesses to verify', t.businesses_to_verify, '#/ad-businesses')),
    h('div', { class: 'stats' },
      statCard('Ad revenue', usd(t.revenue_usd), 'Verified payments'),
      statCard('This month', usd(t.revenue_month_usd)),
      statCard('Outstanding', usd(t.outstanding_usd), 'Not yet verified'),
      statCard('Impressions', num(t.impressions)),
      statCard('Clicks', num(t.clicks), `${pct(t.ctr)} click rate`),
      statCard('Active campaigns', num(t.active_campaigns), `${num(t.scheduled_campaigns)} scheduled · ${num(t.expired_campaigns)} expired`)),
    h('div', { class: 'grid-2' },
      h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Ad revenue'), h('span', { class: 'muted small' }, 'Last 30 days')), h('div', { class: 'card-pad' }, revenueBars(a.revenueDaily))),
      h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Revenue by package')),
        h('div', { class: 'card-pad' }, h('table', { class: 'mini-table' }, h('tbody', {}, a.revenueByPackage.map((p) => h('tr', {}, h('td', {}, L(p.name_en, p.name_km)), h('td', { class: 'num' }, `${num(p.payments)}×`), h('td', { class: 'num' }, usd(p.revenue_usd))))))))),
    h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Top campaigns')),
      table({ empty: 'Nothing to show', rows: a.topCampaigns, columns: [
        { label: 'Campaign', key: 'title_en' }, { label: 'Business', key: 'business_name' },
        { label: 'Package', render: (c) => PLACEMENTS[c.placement] }, { label: 'Status', render: (c) => statusBadge(c.status) },
        { label: 'Impressions', num: true, render: (c) => num(c.impressions) }, { label: 'Clicks', num: true, render: (c) => num(c.clicks) },
      ] })));
}

/* ---------------- businesses ---------------- */
export async function adBusinessesPage({ api, user }) {
  const state = { status: 'pending', q: '', page: 1 };
  const box = h('div', { class: 'stack' });
  const status = select(STATUS_OPTIONS(['pending', 'verified', 'rejected', 'suspended']), state.status, { 'aria-label': 'Status' });
  const q = input({ type: 'search', placeholder: 'Search', maxlength: 60 });
  status.addEventListener('change', () => { state.status = status.value; state.page = 1; load(); });
  q.addEventListener('change', () => { state.q = q.value; state.page = 1; load(); });
  async function load() {
    const r = await api.get('/admin/ads/businesses', { status: state.status || undefined, q: state.q || undefined, page: state.page, pageSize: 20 });
    box.replaceChildren(h('section', { class: 'card' }, table({
      empty: 'Nothing to show', rows: r.items, startIndex: (r.page - 1) * r.pageSize + 1, onRowClick: (b) => businessModal(b.id),
      columns: [
        { label: 'Business', render: (b) => h('div', {}, h('strong', {}, b.name), h('div', { class: 'small muted' }, b.owner_email)) },
        { label: 'Business type', render: (b) => CATEGORIES.find((c) => c[0] === b.category)?.[1] || b.category },
        { label: 'Status', render: (b) => statusBadge(b.verification_status) },
        { label: 'Campaigns', num: true, render: (b) => num(b.campaigns) },
        { label: 'Total spent', num: true, render: (b) => usd(b.spent_usd) },
        { label: 'Date', render: (b) => date(b.created_at) },
      ] }), pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } })));
  }
  async function businessModal(id) {
    const b = await api.get(`/admin/ads/businesses/${id}`);
    const done = (m) => { m.close(); load(); };
    const m = modal({
      title: b.name, width: 720,
      body: h('div', { class: 'stack' },
        h('div', { class: 'row' }, statusBadge(b.verification_status), b.verification_note ? h('span', { class: 'muted small' }, b.verification_note) : null),
        h('dl', { class: 'kv' },
          h('dt', {}, 'Name'), h('dd', {}, `${b.owner_name} · ${b.owner_email}`),
          h('dt', {}, 'Phone'), h('dd', {}, b.phone || '-'),
          h('dt', {}, 'Website'), h('dd', {}, b.website || '-'),
          h('dt', {}, 'Address'), h('dd', {}, b.address || '-'),
          h('dt', {}, 'Description (English)'), h('dd', {}, b.description || '-'),
          h('dt', {}, 'Description (Khmer)'), h('dd', {}, b.description_km || '-')),
        h('h3', {}, 'Campaigns'),
        b.campaigns.length ? h('table', { class: 'mini-table' }, h('tbody', {}, b.campaigns.map((c) => h('tr', {}, h('td', {}, c.title_en), h('td', {}, statusBadge(c.status)), h('td', { class: 'num' }, usd(c.price_usd)))))) : h('p', { class: 'muted' }, 'Nothing to show')),
      actions: [
        h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Close'),
        b.verification_status !== 'suspended' ? h('button', { class: 'btn danger', type: 'button', onclick: () => reasonDialog({ title: 'Suspend', confirmLabel: 'Suspend', fn: async (r) => { await api.post(`/admin/ads/businesses/${id}/suspend`, { reason: r }); toast('Suspended', 'ok'); done(m); } }) }, 'Suspend') : null,
        b.verification_status !== 'rejected' ? h('button', { class: 'btn danger', type: 'button', onclick: () => reasonDialog({ title: 'Reject', fn: async (r) => { await api.post(`/admin/ads/businesses/${id}/reject`, { reason: r }); toast('Rejected', 'ok'); done(m); } }) }, 'Reject') : null,
        b.verification_status !== 'verified' ? h('button', { class: 'btn primary', type: 'button', onclick: async () => { try { await api.post(`/admin/ads/businesses/${id}/verify`, {}); toast('Verified', 'ok'); done(m); } catch (e) { toast(e.message, 'bad'); } } }, icon('check'), 'Verify') : null,
      ],
    });
  }
  await load();
  return h('div', { class: 'stack' }, h('div', { class: 'row' }, status, q), box);
}

/* ---------------- campaigns ---------------- */
export async function adCampaignsPage({ api, user }) {
  const state = { status: 'pending_review', placement: '', q: '', page: 1 };
  const box = h('div', { class: 'stack' });
  const status = select(STATUS_OPTIONS(['pending_review', 'awaiting_payment', 'payment_review', 'scheduled', 'active', 'paused', 'expired', 'rejected', 'cancelled', 'draft']), state.status, { 'aria-label': 'Status' });
  const placement = select([['', 'All'], ...Object.entries(PLACEMENTS)], '', { 'aria-label': 'Package' });
  const q = input({ type: 'search', placeholder: 'Search', maxlength: 60 });
  status.addEventListener('change', () => { state.status = status.value; state.page = 1; load(); });
  placement.addEventListener('change', () => { state.placement = placement.value; state.page = 1; load(); });
  q.addEventListener('change', () => { state.q = q.value; state.page = 1; load(); });

  async function load() {
    const r = await api.get('/admin/ads/campaigns', { status: state.status || undefined, placement: state.placement || undefined, q: state.q || undefined, page: state.page, pageSize: 20 });
    box.replaceChildren(h('section', { class: 'card' }, table({
      empty: 'Nothing to show', rows: r.items, startIndex: (r.page - 1) * r.pageSize + 1, onRowClick: (c) => reviewModal(c.id),
      columns: [
        { label: 'Campaign', render: (c) => h('div', { class: 'cell-title' }, thumb(c.image_url), h('div', {}, h('strong', {}, c.title_en), h('span', {}, c.business_name))) },
        { label: 'Package', render: (c) => L(c.package_name_en, c.package_name_km) },
        { label: 'Dates', render: (c) => `${date(c.start_date)} – ${date(c.end_date)}` },
        { label: 'Status', render: (c) => statusBadge(c.status) },
        { label: 'Impressions', num: true, render: (c) => num(c.impressions) },
        { label: 'Clicks', num: true, render: (c) => num(c.clicks) },
        { label: 'Price', num: true, render: (c) => usd(c.price_usd) },
      ] }), pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } })));
  }

  async function reviewModal(id) {
    const c = await api.get(`/admin/ads/campaigns/${id}`);
    const after = (m) => { m.close(); load(); };
    const call = (m, path, body, msg) => async () => { try { await api.post(`/admin/ads/campaigns/${id}/${path}`, body); toast(msg, 'ok'); after(m); } catch (e) { toast(e.message, 'bad'); } };
    const s = c.status;
    const m = modal({
      title: c.title_en, width: 820,
      body: h('div', { class: 'stack' },
        h('div', { class: 'row' }, statusBadge(s), h('span', { class: 'muted small' }, c.business_name)),
        c.business?.verification_status !== 'verified' ? h('div', { class: 'notice' }, `Verification: ${c.business?.verification_status}`) : null,
        h('div', { class: 'grid-2' },
          h('div', { class: 'stack' }, preview(c, c.business_name), c.cta_url ? h('div', { class: 'small muted' }, c.cta_url) : null),
          h('dl', { class: 'kv' },
            h('dt', {}, 'Package'), h('dd', {}, L(c.package_name_en, c.package_name_km)),
            h('dt', {}, 'Dates'), h('dd', {}, `${date(c.start_date)} – ${date(c.end_date)}`),
            h('dt', {}, 'Price'), h('dd', {}, usd(c.price_usd)),
            h('dt', {}, 'Title (Khmer)'), h('dd', {}, c.title_km || '-'),
            h('dt', {}, 'Short text (English)'), h('dd', {}, c.body_en || '-'),
            h('dt', {}, 'Short text (Khmer)'), h('dd', {}, c.body_km || '-'),
            h('dt', {}, 'Promotional offer (English)'), h('dd', {}, c.offer_en || '-'),
            h('dt', {}, 'Keywords'), h('dd', {}, (c.keywords || []).join(', ') || '-'),
            c.review_note ? [h('dt', {}, 'Note'), h('dd', {}, c.review_note)] : null)),
        c.article_en ? h('div', { class: 'stack' }, h('h3', {}, 'Article (English)'), h('p', { style: 'white-space:pre-wrap' }, c.article_en), c.article_km ? [h('h3', {}, 'Article (Khmer)'), h('p', { style: 'white-space:pre-wrap' }, c.article_km)] : null) : null,
        c.daily.length ? dailyBars(c.daily, { height: 110 }) : null),
      actions: [
        h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Close'),
        ['scheduled', 'active', 'paused', 'awaiting_payment', 'payment_review'].includes(s) ? h('button', { class: 'btn', type: 'button', onclick: () => rescheduleDialog(api, c, () => after(m)) }, icon('calendar'), 'Reschedule') : null,
        !['expired', 'cancelled', 'rejected', 'draft'].includes(s) ? h('button', { class: 'btn danger', type: 'button', onclick: () => reasonDialog({ title: 'Cancel campaign', confirmLabel: 'Cancel campaign', fn: async (r) => { await api.post(`/admin/ads/campaigns/${id}/cancel`, { note: r }); toast('Cancelled', 'ok'); after(m); } }) }, 'Cancel campaign') : null,
        ['active', 'scheduled'].includes(s) ? h('button', { class: 'btn', type: 'button', onclick: call(m, 'pause', {}, 'Paused') }, 'Pause') : null,
        s === 'paused' ? h('button', { class: 'btn primary', type: 'button', onclick: call(m, 'resume', undefined, 'Resumed') }, 'Resume') : null,
        s === 'pending_review' ? h('button', { class: 'btn danger', type: 'button', onclick: () => reasonDialog({ title: 'Reject', fn: async (r) => { await api.post(`/admin/ads/campaigns/${id}/reject`, { reason: r }); toast('Rejected', 'ok'); after(m); } }) }, 'Reject') : null,
        s === 'pending_review' ? h('button', { class: 'btn primary', type: 'button', onclick: call(m, 'approve', {}, 'Approved') }, icon('check'), 'Approve') : null,
      ],
    });
  }
  await load();
  return h('div', { class: 'stack' }, h('div', { class: 'row' }, status, placement, q), box);
}

function rescheduleDialog(api, c, done) {
  const start = input({ type: 'date', value: String(c.start_date).slice(0, 10) });
  const errors = h('div', { 'aria-live': 'polite' });
  const m = modal({
    title: 'Reschedule', width: 440,
    body: h('div', { class: 'stack' }, h('p', { class: 'muted small' }, 'The campaign keeps its length. Placement capacity is checked for the new dates.'), field('Start date', start, { required: true }), errors),
    actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
      h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        m.setBusy(true);
        try { await api.post(`/admin/ads/campaigns/${c.id}/reschedule`, { startDate: start.value }); m.close(); toast('Saved', 'ok'); done(); } catch (e) { showErrors(errors, e); m.setBusy(false); }
      } }, 'Save')],
  });
}

/* ---------------- payments ---------------- */
export async function adPaymentsPage({ api, user }) {
  const state = { status: 'claimed', page: 1 };
  const box = h('div', { class: 'stack' });
  const status = select(STATUS_OPTIONS(['claimed', 'pending', 'verified', 'rejected', 'cancelled']), state.status, { 'aria-label': 'Status' });
  status.addEventListener('change', () => { state.status = status.value; state.page = 1; load(); });
  async function load() {
    const r = await api.get('/admin/ads/payments', { status: state.status || undefined, page: state.page, pageSize: 20 });
    box.replaceChildren(h('section', { class: 'card' }, table({
      empty: 'Nothing to show', rows: r.items, startIndex: (r.page - 1) * r.pageSize + 1, onRowClick: (p) => payModal(p),
      columns: [
        { label: 'Reference', render: (p) => h('code', {}, p.reference) },
        { label: 'Business', key: 'business_name' },
        { label: 'Campaign', key: 'campaign_title' },
        { label: 'Method', render: (p) => (p.method === 'khqr' ? 'KHQR' : 'Bank transfer') },
        { label: 'Amount', num: true, render: (p) => amountOf(p.currency, p.amount_local) },
        { label: 'Status', render: (p) => statusBadge(p.status) },
        { label: 'Date', render: (p) => dateTime(p.claimed_at || p.created_at) },
      ] }), pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (n) => { state.page = n; load(); } })));
  }
  function payModal(p) {
    const received = input({ type: 'number', step: p.currency === 'KHR' ? '1' : '0.01', min: 0, placeholder: p.currency === 'KHR' ? 'e.g. 82000' : 'e.g. 20.00' });
    const errors = h('div', { 'aria-live': 'polite' });
    const canDecide = p.status === 'claimed' && isAdmin(user);
    const m = modal({
      title: p.reference, width: 560,
      body: h('div', { class: 'stack' },
        h('dl', { class: 'kv' },
          h('dt', {}, 'Business'), h('dd', {}, `${p.business_name} · ${p.business_email}`),
          h('dt', {}, 'Campaign'), h('dd', {}, p.campaign_title),
          h('dt', {}, 'Method'), h('dd', {}, p.method === 'khqr' ? 'KHQR' : 'Bank transfer'),
          h('dt', {}, 'Amount to pay'), h('dd', {}, h('strong', {}, amountOf(p.currency, p.amount_local))),
          h('dt', {}, 'Bank transaction reference'), h('dd', {}, p.bank_txn_ref ? h('code', {}, p.bank_txn_ref) : '-'),
          h('dt', {}, 'Status'), h('dd', {}, statusBadge(p.status)),
          p.reject_reason ? [h('dt', {}, 'Reason'), h('dd', {}, p.reject_reason)] : null),
        p.proof_url ? h('img', { src: p.proof_url, alt: '', style: 'max-width:100%;border-radius:12px;border:1px solid var(--line)' }) : null,
        canDecide ? h('div', { class: 'stack' },
          h('div', { class: 'notice info' }, 'Open your bank statement, find the transfer with this reference, and type the amount that arrived. It must match.'),
          field('Amount received', received, { required: true }), errors) : (p.status === 'claimed' ? h('div', { class: 'notice' }, 'Only an administrator can verify payments.') : null)),
      actions: [
        h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Close'),
        canDecide ? h('button', { class: 'btn danger', type: 'button', onclick: () => reasonDialog({ title: 'Reject', fn: async (r) => { await api.post(`/admin/ads/payments/${p.id}/reject`, { reason: r }); toast('Rejected', 'ok'); m.close(); load(); } }) }, 'Reject') : null,
        canDecide ? h('button', { class: 'btn primary', type: 'button', onclick: async () => {
          if (!validate([{ input: received, label: 'Amount received', required: true }], errors)) return;
          m.setBusy(true);
          try { await api.post(`/admin/ads/payments/${p.id}/verify`, { receivedAmount: Number(received.value) }); toast('Payment verified', 'ok'); m.close(); load(); } catch (e) { showErrors(errors, e); m.setBusy(false); }
        } }, icon('check'), 'Confirm payment received') : null,
      ],
    });
  }
  await load();
  return h('div', { class: 'stack' }, h('div', { class: 'row' }, status), box);
}

/* ---------------- packages and payment settings ---------------- */
export async function adPackagesPage({ api, user, refresh }) {
  const [pk, settings] = await Promise.all([api.get('/admin/ads/packages'), api.get('/admin/ads/settings')]);
  const admin = isAdmin(user);

  function packageModal(p) {
    const f = {
      nameEn: input({ value: p?.name_en || '', maxlength: 80, required: true }), nameKm: input({ value: p?.name_km || '', maxlength: 80, required: true }),
      descEn: textarea({ maxlength: 400, rows: 2 }), descKm: textarea({ maxlength: 400, rows: 2 }),
      price: input({ type: 'number', step: '0.01', min: 0, value: p?.unit_price_usd ?? 10 }), days: input({ type: 'number', min: 1, max: 366, value: p?.days_per_unit ?? 7 }),
      min: input({ type: 'number', min: 1, max: 52, value: p?.min_units ?? 1 }), max: input({ type: 'number', min: 1, max: 52, value: p?.max_units ?? 12 }),
      cap: input({ type: 'number', min: 1, max: 200, value: p?.slot_capacity ?? 5 }), sort: input({ type: 'number', min: 0, max: 1000, value: p?.sort_order ?? 0 }),
    };
    f.descEn.value = p?.description_en || ''; f.descKm.value = p?.description_km || '';
    const active = h('input', { type: 'checkbox', checked: p ? p.is_active : true });
    const code = input({ maxlength: 40, placeholder: 'e.g. featured_two_weeks' });
    const placement = select(Object.entries(PLACEMENTS).map(([k, v]) => [k, v]), 'featured_destination');
    const unit = select([['week', 'week'], ['post', 'post'], ['month', 'month']], 'week');
    const errors = h('div', { 'aria-live': 'polite' });
    const m = modal({
      title: p ? L(p.name_en, p.name_km) : 'New package', width: 680,
      body: h('div', { class: 'stack' },
        h('div', { class: 'form-grid' },
          p ? null : field('Reference', code, { required: true, hint: 'Lower case letters, digits and underscores' }),
          p ? null : field('Package', placement), p ? null : field('Unit', unit),
          field('Name (English)', f.nameEn, { required: true }), field('Name (Khmer)', f.nameKm, { required: true }),
          field('Description (English)', f.descEn, { full: true }), field('Description (Khmer)', f.descKm, { full: true }),
          field('Price per unit (USD)', f.price), field('Days per unit', f.days),
          field('Minimum units', f.min), field('Maximum units', f.max), field('Slots per day', f.cap, { hint: 'How many campaigns of this package can run on the same day' }), field('Sort', f.sort),
          h('label', { class: 'check full' }, active, 'On sale')),
        errors),
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
        h('button', { class: 'btn primary', type: 'button', onclick: async () => {
          if (!validate([{ input: f.nameEn, label: 'Name (English)', required: true }, { input: f.nameKm, label: 'Name (Khmer)', required: true }], errors)) return;
          const details = { nameEn: f.nameEn.value.trim(), nameKm: f.nameKm.value.trim(), descriptionEn: f.descEn.value.trim(), descriptionKm: f.descKm.value.trim(), unitPriceUsd: Number(f.price.value), daysPerUnit: Number(f.days.value),
            minUnits: Number(f.min.value), maxUnits: Number(f.max.value), slotCapacity: Number(f.cap.value), active: active.checked, sortOrder: Number(f.sort.value) };
          m.setBusy(true);
          try {
            if (p) await api.put(`/admin/ads/packages/${p.id}`, details);
            else await api.post('/admin/ads/packages', { code: code.value.trim(), placement: placement.value, unit: unit.value, details });
            m.close(); toast('Saved', 'ok'); refresh();
          } catch (e) { showErrors(errors, e); m.setBusy(false); }
        } }, 'Save')],
    });
  }

  const qr = imagePicker({ current: settings.khqrImageUrl, label: 'Choose image', upload: (f) => api.upload(f) });
  const acc = input({ value: settings.accountName || '', maxlength: 100 });
  const bank = input({ value: settings.bankName || '', maxlength: 100 });
  const num_ = input({ value: settings.accountNumber || '', maxlength: 60 });
  const instr = textarea({ maxlength: 500, rows: 3 }); instr.value = settings.instructions || '';
  const rounding = select([['1', '1 ៛'], ['10', '10 ៛'], ['50', '50 ៛'], ['100', '100 ៛'], ['500', '500 ៛'], ['1000', '1,000 ៛']], settings.khrRounding || '100');
  const errors = h('div', { 'aria-live': 'polite' });

  return h('div', { class: 'stack' },
    h('section', { class: 'card' },
      h('div', { class: 'card-head' }, h('h2', {}, 'Packages & pricing'), admin ? h('button', { class: 'btn small primary', type: 'button', onclick: () => packageModal(null) }, icon('plus'), 'New') : null),
      table({ empty: 'Nothing to show', rows: pk.items, onRowClick: admin ? packageModal : null, columns: [
        { label: 'Package', render: (p) => h('div', {}, h('strong', {}, L(p.name_en, p.name_km)), h('div', { class: 'small muted' }, PLACEMENTS[p.placement])) },
        { label: 'Price', num: true, render: (p) => `${usd(p.unit_price_usd)} / ${p.unit}` },
        { label: 'Days per unit', num: true, render: (p) => num(p.days_per_unit) },
        { label: 'Slots per day', num: true, render: (p) => num(p.slot_capacity) },
        { label: 'On sale', render: (p) => statusBadge(p.is_active ? 'active' : 'paused') },
      ] }),
      admin ? null : h('p', { class: 'muted small card-pad' }, 'Only an administrator can change prices and packages.')),
    h('section', { class: 'card card-pad stack' },
      h('h2', {}, 'Payment settings'),
      h('p', { class: 'muted small' }, 'Businesses see these details when they pay for a campaign.'),
      h('div', { class: 'form-grid' },
        h('div', { class: 'full' }, h('label', { class: 'small muted' }, 'KHQR image'), qr.el),
        field('Account name', acc), field('Bank name', bank), field('Account number', num_), field('KHR rounding step', rounding),
        field('Transfer instructions', instr, { full: true })),
      errors,
      admin ? h('div', {}, h('button', { class: 'btn primary', type: 'button', onclick: async (ev) => {
        ev.target.disabled = true;
        try {
          await api.put('/admin/ads/settings', { khqrImageUrl: qr.get() || '', accountName: acc.value, bankName: bank.value, accountNumber: num_.value, transferInstructions: instr.value, khrRounding: rounding.value });
          showErrors(errors, null); toast('Saved', 'ok');
        } catch (e) { showErrors(errors, e); } finally { ev.target.disabled = false; }
      } }, 'Save')) : null));
}

/* ---------------- placement planner ---------------- */
export async function adPlacementsPage({ api }) {
  const r = await api.get('/admin/ads/placements', { days: 28 });
  return h('div', { class: 'stack' },
    h('p', { class: 'muted' }, 'Booked slots per day for each package. Capacity is enforced when a campaign is submitted, approved or rescheduled.'),
    h('section', { class: 'card card-pad heat' }, r.items.map((p) => h('div', { class: 'heat-row' },
      h('div', {}, h('strong', {}, L(p.nameEn, p.nameKm)), h('div', { class: 'small muted' }, `${p.capacity} / day`)),
      h('div', { class: 'heat-cells' }, p.days.map((d) => {
        const used = Number(d.used), ratio = used / p.capacity;
        return h('div', { class: `heat-cell ${used === 0 ? 'zero' : ratio >= 1 ? 'full' : ratio >= 0.6 ? 'mid' : ''}`, title: `${d.day}: ${used}/${p.capacity}` }, used ? String(used) : '');
      }))))));
}
