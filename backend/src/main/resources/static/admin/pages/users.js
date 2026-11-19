import {
  badge,
  confirmDialog,
  copyButton,
  dateTime,
  debounce,
  field,
  h,
  icon,
  input,
  modal,
  num,
  pager,
  select,
  showErrors,
  successDialog,
  table,
  toast,
  validate,
} from '/dashboard/js/ui.js';
import { createPartnerModal, partnerColumns, partnerDetailModal } from './partners.js';

const ROLES = ['customer', 'partner', 'staff', 'admin'];

const ROLE_META = {
  admin: {
    badge: 'ADMIN',
    title: 'Administrators',
    singular: 'administrator',
    createLabel: 'Create administrator account',
    modalTitle: 'Create administrator account',
    modalDesc: 'Creates a full-access administrator login for the Travel Admin Console.',
    emailLabel: 'Administrator email (login)',
    namePlaceholder: 'e.g. Sokha Chan',
    emailPlaceholder: 'admin.name@wayfarer.com',
    portalLabel: 'Admin console sign-in page',
    portalPath: '/admin',
    subtitle: 'Full platform access, role management, destination & partner provisioning',
    color: '#E6485C',
    icon: 'compass',
  },
  staff: {
    badge: 'STAFF',
    title: 'Operations Staff',
    singular: 'staff',
    createLabel: 'Create staff account',
    modalTitle: 'Create staff account',
    modalDesc: 'Creates an operations staff login for managing bookings, payments, destinations and reviews in the Admin Console.',
    emailLabel: 'Staff email (login)',
    namePlaceholder: 'e.g. Dara Support',
    emailPlaceholder: 'staff.name@wayfarer.com',
    portalLabel: 'Staff console sign-in page',
    portalPath: '/admin',
    subtitle: 'Booking management, review moderation & destination catalog updates',
    color: '#6347F9',
    icon: 'users',
  },
  partner: {
    badge: 'PARTNERS',
    title: 'Hotel Partners',
    singular: 'partner',
    createLabel: 'Create partner account',
    subtitle: 'Partner businesses: owner login, properties, rooms, bookings and QR payment setup. Click a row for details.',
    color: '#F59E0B',
    icon: 'bed',
  },
  customer: {
    badge: 'TRAVELERS',
    title: 'Customers & Travelers',
    singular: 'customer',
    createLabel: 'Create customer account',
    modalTitle: 'Create customer account',
    modalDesc: 'Creates a traveler account for the Travel mobile app.',
    emailLabel: 'Customer email (login)',
    namePlaceholder: 'e.g. Sophea Sok',
    emailPlaceholder: 'traveler@example.com',
    portalLabel: 'Platform / Mobile app login',
    portalPath: null,
    subtitle: 'Mobile app travelers booking stays, saving wishlists & planning trips',
    color: '#10B981',
    icon: 'ticket',
  },
};

function showUserCredentials({ role, title, name, email, password, notice }) {
  const meta = ROLE_META[role] || ROLE_META.customer;
  const portalUrl = meta.portalPath ? `${location.origin}${meta.portalPath}` : null;
  successDialog({
    title,
    message: `Account credentials for the ${meta.singular} are ready.`,
    details: [
      ['Account type', meta.title],
      ['Full name', name],
    ],
    buttonLabel: 'Done',
    extra: h('div', { class: 'stack', style: 'text-align:left;width:100%' },
      h('div', { class: 'notice' }, notice),
      portalUrl
        ? h('div', { class: 'stack', style: 'gap:6px' },
          h('div', { class: 'small muted' }, meta.portalLabel),
          h('div', { class: 'row' }, h('span', { class: 'secret grow' }, portalUrl), copyButton(portalUrl)))
        : null,
      h('div', { class: 'stack', style: 'gap:6px' },
        h('div', { class: 'small muted' }, meta.emailLabel || 'Login email'),
        h('div', { class: 'row' }, h('span', { class: 'secret grow' }, email), copyButton(email))),
      h('div', { class: 'stack', style: 'gap:6px' },
        h('div', { class: 'small muted' }, 'Password'),
        h('div', { class: 'row' }, h('span', { class: 'secret grow' }, password), copyButton(password)))),
  });
}

