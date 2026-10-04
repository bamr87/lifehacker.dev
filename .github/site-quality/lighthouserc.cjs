// =============================================================================
// lighthouserc.cjs — Lighthouse CI budgets for lifehacker.dev (PR gate)
// -----------------------------------------------------------------------------
// Run by .github/workflows/site-quality.yml against the locally built _site,
// served by serve-site.mjs (gzip + GitHub Pages-style URLs) on 127.0.0.1:4000.
// Mobile (Lighthouse's default form factor + simulated 4G/CPU throttling), 3
// runs per URL, every assertion on the MEDIAN of the 3.
//
// Levels — read this before tightening:
//   * Category scores (a11y / best-practices / SEO >= 0.95) and the must-pass
//     audits are 'error' on every page where they ALREADY pass, so the gate is
//     green on arrival and blocks regressions.
//   * Performance, Web-Vitals metrics and resource-size budgets start at 'warn':
//     the site doesn't meet them yet (render-blocking theme CSS, icon font,
//     oversized card images). Each `TODO(error)` says what flips it.
//   * Cache-policy audits are OFF: GitHub Pages always sends max-age=600 and we
//     can't change it, so those findings are noise here.
// Sizes are transfer bytes (gzip), KiB * 1024.
// =============================================================================
const BASE = process.env.SITE_URL || 'http://127.0.0.1:4000';
const KiB = 1024;

const PAGES = {
  home: '/',
  news: '/news/',
  post: '/posts/2026/09/23/i-finished-a-pull-request-i-didnt-open/',
};

// 'median' (not 'median-run'): LHCI applies median-run to audits but not to
// category scores, which silently fall back to the best run.
const median = { aggregationMethod: 'median' };
const min = (level, minScore) => [level, { ...median, minScore }];
const max = (level, maxNumericValue) => [level, { ...median, maxNumericValue }];

// Shared by every page; per-page overrides below.
const base = {
  // --- categories ----------------------------------------------------------
  'categories:accessibility': min('error', 0.95),
  'categories:best-practices': min('error', 0.95),
  'categories:seo': min('error', 0.95),
  // TODO(error): flip to 'error' once the zer0-mistakes theme fix lands
  // (critical CSS / non-blocking bootstrap + icon CSS, auto-hide-nav reflow).
  'categories:performance': min('warn', 0.7),

  // --- metrics (mobile, simulated) — TODO(error) after the theme perf fixes --
  'largest-contentful-paint': max('warn', 3500),
  'first-contentful-paint': max('warn', 2000),
  'cumulative-layout-shift': max('warn', 0.1),
  'total-blocking-time': max('warn', 300),

  // --- must-pass audits ----------------------------------------------------
  'errors-in-console': min('error', 1),
  'unsized-images': min('error', 1),
  label: min('error', 1),
  'button-name': min('error', 1),
  'link-name': min('error', 1),

  // --- size budgets (transfer bytes) — warn until the theme purges CSS and
  // subsets bootstrap-icons; TODO(error) per line once each one passes. -------
  'resource-summary:stylesheet:size': max('warn', 60 * KiB),
  'resource-summary:font:size': max('warn', 160 * KiB),
  'resource-summary:image:size': max('warn', 300 * KiB),
  'resource-summary:script:size': max('warn', 250 * KiB),
  'resource-summary:third-party:size': max('warn', 150 * KiB),
  'resource-summary:total:size': max('warn', 800 * KiB),

  // --- off: GitHub Pages cache headers are fixed (max-age=600) -------------
  'uses-long-cache-ttl': 'off',
  'cache-insight': 'off',
};

// Per-page exceptions to `base`. Keep each one specific and TODO-tagged.
const overrides = {
  home: {},
  news: {},
  post: {
    // TODO(error): related-post `img.card-img-top` has no width/height — the
    // theme's _includes/components/preview-image.html emits none. Back to
    // 'error' once the theme fix PR (width/height on preview images) lands.
    'unsized-images': min('warn', 1),
  },
};

const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

module.exports = {
  ci: {
    collect: {
      url: Object.values(PAGES).map((p) => BASE + p),
      numberOfRuns: 3,
      settings: {
        // Mobile is Lighthouse's default config (the `preset` option only
        // offers 'desktop'/'perf'/'experimental'); spelled out so it's explicit.
        formFactor: 'mobile',
        throttlingMethod: 'simulate',
        skipAudits: ['uses-long-cache-ttl', 'cache-insight'],
        chromeFlags: '--no-sandbox',
      },
    },
    assert: {
      assertMatrix: Object.entries(PAGES).map(([key, path]) => ({
        // Anchored so '/' only matches the home page.
        matchingUrlPattern: `^${escape(BASE + path)}$`,
        assertions: { ...base, ...overrides[key] },
      })),
    },
    upload: {
      target: 'filesystem',
      outputDir: 'reports/lighthouse',
    },
  },
};
