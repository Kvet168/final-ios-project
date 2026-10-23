// Small DOM toolkit. Elements are built with createElement/textContent only (never innerHTML), so data from the API cannot inject markup.

const SVG_NS = 'http://www.w3.org/2000/svg';

export function h(tag, props, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props || {})) {
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2).toLowerCase(), v);
    else if (k === 'value') el.value = v;
    else if (k === 'checked' || k === 'disabled' || k === 'selected' || k === 'required' || k === 'hidden') el[k] = !!v;
    else el.setAttribute(k, v === true ? '' : String(v));
  }
  append(el, children);
  return el;
}

export function append(el, children) {
  for (const c of children.flat(Infinity)) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}

export const clear = (el) => { while (el.firstChild) el.removeChild(el.firstChild); return el; };

const ICONS = {
  home: 'M3 11l9-8 9 8v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z',
  users: 'M16 11a4 4 0 10-8 0 4 4 0 008 0zM4 21a8 8 0 0116 0',
  ticket: 'M3 8a2 2 0 002-2h14a2 2 0 002 2v2a2 2 0 000 4v2a2 2 0 00-2 2H5a2 2 0 00-2-2v-2a2 2 0 000-4z',
  card: 'M3 6h18v12H3zM3 10h18',
  star: 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z',
  map: 'M9 4L3 6v14l6-2 6 2 6-2V4l-6 2zM9 4v14M15 6v14',
  bed: 'M3 18V6M3 14h18v4M21 14v-3a3 3 0 00-3-3h-7v6M7 11h.01',
  log: 'M6 3h9l4 4v14H6zM9 12h7M9 16h7M9 8h3',
  bot: 'M5 9h14v10H5zM12 5v4M9 14h.01M15 14h.01',
  chart: 'M4 20V10M10 20V4M16 20v-8M22 20H2',
  out: 'M15 4h4v16h-4M10 8l-4 4 4 4M6 12h10',
  plus: 'M12 5v14M5 12h14',
  menu: 'M4 7h16M4 12h16M4 17h16',
  x: 'M6 6l12 12M18 6L6 18',
  edit: 'M4 20h4L19 9l-4-4L4 16zM13 7l4 4',
  trash: 'M5 7h14M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3',
  moon: 'M20 14A8 8 0 019.5 3.5 8 8 0 1020 14z',
  calendar: 'M4 6h16v14H4zM4 10h16M8 3v4M16 3v4',
};

export function icon(name) {
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.setAttribute('fill', 'none');
  svg.setAttribute('stroke', 'currentColor');
  svg.setAttribute('stroke-width', '1.8');
  svg.setAttribute('stroke-linecap', 'round');
  svg.setAttribute('stroke-linejoin', 'round');
  svg.setAttribute('aria-hidden', 'true');
  const p = document.createElementNS(SVG_NS, 'path');
  p.setAttribute('d', ICONS[name] || ICONS.home);
  svg.append(p);
  return svg;
}

