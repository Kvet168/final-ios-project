// Dashboard shell: login screen, sidebar, hash router. Each app (admin, partner) supplies its navigation and pages.
import { api, login, logout, onSessionExpired, session, ApiError } from './api.js';
import { clear, field, h, icon, input, showErrors, skeleton, toast } from './ui.js';
import { forcePasswordChange } from './account.js';

/**
 * @param {object} cfg
 * @param {string} cfg.name           e.g. "Admin console"
 * @param {string} cfg.roleLabel      shown under the logo
 * @param {string[]} cfg.allowedRoles roles that may sign in here
 * @param {{id:string,label:string,icon:string,page:Function}[]} cfg.nav
 */
export function createDashboard(cfg) {
  const root = document.getElementById('app');
  document.title = `WAYFARER ${cfg.name}`;
  const theme = localStorage.getItem('wf.theme');
  if (theme) document.documentElement.dataset.theme = theme;

  onSessionExpired(() => { toast('Your session expired. Please sign in again.', 'bad'); showLogin(); });
  window.addEventListener('hashchange', () => { if (root.querySelector('.shell')) renderPage(); });

  /* ---------------- login ---------------- */
  function showLogin(message) {
    clear(root);
    const err = h('div', { 'aria-live': 'polite' });
    if (message) showErrors(err, { message });
    const email = input({ type: 'email', autocomplete: 'username', required: true, placeholder: 'you@example.com' });
    const pw = input({ type: 'password', autocomplete: 'current-password', required: true });
    const submit = h('button', { class: 'btn primary', type: 'submit' }, 'Sign in');
    const form = h('form', { class: 'stack', novalidate: true,
      onsubmit: async (e) => {
        e.preventDefault();
        submit.disabled = true;
        try {
          const u = await login(email.value.trim(), pw.value);
          if (!cfg.allowedRoles.includes(u.role)) {
            await logout();
            throw new ApiError(403, 'FORBIDDEN', `This account (${u.role}) cannot use the ${cfg.name}.`);
          }
          showShell(u);
        } catch (ex) { showErrors(err, ex); } finally { submit.disabled = false; }
      } },
    field('Email', email), field('Password', pw), err, submit);
    root.append(h('main', { class: 'login' }, h('div', { class: 'login-card' },
      h('div', { class: 'brand' }, h('span', { class: 'brand-mark' }, icon('map')), 'WAYFARER'),
      h('div', {}, h('h1', {}, cfg.name), h('p', { class: 'muted' }, 'Sign in with your staff account.')), form)));
    email.focus();
  }

  /* ---------------- shell ---------------- */
  let content, title, shell;

  function showShell(u) {
    clear(root);
    const nav = h('nav', { class: 'nav', 'aria-label': 'Main' }, cfg.nav.map((n) => h('a', { href: `#/${n.id}`, 'data-id': n.id, onclick: () => shell.classList.remove('open') }, icon(n.icon), n.label)));
    title = h('h1', {});
    content = h('div', { class: 'content', id: 'content', tabindex: -1 });
    shell = h('div', { class: 'shell' },
      h('aside', { class: 'sidebar' },
        h('div', { class: 'brand' }, h('span', { class: 'brand-mark' }, icon('map')), 'WAYFARER'),
        h('div', { class: 'role' }, cfg.roleLabel), nav,
        h('div', { class: 'sidebar-foot' },
          h('div', { class: 'who' }, u.name, h('br'), h('span', { class: 'small' }, u.email)),
          h('button', { class: 'btn small', type: 'button', onclick: toggleTheme }, icon('moon'), 'Theme'),
          h('button', { class: 'btn small', type: 'button', onclick: async () => { await logout(); showLogin(); } }, icon('out'), 'Sign out'))),
      h('div', { class: 'main' },
        h('header', { class: 'topbar' }, h('div', { class: 'row' },
          h('button', { class: 'btn small menu-btn', type: 'button', 'aria-label': 'Open menu', onclick: () => shell.classList.toggle('open') }, icon('menu')), title)),
        content));
    root.append(shell);
    if (!location.hash) location.hash = `#/${cfg.nav[0].id}`;
    renderPage();
    // accounts created by an administrator must replace the temporary password before doing anything else
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
    title.textContent = entry.label;
    document.title = `${entry.label} | WAYFARER ${cfg.name}`;
    const mine = ++token;
    clear(content).append(skeleton());
    try {
      const view = await entry.page({ api, user: session.user, params, toast, refresh: renderPage, setTitle: (t) => { title.textContent = t; } });
      if (mine !== token) return;
      clear(content).append(view);
    } catch (e) {
      if (mine !== token) return;
      clear(content).append(h('div', { class: 'card empty', role: 'alert' }, h('strong', {}, 'Could not load this page'), h('span', {}, e.message),
        h('div', {}, h('button', { class: 'btn', type: 'button', onclick: renderPage }, 'Try again'))));
    }
  }

  /* ---------------- boot ---------------- */
  const user = session.user;
  if (user && session.access && cfg.allowedRoles.includes(user.role)) showShell(user); else { session.clear(); showLogin(); }
}
