// Change-password form, used as a page and as the forced step for accounts issued by an administrator.
import { session, api } from './api.js';
import { badge, field, h, icon, input, showErrors, successDialog, validate } from './ui.js';

const RULE = /^(?=.*[A-Za-z])(?=.*\d).{10,128}$/;

function passwordForm(onDone, { forced = false } = {}) {
  const current = input({ type: 'password', autocomplete: 'current-password', required: true, placeholder: forced ? 'Enter temporary password' : 'Enter current password' });
  const next = input({ type: 'password', autocomplete: 'new-password', required: true, minlength: 10, placeholder: '10+ characters with letters & a number' });
  const again = input({ type: 'password', autocomplete: 'new-password', required: true, placeholder: 'Re-enter new password' });
  const errors = h('div', { 'aria-live': 'polite' });
  const save = h('button', { class: 'btn primary', type: 'submit' }, 'Change password');
  const form = h('form', {
    class: 'stack',
    novalidate: true,
    onsubmit: async (e) => {
      e.preventDefault();
      if (!validate([
        { input: current, label: forced ? 'Temporary password' : 'Current password', required: true },
        {
          input: next,
          label: 'New password',
          required: true,
          minLen: 10,
          maxLen: 128,
          pattern: RULE,
          patternMsg: 'Use 10 or more characters with letters and at least one number.',
          custom: (v) => (v === current.value ? 'New password must be different from your current password.' : null),
        },
        {
          input: again,
          label: 'Repeat new password',
          required: true,
          custom: (v) => (v !== next.value ? 'The two new passwords do not match.' : null),
        },
      ], errors)) return;

      save.disabled = true;
      try {
        const r = await api.post('/auth/change-password', { currentPassword: current.value, newPassword: next.value });
        session.save(r);
        current.value = '';
        next.value = '';
        again.value = '';
        onDone(r.user);
        await successDialog({
          title: 'Password updated',
          message: 'Your new password has been saved and is active immediately.',
          details: [['Account', r.user.email], ['Role', r.user.role]],
        });
      } catch (ex) {
        showErrors(errors, ex);
      } finally {
        save.disabled = false;
      }
    },
  },
  forced ? h('div', { class: 'notice' }, 'Your account was created by an administrator with a temporary password. Choose your own password to continue.') : null,
  field(forced ? 'Temporary password' : 'Current password', current, { required: true }),
  field('New password', next, { hint: '10+ characters, with letters and at least one number', required: true }),
  field('Repeat new password', again, { required: true }),
  errors,
  save);
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

export function accountPage({ user, signOut }) {
  return h('div', { class: 'stack', style: 'max-width:560px' },
    h('section', { class: 'card card-pad stack' },
      h('div', { class: 'row between' },
        h('h2', {}, 'Your account'),
        badge(user.role)),
      h('dl', { class: 'kv' },
        h('dt', {}, 'Name'), h('dd', {}, h('strong', {}, user.name)),
        h('dt', {}, 'Email'), h('dd', {}, user.email),
        h('dt', {}, 'Role'), h('dd', {}, user.role)),
      signOut ? h('div', { class: 'row', style: 'padding-top:6px' },
        h('button', { class: 'btn danger', type: 'button', onclick: signOut }, icon('out'), 'Sign out of this session')) : null),
    h('section', { class: 'card card-pad stack' }, h('h2', {}, 'Change password'), passwordForm(() => {})));
}