/* ---------- formatting ---------- */
export const money = (v) => (v == null ? '-' : new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(v)));
export const num = (v) => (v == null ? '-' : new Intl.NumberFormat('en-US').format(Number(v)));
export const date = (v) => (v ? new Date(`${String(v).slice(0, 10)}T00:00:00`).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' }) : '-');
export const dateTime = (v) => (v ? new Date(v).toLocaleString(undefined, { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '-');
export const todayIso = () => new Date().toISOString().slice(0, 10);

const STATUS_TONE = {
  CONFIRMED: 'ok', COMPLETED: 'ok', SUCCESS: 'ok', published: 'ok', REFUNDED: 'info', CHECKED_IN: 'info',
  PENDING_CONFIRMATION: 'warn', PENDING: 'warn', REFUND_PENDING: 'warn', CANCELLED: 'bad', EXPIRED: 'neutral', FAILED: 'bad', hidden: 'neutral',
};
export const badge = (status) => h('span', { class: `badge ${STATUS_TONE[status] || 'neutral'}` }, String(status ?? '-').replaceAll('_', ' ').toLowerCase());
export const stars = (n) => h('span', { class: 'stars', 'aria-label': `${n} stars` }, '★'.repeat(Number(n) || 0));

/* ---------- toasts ---------- */
let toastBox;
export function toast(message, kind = '') {
  if (!toastBox) { toastBox = h('div', { class: 'toasts', role: 'status', 'aria-live': 'polite' }); document.body.append(toastBox); }
  const t = h('div', { class: `toast ${kind}` }, message);
  toastBox.append(t);
  setTimeout(() => t.remove(), kind === 'bad' ? 6000 : 3200);
}

/* ---------- modal ---------- */
/** Opens a dialog. `body` is a Node; `actions` are buttons. Returns { close, setBusy }. */
export function modal({ title, body, actions = [], width = 640, onClose }) {
  const previous = document.activeElement;
  const close = () => { overlay.remove(); document.removeEventListener('keydown', onKey); previous?.focus?.(); onClose?.(); };
  const onKey = (e) => { if (e.key === 'Escape') close(); };
  const overlay = h('div', { class: 'overlay', onclick: (e) => { if (e.target === overlay) close(); } },
    h('div', { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-label': title, style: `--w:${width}px` },
      h('div', { class: 'modal-head' }, h('h2', {}, title), h('button', { class: 'btn small', type: 'button', 'aria-label': 'Close', onclick: close }, icon('x'))),
      h('div', { class: 'modal-body' }, body),
      actions.length ? h('div', { class: 'modal-foot' }, actions) : null));
  document.body.append(overlay);
  document.addEventListener('keydown', onKey);
  overlay.querySelector('input, select, textarea, button.primary')?.focus();
  const setBusy = (busy) => overlay.querySelectorAll('.modal-foot button').forEach((b) => { b.disabled = busy; });
  return { close, setBusy };
}

export function confirmDialog({ title, message, confirmLabel = 'Confirm', danger = false }) {
  return new Promise((resolve) => {
    let done = false;
    const finish = (v) => { if (!done) { done = true; resolve(v); } m.close(); };
    const m = modal({
      title, width: 440, body: h('p', {}, message), onClose: () => { if (!done) { done = true; resolve(false); } },
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => finish(false) }, 'Cancel'),
        h('button', { class: `btn ${danger ? 'danger' : 'primary'}`, type: 'button', onclick: () => finish(true) }, confirmLabel)],
    });
  });
}

/* ---------- form helpers ---------- */
export function field(label, input, { hint, full = false, id } = {}) {
  const fid = id || `f${Math.random().toString(36).slice(2, 8)}`;
  input.id = fid;
  return h('div', { class: `field ${full ? 'full' : ''}` }, h('label', { for: fid }, label), input, hint ? h('div', { class: 'hint' }, hint) : null);
}
export const input = (props) => h('input', { class: 'input', ...props });
export const textarea = (props) => h('textarea', { class: 'input', ...props });
export function select(options, value, props = {}) {
  return h('select', { class: 'input', ...props }, options.map((o) => {
    const [v, label] = Array.isArray(o) ? o : [o, o];
    return h('option', { value: v, selected: String(v) === String(value) }, label);
  }));
}
export const checkbox = (label, checked) => { const i = h('input', { type: 'checkbox', checked }); return { el: h('label', { class: 'check' }, i, label), input: i }; };

/** Shows API validation details under a form. */
export function showErrors(box, error) {
  clear(box);
  if (!error) return;
  const details = Array.isArray(error.details) ? error.details : [];
  box.append(h('div', { class: 'error-text', role: 'alert' }, error.message || 'Something went wrong'));
  for (const d of details) box.append(h('div', { class: 'error-text small' }, `${d.path}: ${d.message}`));
}

/* ---------- data table ---------- */
export function table({ columns, rows, onRowClick, empty = 'Nothing here yet' }) {
  if (!rows.length) return h('div', { class: 'empty' }, h('strong', {}, empty));
  return h('div', { class: 'table-wrap' }, h('table', {},
    h('thead', {}, h('tr', {}, columns.map((c) => h('th', { class: c.num ? 'num' : '' }, c.label)))),
    h('tbody', {}, rows.map((r) => h('tr', { class: onRowClick ? 'click' : '', tabindex: onRowClick ? 0 : null,
      onclick: onRowClick ? () => onRowClick(r) : null, onkeydown: onRowClick ? (e) => { if (e.key === 'Enter') onRowClick(r); } : null },
    columns.map((c) => h('td', { class: c.num ? 'num' : '' }, c.render ? c.render(r) : (r[c.key] ?? '-'))))))));
}

export function pager({ page, pageSize, total, onChange }) {
  const pages = Math.max(1, Math.ceil(total / pageSize));
  const from = total ? (page - 1) * pageSize + 1 : 0, to = Math.min(total, page * pageSize);
  return h('div', { class: 'pager' }, h('span', { class: 'muted small' }, `${from}-${to} of ${num(total)}`),
    h('div', { class: 'row' },
      h('button', { class: 'btn small', type: 'button', disabled: page <= 1, onclick: () => onChange(page - 1) }, 'Previous'),
      h('span', { class: 'small' }, `Page ${page} of ${pages}`),
      h('button', { class: 'btn small', type: 'button', disabled: page >= pages, onclick: () => onChange(page + 1) }, 'Next')));
}

export const skeleton = (lines = 4) => h('div', { class: 'card card-pad', 'aria-busy': 'true' }, Array.from({ length: lines }, () => h('div', { class: 'skeleton', style: 'margin:10px 0' })));
export const debounce = (fn, ms = 300) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };

