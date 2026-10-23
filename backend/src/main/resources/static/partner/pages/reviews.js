import { dateTime, h, pager, table } from '/dashboard/js/ui.js';

export function reviewsPage({ api }) {
  const state = { page: 1 };
  const box = h('div', { class: 'card' });
  async function load() {
    const r = await api.get('/partner/reviews', { page: state.page, pageSize: 10 });
    box.replaceChildren(table({ empty: 'No guest reviews yet', columns: [
      { label: 'Rating', render: (v) => h('span', { class: 'stars' }, '★'.repeat(v.rating)) },
      { label: 'Review', render: (v) => h('div', {}, h('strong', {}, v.title), h('div', { class: 'muted small' }, v.body)) },
      { label: 'Hotel', render: (v) => v.accommodation_name }, { label: 'Guest', render: (v) => v.author }, { label: 'Date', render: (v) => dateTime(v.created_at) }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } }));
  }
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' }, h('p', { class: 'muted' }, 'Published reviews from guests who stayed at your hotels. Moderation is handled by WAYFARER staff.'), box);
}
