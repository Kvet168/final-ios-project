// Dashboard shell: login screen, sidebar, hash router. Each app (admin, partner) supplies its navigation and pages.
import { api, login, logout, onSessionExpired, session, ApiError } from './api.js';
import { clear, confirmDialog, field, h, icon, input, langSwitchButton, onLangChange, showErrors, skeleton, t, toast, validate } from './ui.js';
import { forcePasswordChange } from './account.js';

/**
 * @param {object} cfg
 * @param {string} cfg.name           e.g. "Admin console"
 * @param {string} cfg.roleLabel      shown under the logo
 * @param {string[]} cfg.allowedRoles roles that may sign in here
 * @param {{id:string,group?:string,label:string,icon:string,page:Function}[]} cfg.nav
 */
export function createDashboard(cfg) {
  const root = document.getElementById('app');
  document.title = `Travel ${t(cfg.name)}`;
  const theme = localStorage.getItem('wf.theme');
  if (theme) document.documentElement.dataset.theme = theme;

  onSessionExpired(() => { toast('Your session expired. Please sign in again.', 'bad'); showLogin(); });
  window.addEventListener('hashchange', () => { if (root.querySelector('.shell')) renderPage(); });
  onLangChange(() => {
    const u = session.user;
    if (u && session.access && cfg.allowedRoles.includes(u.role)) showShell(u);
    else showLogin();
  });

  async function handleSignOut() {
    const ok = await confirmDialog({
      title: 'Sign out of Travel?',
      message: `Are you sure you want to sign out of the ${cfg.name}? Any unsaved changes on this page will be lost.`,
      confirmLabel: 'Sign out',
      danger: true,
    });
    if (!ok) return;
    await logout();
    history.replaceState(null, '', location.pathname);
    toast(`Signed out of ${cfg.name}`, 'ok');
    showLogin();
  }

  /* ---------------- login ---------------- */
  function showLogin(message) {
    clear(root);
    const err = h('div', { 'aria-live': 'polite' });
    if (message) showErrors(err, { message });
    const isPartnerPortal = cfg.allowedRoles.includes('partner');
    const email = input({ type: 'email', autocomplete: 'username', required: true, placeholder: cfg.register ? 'you@yourbusiness.com' : isPartnerPortal ? 'partner@example.com' : 'staff@example.com' });
    const pw = input({ type: 'password', autocomplete: 'current-password', required: true, placeholder: 'Enter your password' });
    const submit = h('button', { class: 'btn primary', type: 'submit' }, 'Sign in');

    const form = h('form', {
      class: 'stack',
      novalidate: true,
      onsubmit: async (e) => {
        e.preventDefault();
        if (!validate([
          { input: email, label: 'Email', required: true, email: true },
          { input: pw, label: 'Password', required: true, minLen: 4 },
        ], err)) return;
        submit.disabled = true;
        submit.textContent = t('Signing in...');
        try {
          const u = await login(email.value.trim(), pw.value);
          if (!cfg.allowedRoles.includes(u.role)) {
            await logout();
            throw new ApiError(403, 'FORBIDDEN', `This account (${u.role}) cannot use the ${cfg.name}. Expected role: ${cfg.allowedRoles.join(' or ')}.`);
          }
          toast(`Welcome back, ${u.name}`, 'ok');
          showShell(u);
        } catch (ex) {
          showErrors(err, ex);
        } finally {
          submit.disabled = false;
          submit.textContent = t('Sign in');
        }
      },
    },
    field('Email', email, { required: true }),
    field('Password', pw, { required: true }),
    err,
    submit,
    cfg.register ? h('button', { class: 'btn small', type: 'button', style: 'margin-top:10px;width:100%', onclick: () => cfg.register((r) => {
      session.save(r);
      toast(`Welcome, ${r.user.name}`, 'ok');
      showShell(r.user);
    }) }, icon('plus'), cfg.registerLabel || 'Create a business account') : null);

    const hint = cfg.hint ? cfg.hint : isPartnerPortal
      ? 'Sign in with your partner account to manage properties, rooms and bookings.'
      : 'Sign in with your staff or administrator account.';
    root.append(h('main', { class: 'login' },
      h('div', { class: 'login-card' },
        h('div', { class: 'login-hero' },
          h('span', { class: 'login-blob blob-amber', 'aria-hidden': 'true' }),
          h('span', { class: 'login-blob blob-mint', 'aria-hidden': 'true' }),
          h('div', { class: 'row between', style: 'position:relative;z-index:2' },
            h('a', { class: 'brand-logo', href: location.pathname, 'aria-label': 'Travel' }, h('img', { src: '/dashboard/img/logo.png', alt: 'Travel', height: 30 })),
            langSwitchButton('login-lang-btn')),
          h('h1', {}, cfg.name),
          h('p', { class: 'login-sub' }, hint)),
        h('div', { class: 'login-sheet' }, form))));
    email.focus();
  }

  /* ---------------- shell ---------------- */
  let content, title, eyebrowEl, shell;

  function buildCategorizedNav() {
    const groups = [];
    const byGroup = new Map();
    for (const item of cfg.nav) {
      const gName = item.group || 'General';
      if (!byGroup.has(gName)) {
        const g = { name: gName, items: [] };
        byGroup.set(gName, g);
        groups.push(g);
      }
      byGroup.get(gName).items.push(item);
    }

    return h('nav', { class: 'nav', 'aria-label': 'Main' },
      groups.map((g) => h('div', { class: 'nav-group' },
        h('div', { class: 'nav-group-label' }, g.name),
        h('div', { class: 'nav-group-items' },
          g.items.map((n) => h('a', {
            href: `#/${n.id}`,
            'data-id': n.id,
            onclick: () => shell.classList.remove('open'),
          }, icon(n.icon), n.label))))));
  }

  function showShell(u) {
    clear(root);
    const nav = buildCategorizedNav();
    eyebrowEl = h('div', { class: 'eyebrow' }, `Travel · ${t(cfg.name)}`);
    title = h('h1', {});
    content = h('div', { class: 'content', id: 'content', tabindex: -1 });
    const initial = (u.name || u.email || 'W').trim().charAt(0).toUpperCase();
    shell = h('div', { class: 'shell' },
      h('aside', { class: 'sidebar' },
        h('a', { class: 'brand-logo', href: location.pathname, 'aria-label': 'Travel' }, h('img', { src: '/dashboard/img/logo.png', alt: 'Travel', height: 30 })),
        h('div', { class: 'role' }, cfg.roleLabel), nav,
        h('div', { class: 'sidebar-foot' },
          h('div', { class: 'user-card' },
            h('span', { class: 'avatar', 'aria-hidden': 'true' }, initial),
            h('div', { class: 'who' }, h('strong', {}, u.name), h('br'), h('span', { class: 'small' }, u.email))))),
      h('div', { class: 'main' },
        h('header', { class: 'topbar' },
          h('div', { class: 'row' },
            h('button', { class: 'btn small menu-btn', type: 'button', 'aria-label': 'Open menu', onclick: () => shell.classList.toggle('open') }, icon('menu')),
            h('div', {}, eyebrowEl, title)),
          h('div', { class: 'topbar-actions' },
            langSwitchButton('', { iconOnly: true }),
            h('button', { class: 'btn small icon-only', type: 'button', title: 'Light / dark theme', 'aria-label': 'Switch light or dark theme', onclick: toggleTheme }, icon('moon')),
            h('span', { class: 'role-pill' }, u.role),
            h('button', { class: 'btn small icon-only signout', type: 'button', title: 'Sign out', 'aria-label': 'Sign out', onclick: handleSignOut }, icon('out')))),
        content));
    root.append(shell);
    if (!location.hash) location.hash = `#/${cfg.nav[0].id}`;
    renderPage();
    if (u.mustChangePassword) forcePasswordChange((fresh) => { session.save({ accessToken: session.access, refreshToken: session.refresh, user: fresh }); renderPage(); });
  }

  function toggleTheme() {
    const dark = getComputedStyle(document.documentElement).colorScheme === 'dark';
    const next = dark ? 'light' : 'dark';
    document.documentElement.dataset.theme = next;
    localStorage.setItem('wf.theme', next);
  }

  /* ---------------- router ---------------- */
  let token = 0;
  async function renderPage() {
    const [id, ...params] = (location.hash.replace(/^#\//, '') || cfg.nav[0].id).split('/');
    const entry = cfg.nav.find((n) => n.id === id) || cfg.nav[0];
    shell.querySelectorAll('.nav a').forEach((a) => (a.dataset.id === entry.id ? a.setAttribute('aria-current', 'page') : a.removeAttribute('aria-current')));
    if (eyebrowEl) {
      eyebrowEl.textContent = entry.group
        ? `Travel · ${t(cfg.name)} · ${t(entry.group)}`
        : `Travel · ${t(cfg.name)}`;
    }
    title.textContent = t(entry.label);
    document.title = `${t(entry.label)} | Travel ${t(cfg.name)}`;
    const mine = ++token;
    clear(content).append(skeleton());
    try {
      const view = await entry.page({ api, user: session.user, params, toast, refresh: renderPage, signOut: handleSignOut, setTitle: (txt) => { title.textContent = t(txt); } });
      if (mine !== token) return;
      clear(content).append(view);
    } catch (e) {
      if (mine !== token) return;
      clear(content).append(h('div', { class: 'card empty', role: 'alert' }, h('strong', {}, 'Could not load this page'), h('span', {}, e.message),
        h('div', {}, h('button', { class: 'btn', type: 'button', onclick: renderPage }, icon('refresh'), 'Try again'))));
    }
  }

  /* ---------------- boot ---------------- */
  const user = session.user;
  if (user && session.access && cfg.allowedRoles.includes(user.role)) showShell(user); else { session.clear(); showLogin(); }
}