/* ---------- clipboard ---------- */
export function copyButton(text, label = 'Copy') {
  const b = h('button', { class: 'btn small', type: 'button', onclick: async () => {
    try { await navigator.clipboard.writeText(text); b.textContent = 'Copied'; setTimeout(() => { b.textContent = label; }, 1500); } catch { toast('Select the text and copy it manually', 'bad'); }
  } }, label);
  return b;
}

/* ---------- image picker ---------- */
/**
 * File input with preview that uploads straight away. `get()` returns the current image URL (or null).
 * Kept free of innerHTML: the preview is an <img> whose src is a same-origin /api/media URL or an https URL.
 */
export function imagePicker({ current = null, label = 'Choose image', upload, round = false }) {
  let url = current;
  const preview = h('div', { class: `img-preview ${round ? 'round' : ''}` });
  const status = h('span', { class: 'hint' });
  const draw = () => { preview.replaceChildren(url ? h('img', { src: url, alt: '' }) : h('span', { class: 'muted small' }, 'No image')); };
  const file = h('input', { type: 'file', accept: 'image/png,image/jpeg,image/webp', class: 'sr-only', tabindex: -1,
    onchange: async () => {
      const f = file.files[0];
      if (!f) return;
      if (f.size > 2 * 1024 * 1024) { status.textContent = 'That file is over 2 MB.'; file.value = ''; return; }
      status.textContent = 'Uploading...';
      try { const r = await upload(f); url = r.url; status.textContent = ''; draw(); } catch (e) { status.textContent = e.message; } finally { file.value = ''; }
    } });
  draw();
  const el = h('div', { class: 'picker' }, preview,
    h('div', { class: 'stack', style: 'gap:6px' }, h('div', { class: 'row' }, h('button', { class: 'btn small', type: 'button', onclick: () => file.click() }, label),
      h('button', { class: 'btn small', type: 'button', onclick: () => { url = null; draw(); } }, 'Remove')), status, h('div', { class: 'hint' }, 'PNG, JPEG or WebP, up to 2 MB'), file));
  return { el, get: () => url, set: (u) => { url = u; draw(); } };
}
