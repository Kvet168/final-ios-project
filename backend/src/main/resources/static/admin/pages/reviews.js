import { badge, dateTime, h, pager, select, table, toast } from '/dashboard/js/ui.js';

export function reviewsPage({ api }) {
  const state = { page: 1, status: '' };
  const box = h('div', { class: 'card' });
  async function load() {
    const r = await api.get('/admin/reviews', { page: state.page, pageSize: 12, status: state.status });
    const act = async (id, status) => { try { await api.patch(`/admin/reviews/${id}`, { status }); toast(status === 'hidden' ? 'Review hidden' : 'Review published', 'ok'); await load(); } catch (e) { toast(e.message, 'bad'); } };
    box.replaceChildren(table({ empty: 'No reviews', columns: [
      { label: 'Rating', render: (v) => h('span', { class: 'stars' }, '★'.repeat(v.rating)) },
      { label: 'Review', render: (v) => h('div', {}, h('strong', {}, v.title), h('div', { class: 'muted small' }, v.body)) },
      { label: 'Hotel', render: (v) => v.accommodation_name }, { label: 'Author', render: (v) => v.author }, { label: 'Date', render: (v) => dateTime(v.created_at) },
      { label: 'Status', render: (v) => badge(v.status) },
      { label: '', render: (v) => h('button', { class: 'btn small', type: 'button', onclick: () => act(v.id, v.status === 'published' ? 'hidden' : 'published') }, v.status === 'published' ? 'Hide' : 'Publish') }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } }));
  }
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' }, h('div', { class: 'toolbar' }, select([['', 'All reviews'], 'published', 'hidden'], '', { 'aria-label': 'Status', onchange: (e) => { state.status = e.target.value; state.page = 1; load(); } })), box);
}
