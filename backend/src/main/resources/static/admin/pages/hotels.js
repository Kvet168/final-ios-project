// Read-only catalogue of every property (hotels, resorts, bungalows, hostels ...). Prices, rooms and stock are managed by the partner who owns each property.
import { badge, date, debounce, h, modal, money, num, pager, select, stars, table, toast } from '/dashboard/js/ui.js';

const TYPES = [['', 'All types'], ['hotel', 'Hotels'], ['resort', 'Resorts'], ['bungalow', 'Bungalows'], ['hostel', 'Hostels'], ['guesthouse', 'Guesthouses'], ['boutique', 'Boutique'], ['villa', 'Villas'], ['apartment', 'Apartments']];

export async function hotelsPage({ api }) {
  const state = { page: 1, q: '', type: '', partnerId: '' };
  const partners = await api.get('/admin/partners', { pageSize: 100 }).catch(() => ({ items: [] }));
  const box = h('div', { class: 'card' });

  async function load() {
    const r = await api.get('/admin/hotels', { page: state.page, pageSize: 15, q: state.q, type: state.type, partnerId: state.partnerId });
    box.replaceChildren(table({ empty: 'No properties match', onRowClick: (a) => view(a), columns: [
      { label: 'Property', render: (a) => h('div', { class: 'row' }, a.cover_image ? h('img', { class: 'thumb', src: a.cover_image, alt: '' }) : null, h('div', {}, h('strong', {}, a.name), h('div', { class: 'muted small' }, a.destination_name))) },
      { label: 'Type', render: (a) => badge(a.type) }, { label: 'Stars', render: (a) => stars(a.stars) },
      { label: 'Partner', render: (a) => a.partner_name || h('span', { class: 'muted' }, 'catalogue (no owner)') },
      { label: 'Rooms', num: true, render: (a) => num(a.rooms) }, { label: 'From', num: true, render: (a) => money(a.from_price_usd) },
      { label: 'Rating', num: true, render: (a) => `${Number(a.rating_avg).toFixed(1)} (${a.review_count})` }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } }));
  }

  async function view(a) {
    const d = await api.get(`/accommodations/${a.id}`).catch((e) => { toast(e.message, 'bad'); return null; });
    if (!d) return;
    modal({ title: d.name, width: 760, body: h('div', { class: 'stack' },
      d.cover_image ? h('img', { class: 'hotel-cover', src: d.cover_image, alt: '' }) : null,
      h('div', { class: 'notice info' }, 'Read-only view. Only the owning partner can change rooms, prices and stock.'),
      h('dl', { class: 'kv' }, h('dt', {}, 'Type'), h('dd', {}, d.type), h('dt', {}, 'Where'), h('dd', {}, `${d.address}, ${d.destination_name}`), h('dt', {}, 'Partner'), h('dd', {}, a.partner_name || 'none'),
        h('dt', {}, 'Cancellation'), h('dd', {}, d.cancellation_policy), h('dt', {}, 'Listed'), h('dd', {}, date(d.created_at))),
      h('p', {}, d.description),
      h('div', {}, h('h3', {}, 'Rooms'), table({ empty: 'No rooms', columns: [{ label: 'Room', render: (r) => h('div', { class: 'row' }, r.cover_image ? h('img', { class: 'thumb', src: r.cover_image, alt: '' }) : null, r.name) },
        { label: 'Sleeps', render: (r) => `${r.max_adults} adults${r.max_children ? ` + ${r.max_children} children` : ''}` }, { label: 'Units', num: true, key: 'total_units' }, { label: 'Price / night', num: true, render: (r) => money(r.base_price_usd) }], rows: d.room_types })),
      h('div', {}, h('h3', {}, `Photos (${(d.images || []).length})`), h('div', { class: 'gallery' }, (d.images || []).map((i) => h('figure', {}, h('img', { src: i.url, alt: '' })))))) });
  }

  const search = debounce((v) => { state.q = v; state.page = 1; load(); });
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' }, h('div', { class: 'toolbar' },
    h('input', { class: 'input', type: 'search', placeholder: 'Search property, destination or partner', 'aria-label': 'Search properties', oninput: (e) => search(e.target.value) }),
    select(TYPES, '', { 'aria-label': 'Type', onchange: (e) => { state.type = e.target.value; state.page = 1; load(); } }),
    select([['', 'All partners'], ...partners.items.map((p) => [p.id, p.name])], '', { 'aria-label': 'Partner', onchange: (e) => { state.partnerId = e.target.value; state.page = 1; load(); } })), box);
}