/** Role-specific creation modal for 'admin', 'staff', or 'customer' accounts. */
function createRoleAccountModal({ api, role, onCreated }) {
  const meta = ROLE_META[role] || ROLE_META.customer;
  const name = input({ required: true, maxlength: 80, placeholder: meta.namePlaceholder });
  const email = input({ type: 'email', required: true, maxlength: 160, placeholder: meta.emailPlaceholder });
  const phone = input({ maxlength: 30, placeholder: 'Optional, e.g. +855 12 345 678' });
  const pw = input({ type: 'password', required: true, minlength: 8, maxlength: 100, placeholder: 'Min 8 characters (letters & numbers)' });
  const errors = h('div', { 'aria-live': 'polite' });

  const m = modal({
    title: meta.modalTitle,
    width: 540,
    body: h('div', { class: 'stack' },
      h('div', { class: 'row', style: 'gap:8px' },
        h('span', { class: 'cat-hub-badge', style: `background:${meta.color}18;color:${meta.color}` }, meta.badge),
        h('span', { class: 'muted small' }, meta.title)),
      h('p', { class: 'muted small' }, meta.modalDesc),
      h('div', { class: 'form-grid' },
        field('Full name', name, { required: true }),
        field('Phone', phone),
        field(meta.emailLabel, email, { full: true, required: true }),
        field('Password', pw, { full: true, required: true })),
      errors),
    actions: [
      h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'),
      h('button', {
        class: 'btn primary',
        type: 'button',
        onclick: async () => {
          if (!validate([
            { input: name, label: 'Full name', required: true, minLen: 2, maxLen: 80 },
            { input: phone, label: 'Phone', maxLen: 30 },
            { input: email, label: meta.emailLabel, required: true, email: true, maxLen: 160 },
            { input: pw, label: 'Password', required: true, minLen: 8, maxLen: 100 },
          ], errors)) return;
          m.setBusy(true);
          try {
            const r = await api.post('/admin/users', {
              name: name.value.trim(),
              email: email.value.trim(),
              phone: phone.value.trim() || null,
              role,
              password: pw.value,
            });
            m.close();
            await onCreated?.();
            showUserCredentials({
              role,
              title: `${meta.singular.charAt(0).toUpperCase() + meta.singular.slice(1)} account created`,
              name: r.name,
              email: r.email,
              password: r.temporaryPassword || pw.value,
              notice: r.notice || 'Account created with the password you set.',
            });
          } catch (e) {
            showErrors(errors, e);
            m.setBusy(false);
          }
        },
      }, meta.createLabel),
    ],
  });
}

