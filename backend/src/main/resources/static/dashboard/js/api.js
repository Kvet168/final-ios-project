// API client for the dashboards. Same origin as the server, so no base URL and no CORS.

const KEY = { access: 'wf.access', refresh: 'wf.refresh', user: 'wf.user' };
const store = window.sessionStorage;

export class ApiError extends Error {
  constructor(status, code, message, details) { super(message); this.status = status; this.code = code; this.details = details; }
}

export const session = {
  get user() { try { return JSON.parse(store.getItem(KEY.user)); } catch { return null; } },
  get access() { return store.getItem(KEY.access); },
  get refresh() { return store.getItem(KEY.refresh); },
  save({ accessToken, refreshToken, user }) {
    store.setItem(KEY.access, accessToken);
    store.setItem(KEY.refresh, refreshToken);
    if (user) store.setItem(KEY.user, JSON.stringify(user));
  },
  clear() { Object.values(KEY).forEach((k) => store.removeItem(k)); },
};

let refreshing = null;
async function refreshTokens() {
  if (!session.refresh) return false;
  refreshing ||= fetch('/api/auth/refresh', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ refreshToken: session.refresh }) })
    .then(async (r) => { if (!r.ok) return false; const t = await r.json(); session.save(t); return true; })
    .catch(() => false)
    .finally(() => { refreshing = null; });
  return refreshing;
}

let onExpired = () => {};
export const onSessionExpired = (fn) => { onExpired = fn; };

async function request(method, path, body, retried = false) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (session.access) headers.Authorization = `Bearer ${session.access}`;
  let res;
  try {
    res = await fetch(`/api${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  } catch {
    throw new ApiError(0, 'NETWORK', 'Cannot reach the server. Check your connection and try again.');
  }
  if (res.status === 401 && !retried && !path.startsWith('/auth/') && await refreshTokens()) return request(method, path, body, true);
  if (res.status === 401 && !path.startsWith('/auth/')) { session.clear(); onExpired(); }
  if (res.status === 204) return null;
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    const e = data?.error || {};
    throw new ApiError(res.status, e.code || 'ERROR', e.message || `Request failed (${res.status})`, e.details);
  }
  return data;
}

const qs = (q) => {
  const p = new URLSearchParams();
  for (const [k, v] of Object.entries(q || {})) if (v !== undefined && v !== null && v !== '') p.set(k, v);
  const s = p.toString();
  return s ? `?${s}` : '';
};

export const api = {
  upload,
  get: (path, query) => request('GET', path + qs(query)),
  post: (path, body = {}) => request('POST', path, body),
  patch: (path, body = {}) => request('PATCH', path, body),
  put: (path, body = {}) => request('PUT', path, body),
  del: (path) => request('DELETE', path),
};

/** Uploads an image (PNG, JPEG or WebP, max 2 MB). Returns { id, url }. */
export async function upload(file) {
  const form = new FormData();
  form.append('file', file);
  const send = () => fetch('/api/media', { method: 'POST', headers: { Authorization: `Bearer ${session.access}` }, body: form });
  let res;
  try { res = await send(); } catch { throw new ApiError(0, 'NETWORK', 'Cannot reach the server. Check your connection and try again.'); }
  if (res.status === 401 && await refreshTokens()) res = await send();
  const data = await res.json().catch(() => null);
  if (!res.ok) throw new ApiError(res.status, data?.error?.code || 'ERROR', data?.error?.message || `Upload failed (${res.status})`);
  return data;
}

export async function login(email, password) {
  const r = await request('POST', '/auth/login', { email, password });
  session.save(r);
  return r.user;
}

export async function logout() {
  const rt = session.refresh;
  try { if (rt) await request('POST', '/auth/logout', { refreshToken: rt }); } catch { /* signing out locally anyway */ }
  session.clear();
}
