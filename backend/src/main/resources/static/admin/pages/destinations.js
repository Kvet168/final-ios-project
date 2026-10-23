import { checkbox, confirmDialog, debounce, field, h, icon, input, modal, money, pager, showErrors, table, textarea, toast } from '/dashboard/js/ui.js';

const numOrNull = (v) => (v === '' || v == null ? null : Number(v));

export function destinationsPage({ api, user }) {
  const state = { page: 1, q: '' };
  const box = h('div', { class: 'card' });
  const isAdmin = user.role === 'admin';

  async function load() {
    const r = await api.get('/destinations', { page: state.page, pageSize: 15, q: state.q, sort: 'name' });
    box.replaceChildren(table({ empty: 'No destinations', columns: [
      { label: 'Name', render: (d) => h('div', {}, h('strong', {}, d.name), h('div', { class: 'muted small' }, `${d.region ? `${d.region}, ` : ''}${d.country}`)) },
      { label: 'Daily budget', num: true, render: (d) => money(d.daily_budget_usd) }, { label: 'Hotels', num: true, render: (d) => d.accommodation_count }, { label: 'Places', num: true, render: (d) => d.place_count },
      { label: 'Featured', render: (d) => (d.is_featured ? h('span', { class: 'badge ok' }, 'featured') : '') },
      { label: '', render: (d) => h('div', { class: 'row' },
        h('button', { class: 'btn small', type: 'button', onclick: () => form(d.id) }, icon('edit'), 'Edit'),
        isAdmin ? h('button', { class: 'btn small danger', type: 'button', 'aria-label': `Delete ${d.name}`, onclick: async () => {
          if (await confirmDialog({ title: 'Delete destination', message: `Remove ${d.name} from the catalogue?`, confirmLabel: 'Delete', danger: true })) {
            try { await api.del(`/admin/destinations/${d.id}`); toast('Destination deleted', 'ok'); await load(); } catch (e) { toast(e.message, 'bad'); }
          }
        } }, icon('trash')) : null) }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } }));
  }

  async function form(id) {
    const editing = !!id;
    const v = editing ? await api.get(`/destinations/${id}`).catch((e) => { toast(e.message, 'bad'); return null; }) : {};
    if (!v) return;
    const name = input({ value: v.name || '', required: true, maxlength: 80 }), country = input({ value: v.country || '', required: true, maxlength: 60 }), region = input({ value: v.region || '', maxlength: 80 });
    const short = input({ value: v.short_description || '', maxlength: 300 });
    const long = textarea({ maxlength: 4000 }); long.value = v.long_description || '';
    const lat = input({ type: 'number', step: 'any', value: v.lat ?? '' }), lng = input({ type: 'number', step: 'any', value: v.lng ?? '' });
    const budget = input({ type: 'number', min: 0, step: '0.01', value: v.daily_budget_usd ?? '' }), cover = input({ type: 'url', value: v.cover_image || '', placeholder: 'https://...' });
    const tags = input({ value: (v.tags || []).join(', '), placeholder: 'temples, food, culture' });
    const featured = checkbox('Featured on the home screen', !!v.is_featured), intl = checkbox('International (outside Cambodia)', !!v.is_international);
    const errors = h('div', { 'aria-live': 'polite' });
    const m = modal({
      title: editing ? `Edit ${v.name}` : 'New destination', width: 720,
      body: h('div', { class: 'stack' }, h('div', { class: 'form-grid' }, field('Name', name), field('Country', country), field('Region', region), field('Daily budget (USD)', budget),
        field('Short description', short, { full: true, hint: '10-300 characters' }), field('Long description', long, { full: true, hint: '20-4000 characters' }),
        field('Latitude', lat), field('Longitude', lng), field('Cover image URL (optional)', cover, { full: true }), field('Tags (comma separated)', tags, { full: true }),
        h('div', { class: 'row full' }, featured.el, intl.el)), errors),
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        const body = { name: name.value.trim(), country: country.value.trim(), region: region.value.trim() || null, shortDescription: short.value.trim(), longDescription: long.value.trim(),
          lat: numOrNull(lat.value), lng: numOrNull(lng.value), dailyBudgetUsd: numOrNull(budget.value), coverImage: cover.value.trim() || null,
          tags: tags.value.split(',').map((t) => t.trim()).filter(Boolean), isFeatured: featured.input.checked, isInternational: intl.input.checked };
        // required columns are never cleared on edit: drop them when the field was left blank
        for (const k of ['name', 'country', 'shortDescription', 'longDescription', 'lat', 'lng', 'dailyBudgetUsd']) if (body[k] == null || body[k] === '') { if (editing) delete body[k]; }
        m.setBusy(true);
        try {
          if (editing) await api.patch(`/admin/destinations/${id}`, body); else await api.post('/admin/destinations', body);
          toast(editing ? 'Destination updated' : 'Destination created', 'ok'); m.close(); await load();
        } catch (e) { showErrors(errors, e); m.setBusy(false); }
      } }, editing ? 'Save changes' : 'Create destination')],
    });
  }

  const search = debounce((v) => { state.q = v; state.page = 1; load(); });
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' }, h('div', { class: 'row between' },
    h('input', { class: 'input', type: 'search', placeholder: 'Search destinations', 'aria-label': 'Search destinations', style: 'max-width:280px', oninput: (e) => search(e.target.value) }),
    h('button', { class: 'btn primary', type: 'button', onclick: () => form() }, icon('plus'), 'Add destination')), box);
}