export function usersPage({ api, user }) {
  // mode: 'grouped' (separated into 4 distinct category cards) or a specific role ('admin'|'staff'|'partner'|'customer')
  const state = { page: 1, q: '', mode: 'grouped' };
  const container = h('div', { class: 'stack' });
  const tabsWrap = h('div', { class: 'cat-tabs-grid' });
  const toolbarActionSlot = h('div', { class: 'row', style: 'gap:8px;flex-wrap:wrap' });
  const isAdmin = user.role === 'admin';

  const openCreateForRole = (role) => {
    if (role === 'partner') {
      createPartnerModal({ api, onCreated: () => load() });
    } else {
      createRoleAccountModal({ api, role, onCreated: () => load() });
    }
  };
  const openPartner = (p) => partnerDetailModal({ api, id: p.id, isAdmin, onChanged: () => load() });

  function createButtonForRole(role, small = false) {
    // Customers sign up in the app, so admins do not need a button for them.
    if (!isAdmin || role === 'customer') return null;
    const meta = ROLE_META[role] || ROLE_META.customer;
    return h('button', {
      class: `btn ${small ? 'small ' : ''}primary`.trim(),
      type: 'button',
      onclick: () => openCreateForRole(role),
    }, icon('plus'), meta.createLabel);
  }

  function renderToolbarAction() {
    if (!isAdmin) {
      toolbarActionSlot.replaceChildren(
        h('span', { class: 'muted small' }, 'Only administrators can create accounts or change roles.'));
      return;
    }
    // Each category card has its own "Create ..." button, so the toolbar stays empty to avoid repeating them.
    toolbarActionSlot.replaceChildren();
  }

  // Soft delete on the server: personal data is erased and sign-in stops; bookings stay for records.
  function deleteButton(u) {
    return h('button', {
      class: 'btn small danger icon-only',
      type: 'button',
      title: 'Delete account',
      'aria-label': `Delete account of ${u.name}`,
      onclick: async (ev) => {
        ev.stopPropagation();
        const ok = await confirmDialog({
          title: 'Delete account',
          message: `Delete ${u.name} (${u.email})? Their personal details are erased and they can no longer sign in. Past bookings are kept for records. This cannot be undone.`,
          confirmLabel: 'Delete account',
          danger: true,
        });
        if (!ok) return;
        try {
          await api.del(`/admin/users/${u.id}`);
          await load();
          toast(`${u.name} was deleted`, 'ok');
        } catch (ex) {
          toast(ex.message, 'bad');
        }
      },
    }, icon('trash'));
  }

  function userColumns() {
    const cols = [
      {
        label: 'Name',
        sortValue: (u) => u.name || '',
        render: (u) => {
          const initial = (u.name || u.email || '?').trim().charAt(0).toUpperCase();
          const meta = ROLE_META[u.role] || ROLE_META.customer;
          return h('div', { class: 'row', style: 'gap:10px' },
            h('span', {
              class: 'user-row-avatar',
              style: `background:${meta.color}18;color:${meta.color};border:1px solid ${meta.color}35`,
            }, initial),
            h('div', {},
              h('strong', {}, u.name || '-'),
              u.is_demo ? h('span', { class: 'badge neutral', style: 'margin-left:8px' }, 'demo') : null,
              u.phone ? h('div', { class: 'muted small' }, u.phone) : null));
        },
      },
      { label: 'Email', key: 'email' },
      {
        label: 'Account',
        sortValue: (u) => (u.must_change_password ? 0 : 1),
        render: (u) => (u.must_change_password
          ? h('span', { class: 'badge warn' }, 'never signed in')
          : h('span', { class: 'badge ok' }, 'active')),
      },
      {
        label: 'Joined',
        sortValue: (u) => u.created_at || '',
        render: (u) => dateTime(u.created_at),
      },
      {
        label: 'Role',
        sortValue: (u) => u.role || '',
        render: (u) => (isAdmin && u.id !== user.id
          ? select(ROLES, u.role, {
            'aria-label': `Role of ${u.name}`,
            onchange: async (e) => {
              const nextRole = e.target.value;
              if (nextRole === u.role) return;
              const ok = await confirmDialog({
                title: 'Change user role',
                message: `Move ${u.name} (${u.email}) to the "${nextRole}" category? Their active sessions will be signed out so the new permissions take effect.`,
                confirmLabel: 'Change role',
              });
              if (!ok) {
                e.target.value = u.role;
                return;
              }
              try {
                await api.patch(`/admin/users/${u.id}/role`, { role: nextRole });
                await load();
                await successDialog({
                  title: 'User role updated',
                  message: `${u.name} is now in the ${ROLE_META[nextRole]?.title || nextRole} category.`,
                  details: [
                    ['User', u.name],
                    ['Email', u.email],
                    ['New category', nextRole.toUpperCase()],
                  ],
                });
              } catch (ex) {
                toast(ex.message, 'bad');
                e.target.value = u.role;
              }
            },
          })
          : badge(u.role)),
      },
    ];

    if (isAdmin) {
      cols.push({
        label: 'Action',
        render: (u) => (u.id === user.id
          ? h('span', { class: 'muted small' }, 'You')
          : h('div', { class: 'row', style: 'gap:6px;flex-wrap:nowrap' }, h('button', {
            class: 'btn small icon-only',
            type: 'button',
            title: 'Reset password',
            'aria-label': `Reset password of ${u.name}`,
            onclick: async (ev) => {
              ev.stopPropagation();
              const ok = await confirmDialog({
                title: 'Reset password',
                message: `Issue a new one-time temporary password for ${u.name} (${u.email})? They will be signed out everywhere and must choose a new password on next sign-in.`,
                confirmLabel: 'Reset password',
                danger: true,
              });
              if (!ok) return;
              try {
                const r = await api.post(`/admin/users/${u.id}/reset-password`);
                await load();
                showUserCredentials({
                  role: u.role,
                  title: 'Temporary password issued',
                  name: r.name,
                  email: r.email,
                  password: r.temporaryPassword,
                  notice: r.notice,
                });
              } catch (ex) {
                toast(ex.message, 'bad');
              }
            },
          }, icon('key')), deleteButton(u))),
      });
    }

    return cols;
  }

  function renderTabs(countsByRole, totalAll) {
    const tabs = [
      { id: 'grouped', label: 'All Categories (Grouped)', count: totalAll, color: '#E6485C', icon: 'chart' },
      { id: 'admin', label: 'Administrators', count: countsByRole.admin || 0, color: ROLE_META.admin.color, icon: ROLE_META.admin.icon },
      { id: 'staff', label: 'Staff', count: countsByRole.staff || 0, color: ROLE_META.staff.color, icon: ROLE_META.staff.icon },
      { id: 'partner', label: 'Hotel Partners', count: countsByRole.partner || 0, color: ROLE_META.partner.color, icon: ROLE_META.partner.icon },
      { id: 'customer', label: 'Customers', count: countsByRole.customer || 0, color: ROLE_META.customer.color, icon: ROLE_META.customer.icon },
    ];

    tabsWrap.replaceChildren(...tabs.map((tb) => {
      const active = state.mode === tb.id;
      return h('button', {
        class: `card cat-tab-btn ${active ? 'active' : ''}`.trim(),
        type: 'button',
        style: `--cat-color:${tb.color}`,
        onclick: () => {
          state.mode = tb.id;
          state.page = 1;
          renderToolbarAction();
          load();
        },
      },
      h('span', { class: 'cat-tab-icon', style: `background:${tb.color}18;color:${tb.color}` }, icon(tb.icon)),
      h('div', { class: 'cat-tab-copy' },
        h('span', { class: 'cat-tab-label' }, tb.label),
        h('strong', { class: 'cat-tab-count' }, num(tb.count))));
    }));
  }

  const sectionHead = ({ badgeText, title, subtitle, color, count, countLabel, action }) => h('div', { class: 'card-head' },
    h('div', { class: 'row', style: 'gap:10px' },
      h('span', { class: 'cat-hub-badge', style: `background:${color}18;color:${color}` }, badgeText),
      h('div', {},
        h('h2', {}, title),
        h('p', { class: 'muted small' }, subtitle))),
    h('div', { class: 'row' },
      h('span', { class: 'badge neutral' }, `${num(count)} ${countLabel}`),
      action));

  async function countRoles() {
    const allRes = await api.get('/admin/users', { page: 1, pageSize: 100, q: state.q });
    const items = allRes.items || [];
    const countsByRole = { admin: 0, staff: 0, partner: 0, customer: 0 };
    for (const u of items) countsByRole[u.role] = (countsByRole[u.role] || 0) + 1;
    return { items, countsByRole };
  }

  async function load() {
    renderToolbarAction();

    if (state.mode === 'grouped') {
      const [{ items, countsByRole }, partnersRes] = await Promise.all([
        countRoles(),
        api.get('/admin/partners', { page: 1, pageSize: 100, q: state.q }),
      ]);
      renderTabs(countsByRole, items.length);
      const admins = items.filter((u) => u.role === 'admin');
      const staff = items.filter((u) => u.role === 'staff');
      const customers = items.filter((u) => u.role === 'customer');
      const partners = partnersRes.items || [];

      container.replaceChildren(
        h('section', { class: 'card anim-card', style: '--delay:0ms' },
          sectionHead({
            badgeText: ROLE_META.admin.badge,
            title: ROLE_META.admin.title,
            subtitle: ROLE_META.admin.subtitle,
            color: ROLE_META.admin.color,
            count: admins.length,
            countLabel: 'accounts',
            action: createButtonForRole('admin', true),
          }),
          table({ empty: 'No administrators match your search', columns: userColumns(), rows: admins })),
        h('section', { class: 'card anim-card', style: '--delay:60ms' },
          sectionHead({
            badgeText: ROLE_META.staff.badge,
            title: ROLE_META.staff.title,
            subtitle: ROLE_META.staff.subtitle,
            color: ROLE_META.staff.color,
            count: staff.length,
            countLabel: 'accounts',
            action: createButtonForRole('staff', true),
          }),
          table({ empty: 'No operations staff match your search', columns: userColumns(), rows: staff })),
        h('section', { class: 'card anim-card', style: '--delay:120ms' },
          sectionHead({
            badgeText: ROLE_META.partner.badge,
            title: ROLE_META.partner.title,
            subtitle: ROLE_META.partner.subtitle,
            color: ROLE_META.partner.color,
            count: partners.length,
            countLabel: 'businesses',
            action: createButtonForRole('partner', true),
          }),
          table({ empty: 'No partners yet. Create the first partner account.', onRowClick: openPartner, columns: partnerColumns(), rows: partners })),
        h('section', { class: 'card anim-card', style: '--delay:180ms' },
          sectionHead({
            badgeText: ROLE_META.customer.badge,
            title: ROLE_META.customer.title,
            subtitle: ROLE_META.customer.subtitle,
            color: ROLE_META.customer.color,
            count: customers.length,
            countLabel: 'accounts',
            action: createButtonForRole('customer', true),
          }),
          table({ empty: 'No customers match your search', columns: userColumns(), rows: customers })));
      return;
    }

    const meta = ROLE_META[state.mode] || ROLE_META.customer;

    if (state.mode === 'partner') {
      // Partner category shows the partner businesses (owner login + properties) with server pagination
      const [{ items, countsByRole }, r] = await Promise.all([
        countRoles(),
        api.get('/admin/partners', { page: state.page, pageSize: 15, q: state.q }),
      ]);
      renderTabs(countsByRole, items.length);
      container.replaceChildren(
        h('section', { class: 'card anim-card' },
          sectionHead({
            badgeText: meta.badge,
            title: meta.title,
            subtitle: meta.subtitle,
            color: meta.color,
            count: r.total,
            countLabel: 'businesses',
            action: createButtonForRole('partner', true),
          }),
          table({ empty: 'No partners yet. Create the first partner account.', onRowClick: openPartner, columns: partnerColumns(), rows: r.items || [] }),
          pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } })));
      return;
    }

    // Filtered single category mode ('admin', 'staff', or 'customer') with server pagination
    const [{ items, countsByRole }, r] = await Promise.all([
      countRoles(),
      api.get('/admin/users', { page: state.page, pageSize: 15, q: state.q, role: state.mode }),
    ]);
    renderTabs(countsByRole, items.length);
    container.replaceChildren(
      h('section', { class: 'card anim-card' },
        sectionHead({
          badgeText: meta.badge,
          title: meta.title,
          subtitle: meta.subtitle,
          color: meta.color,
          count: r.total,
          countLabel: 'total',
          action: createButtonForRole(state.mode, true),
        }),
        table({ empty: `No ${meta.title.toLowerCase()} match`, columns: userColumns(), rows: r.items || [] }),
        pager({ page: r.page, pageSize: r.pageSize, total: r.total, onChange: (p) => { state.page = p; load(); } })));
  }

  const search = debounce((v) => { state.q = v; state.page = 1; load(); });
  renderToolbarAction();
  load().catch((e) => container.replaceChildren(h('div', { class: 'card empty' }, e.message)));

  return h('div', { class: 'stack' },
    h('div', { class: 'toolbar row between' },
      h('div', { class: 'row' },
        h('input', {
          class: 'input',
          type: 'search',
          placeholder: 'Search name, email or business...',
          'aria-label': 'Search users',
          style: 'min-width:280px',
          oninput: (e) => search(e.target.value),
        }),
        h('button', { class: 'btn', type: 'button', onclick: () => load() }, icon('refresh'), 'Refresh')),
      toolbarActionSlot),
    tabsWrap,
    container);
}
