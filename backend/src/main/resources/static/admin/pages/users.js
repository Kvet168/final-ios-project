import { confirmDialog, dateTime, debounce, h, pager, select, table, toast } from '/dashboard/js/ui.js';

const ROLES = ['customer', 'partner', 'staff', 'admin'];

export function usersPage({ api, user }) {
  const state = { page: 1, q: '', role: '' };
  const box = h('div', { class: 'card' });
  const isAdmin = user.role === 'admin';
  async function load() {
    const r = await api.get('/admin/users', { page: state.page, pageSize: 15, q: state.q, role: state.role });
    box.replaceChildren(table({ empty: 'No users match', columns: [
      { label: 'Name', render: (u) => h('div', {}, u.name, u.is_demo ? h('span', { class: 'badge neutral', style: 'margin-left:8px' }, 'demo') : null) },
      { label: 'Email', key: 'email' }, { label: 'Joined', render: (u) => dateTime(u.created_at) },
      { label: 'Role', render: (u) => (isAdmin && u.id !== user.id
        ? select(ROLES, u.role, { 'aria-label': `Role of ${u.name}`, onchange: async (e) => {
          const role = e.target.value;
          if (!(await confirmDialog({ title: 'Change role', message: `Make ${u.name} a ${role}? They are signed out everywhere and must sign in again.`, confirmLabel: 'Change role' }))) { e.target.value = u.role; return; }
          try { await api.patch(`/admin/users/${u.id}/role`, { role }); toast('Role updated', 'ok'); await load(); } catch (ex) { toast(ex.message, 'bad'); e.target.value = u.role; }
        } })
        : h('span', { class: 'badge neutral' }, u.role)) }], rows: r.items }),
    pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } }));
  }
  const search = debounce((v) => { state.q = v; state.page = 1; load(); });
  load().catch((e) => box.replaceChildren(h('div', { class: 'empty' }, e.message)));
  return h('div', { class: 'stack' }, h('div', { class: 'toolbar' },
    h('input', { class: 'input', type: 'search', placeholder: 'Search name or email', 'aria-label': 'Search users', oninput: (e) => search(e.target.value) }),
    select([['', 'All roles'], ...ROLES], '', { 'aria-label': 'Role', onchange: (e) => { state.role = e.target.value; state.page = 1; load(); } }),
    isAdmin ? null : h('span', { class: 'muted small' }, 'Only administrators can change roles.')), box);
}
