// Change-password form, used as a page and as the forced step for accounts issued by an administrator.
import { session, api } from './api.js';
import { field, h, input, showErrors, toast } from './ui.js';

const RULE = /^(?=.*[A-Za-z])(?=.*\d).{10,128}$/;

function passwordForm(onDone, { forced = false } = {}) {
  const current = input({ type: 'password', autocomplete: 'current-password', required: true });
  const next = input({ type: 'password', autocomplete: 'new-password', required: true, minlength: 10 });
  const again = input({ type: 'password', autocomplete: 'new-password', required: true });
  const errors = h('div', { 'aria-live': 'polite' });
  const save = h('button', { class: 'btn primary', type: 'submit' }, 'Change password');
  const form = h('form', { class: 'stack', novalidate: true, onsubmit: async (e) => {
    e.preventDefault();
    if (!RULE.test(next.value)) return showErrors(errors, { message: 'Use 10 or more characters with letters and at least one number.' });
    if (next.value !== again.value) return showErrors(errors, { message: 'The two new passwords do not match.' });
    save.disabled = true;
    try {
      const r = await api.post('/auth/change-password', { currentPassword: current.value, newPassword: next.value });
      session.save(r);
      toast('Password changed', 'ok');
      onDone(r.user);
    } catch (ex) { showErrors(errors, ex); } finally { save.disabled = false; }
  } },
  forced ? h('div', { class: 'notice' }, 'Your account was created by an administrator with a temporary password. Choose your own password to continue.') : null,
  field(forced ? 'Temporary password' : 'Current password', current), field('New password', next, { hint: '10+ characters, with letters and a number' }), field('Repeat new password', again), errors, save);
  return form;
}

/** Blocks the dashboard until the temporary password has been replaced. */
export function forcePasswordChange(onDone) {
  const overlay = h('div', { class: 'overlay', role: 'dialog', 'aria-modal': 'true', 'aria-label': 'Choose a new password' },
    h('div', { class: 'modal', style: '--w:460px' }, h('div', { class: 'modal-head' }, h('h2', {}, 'Choose a new password')),
      h('div', { class: 'modal-body' }, passwordForm((u) => { overlay.remove(); onDone(u); }, { forced: true }))));
  document.body.append(overlay);
  overlay.querySelector('input')?.focus();
}

export function accountPage({ user }) {
  return h('div', { class: 'stack', style: 'max-width:520px' },
    h('section', { class: 'card card-pad stack' }, h('h2', {}, 'Your account'),
      h('dl', { class: 'kv' }, h('dt', {}, 'Name'), h('dd', {}, user.name), h('dt', {}, 'Email'), h('dd', {}, user.email), h('dt', {}, 'Role'), h('dd', {}, user.role))),
    h('section', { class: 'card card-pad stack' }, h('h2', {}, 'Change password'), passwordForm(() => {})));
}

