// Trace Bloom — xAI credential resolution (OAuth first).
//
// House convention matches scripts/ai/run.sh: a subscription/OAuth token wins
// over a metered API key, and the key is never sent when OAuth is present.
// Sources, in order:
//   1. XAI_OAUTH_TOKEN
//   2. Official Grok CLI store (~/.grok/auth.json from `grok login`)
//   3. Kilo's local xAI OAuth store (~/.local/share/kilo/auth.json), refreshed
//      against auth.x.ai when the access token is expired
//   4. XAI_API_KEY (pay-per-use; last resort)
//
// Never logs a token. GROK_AUTH_PATH / KILO_AUTH_PATH override store locations (tests).

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const AUTH_HOST = 'https://auth.x.ai';
const TOKEN_PATHS = ['/oauth/token', '/oauth2/token'];
const SKEW_MS = 60_000;

const kiloAuthPath = () => {
  if (process.env.KILO_AUTH_PATH) return process.env.KILO_AUTH_PATH;
  const xdg = process.env.XDG_DATA_HOME || path.join(os.homedir(), '.local', 'share');
  return path.join(xdg, 'kilo', 'auth.json');
};

const grokAuthPath = () => process.env.GROK_AUTH_PATH
  || path.join(os.homedir(), '.grok', 'auth.json');

/** Official Grok CLI store: { "https://auth.x.ai::<client>": { "key": "<jwt>" }, … } */
const grokSlot = (store) => {
  if (!store || typeof store !== 'object') return null;
  const rows = Object.entries(store);
  const hit = rows.find(([k]) => k.includes('auth.x.ai'))
    || rows.find(([k]) => k.includes('accounts.x.ai'));
  if (!hit) return null;
  const [scope, value] = hit;
  const rec = value && typeof value === 'object' ? value : { key: value };
  const access = rec.key || rec.access || rec.access_token;
  if (!access) return null;
  const clientId = (scope.split('::')[1] || rec.client_id || '').trim();
  return {
    access,
    refresh: rec.refresh || rec.refresh_token || '',
    client_id: clientId,
    expires: rec.expires,
  };
};

const decodeJwt = (token) => {
  const parts = String(token || '').split('.');
  if (parts.length < 2) return null;
  try {
    const pad = parts[1] + '='.repeat((4 - (parts[1].length % 4)) % 4);
    return JSON.parse(Buffer.from(pad, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
};

const expiryMs = (value, fallbackJwt) => {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value > 1e12 ? value : value * 1000;
  }
  const exp = fallbackJwt && Number(fallbackJwt.exp);
  return Number.isFinite(exp) ? exp * 1000 : 0;
};

const readStore = (file) => {
  if (!fs.existsSync(file)) return null;
  try {
    const data = JSON.parse(fs.readFileSync(file, 'utf8'));
    return data && typeof data === 'object' ? data : null;
  } catch {
    return null;
  }
};

const writeStore = (file, data) => {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
};

async function refreshOAuth(refreshToken, clientId) {
  const body = new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: clientId,
  }).toString();
  let last = 'no token endpoint responded';
  for (const p of TOKEN_PATHS) {
    const res = await fetch(`${AUTH_HOST}${p}`, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body,
    });
    const text = await res.text().catch(() => '');
    if (!res.ok) {
      last = `${res.status} from ${p}`;
      if (res.status === 404) continue;
      throw new Error(`xAI OAuth refresh failed (${last})`);
    }
    let json;
    try { json = JSON.parse(text); } catch {
      throw new Error('xAI OAuth refresh returned non-JSON');
    }
    if (!json.access_token) throw new Error('xAI OAuth refresh returned no access_token');
    return json;
  }
  throw new Error(`xAI OAuth refresh failed (${last})`);
}

export async function resolveXaiAuth() {
  const oauthEnv = (process.env.XAI_OAUTH_TOKEN || '').trim();
  if (oauthEnv) {
    return { token: oauthEnv, source: 'XAI_OAUTH_TOKEN', mode: 'oauth' };
  }

  const grok = grokSlot(readStore(grokAuthPath()));
  if (grok && grok.access) {
    const jwt = decodeJwt(grok.access);
    const exp = expiryMs(grok.expires, jwt);
    if (!exp || exp - SKEW_MS > Date.now()) {
      return { token: grok.access, source: 'grok-auth', mode: 'oauth' };
    }
  }

  const file = kiloAuthPath();
  const store = readStore(file);
  const slot = store && store.xai;
  if (slot && (slot.access || slot.refresh)) {
    const jwt = decodeJwt(slot.access);
    const exp = expiryMs(slot.expires, jwt);
    if (slot.access && exp - SKEW_MS > Date.now()) {
      return { token: slot.access, source: 'kilo-auth', mode: 'oauth' };
    }
    if (slot.refresh) {
      const clientId = slot.client_id || (jwt && jwt.client_id) || (jwt && jwt.aud);
      if (!clientId) {
        throw new Error('xAI OAuth access token expired and the store has no client_id to refresh with — re-login via Kilo');
      }
      const fresh = await refreshOAuth(slot.refresh, String(clientId));
      const next = {
        ...slot,
        type: 'oauth',
        access: fresh.access_token,
        refresh: fresh.refresh_token || slot.refresh,
        expires: Date.now() + (Number(fresh.expires_in) || 3600) * 1000,
        client_id: clientId,
      };
      writeStore(file, { ...store, xai: next });
      return { token: next.access, source: 'kilo-auth-refresh', mode: 'oauth' };
    }
    throw new Error('xAI OAuth access token in the Kilo store is expired and has no refresh token — re-login via Kilo');
  }

  const key = (process.env.XAI_API_KEY || '').trim();
  if (key) return { token: key, source: 'XAI_API_KEY', mode: 'api_key' };

  const err = new Error(
    'no xAI credential. Run `grok login`, set XAI_OAUTH_TOKEN, or set XAI_API_KEY',
  );
  err.noCredential = true;
  throw err;
}

export function configuredXai(root, ymlPath) {
  const defaults = {
    model: 'grok-imagine-image-2.0',
    aspect: '3:2',
    resolution: '1k',
    quality: 'medium',
    base: process.env.XAI_BASE_URL || 'https://api.x.ai/v1',
  };
  const file = ymlPath || path.join(root, '_data', 'ai.yml');
  try {
    const yml = fs.readFileSync(file, 'utf8');
    const grab = (key, fallback) => {
      const m = yml.match(new RegExp(`^${key}:\\s*(\\S+)`, 'm'));
      return m ? m[1].replace(/^["']|["']$/g, '') : fallback;
    };
    return {
      model: process.env.LH_XAI_IMAGE_MODEL || grab('xai_image_model', defaults.model),
      aspect: process.env.LH_XAI_IMAGE_ASPECT || grab('xai_image_aspect', defaults.aspect),
      resolution: process.env.LH_XAI_IMAGE_RESOLUTION || grab('xai_image_resolution', defaults.resolution),
      quality: process.env.LH_XAI_IMAGE_QUALITY || grab('xai_image_quality', defaults.quality),
      base: defaults.base,
    };
  } catch {
    return defaults;
  }
}
