// The browser demo's session: who filled in the form at /try.
//
// A signed cookie, like the studio's, carrying the lead's id and the
// business name the demo shop is named after. It is not a login to
// anything valuable — the demo is the app with a sample shop — so a
// cookie is all it needs. Signed so the name on the page is the one
// that was submitted, with a "try." prefix in the HMAC input so a demo
// cookie can never be passed off as a studio one.
import crypto from 'node:crypto';

const COOKIE = 'bz_try';
const MAX_AGE = 60 * 60 * 24 * 30;        // 30 days

function sign(value) {
  return crypto.createHmac('sha256', process.env.SESSION_SECRET || '')
    .update('try.' + value).digest('base64url');
}

export function issueTryCookie({ id, shop }) {
  const payload = Buffer.from(JSON.stringify({
    id, shop, exp: Date.now() + MAX_AGE * 1000,
  })).toString('base64url');
  return `${COOKIE}=${payload}.${sign(payload)}; Path=/; Max-Age=${MAX_AGE}; HttpOnly; Secure; SameSite=Lax`;
}

export function clearTryCookie() {
  return `${COOKIE}=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax`;
}

/** The session, or null. Accepts a headers object or a Cookie string. */
export function readTry(headersOrCookie) {
  const raw = typeof headersOrCookie === 'string'
    ? headersOrCookie
    : (headersOrCookie?.cookie || headersOrCookie?.Cookie || '');
  const m = raw.match(new RegExp(`(?:^|;\\s*)${COOKIE}=([^;]+)`));
  if (!m || !process.env.SESSION_SECRET) return null;
  const [payload, sig] = m[1].split('.');
  if (!payload || !sig) return null;
  const want = sign(payload);
  if (sig.length !== want.length ||
      !crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(want))) return null;
  try {
    const s = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    return s.exp > Date.now() ? s : null;
  } catch { return null; }
}
