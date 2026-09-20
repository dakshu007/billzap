// Who gets in, and how.
//
// Three things guard the studio, because the obvious one is not
// enough on its own:
//
//   ADMIN_PATH      a long random segment. The studio lives at
//                   /s/<ADMIN_PATH>; every other /s/… is a 404, so a
//                   crawler or a drive-by scan finds nothing. On its
//                   own this would still be weak — URLs leak through
//                   history, referrers and proxy logs — so it only
//                   decides whether the login page exists at all.
//   ADMIN_PASSWORD  what actually authenticates. Compared against a
//                   PBKDF2 hash; the plaintext is never stored.
//   SESSION_SECRET  signs the session cookie, so a cookie cannot be
//                   forged without it.
//
// No third-party auth service, no user table: there is exactly one
// person who should ever log in.
import crypto from 'node:crypto';

const COOKIE = 'bz_studio';
const MAX_AGE = 60 * 60 * 12;          // 12 hours

/** PBKDF2-SHA256. Format: pbkdf2$<iterations>$<salt_b64>$<hash_b64> */
export function hashPassword(pw, iterations = 210000, salt = null) {
  const s = salt || crypto.randomBytes(16);
  const h = crypto.pbkdf2Sync(pw, s, iterations, 32, 'sha256');
  return `pbkdf2$${iterations}$${s.toString('base64')}$${h.toString('base64')}`;
}

export function verifyPassword(pw, stored) {
  try {
    const [scheme, iter, saltB64, hashB64] = String(stored).split('$');
    if (scheme !== 'pbkdf2') return false;
    const want = Buffer.from(hashB64, 'base64');
    const got = crypto.pbkdf2Sync(pw, Buffer.from(saltB64, 'base64'),
                                  parseInt(iter, 10), want.length, 'sha256');
    // Constant time: a length mismatch must not short-circuit either.
    return got.length === want.length && crypto.timingSafeEqual(got, want);
  } catch { return false; }
}

function sign(value) {
  return crypto.createHmac('sha256', process.env.SESSION_SECRET || '')
    .update(value).digest('base64url');
}

export function issueCookie() {
  const expires = Date.now() + MAX_AGE * 1000;
  const payload = `${expires}`;
  const token = `${payload}.${sign(payload)}`;
  return `${COOKIE}=${token}; Path=/; Max-Age=${MAX_AGE}; HttpOnly; Secure; SameSite=Strict`;
}

export function clearCookie() {
  return `${COOKIE}=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Strict`;
}

export function isAuthed(headers) {
  const raw = headers.cookie || headers.Cookie || '';
  const m = raw.match(new RegExp(`(?:^|;\\s*)${COOKIE}=([^;]+)`));
  if (!m) return false;
  const [payload, sig] = m[1].split('.');
  if (!payload || !sig) return false;
  const expected = sign(payload);
  if (sig.length !== expected.length) return false;
  if (!crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected))) return false;
  return Number(payload) > Date.now();
}

/** The studio only exists at its configured path. */
export function pathMatches(segment) {
  const want = process.env.ADMIN_PATH || '';
  if (!want || !segment) return false;
  const a = Buffer.from(segment), b = Buffer.from(want);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}
