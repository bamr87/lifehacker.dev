# Site quality checks (Lighthouse CI + axe + pa11y)

Run on every PR to `main` that touches the site by [`site-quality.yml`](../workflows/site-quality.yml). The workflow builds `_site` through the same safe-mode overlay as `verify` (the `build-overlay` composite, which runs `scripts/ci/build.sh`), serves it on `127.0.0.1:4000` and checks it. Nothing here touches the live site, nothing needs a secret, and nothing calls a model. It is not a required check: `verify` is still the only required gate.

| File | What it does |
|---|---|
| `serve-site.mjs` | Zero-dependency static server for `_site` that behaves like GitHub Pages: gzip, `/dir/` → `index.html`, `/dir` → 301, `404.html` with HTTP 404, `cache-control: max-age=600`. Without gzip the transfer-size budgets would be meaningless. |
| `lighthouserc.cjs` | Lighthouse CI: `/`, `/news/` and one post, mobile, 3 runs, assertions on the median. Category, Web Vitals, must-pass audit and resource-size assertions, with per-page overrides. |
| `a11y-check.mjs` | axe-core 4.13 through Playwright (the runner's Google Chrome) on the pages in `a11y.config.mjs`, at 390 px and 1366 px. |
| `contrast-check.mjs` | pa11y (HTML_CodeSniffer, WCAG2AA) keeping only the WCAG 1.4.3 contrast results, because axe reports most text on this theme as "incomplete". |
| `a11y.config.mjs` | Pages, viewports, the known-issue list for axe, and the per-page contrast limits. |
| `lhci-summary.mjs` | Writes the Lighthouse table and every failed assertion to the job summary. |

## What fails a PR and what only warns

- **Lighthouse, `error`:** accessibility, best-practices and SEO ≥ 0.95, plus the must-pass audits `errors-in-console`, `unsized-images`, `label`, `button-name` and `link-name`, on every page where they already pass on `main`.
- **Lighthouse, `warn`:** performance ≥ 0.70, LCP ≤ 3.5 s, FCP ≤ 2.0 s, CLS ≤ 0.1, TBT ≤ 300 ms, and the size budgets (CSS ≤ 60 KiB, fonts ≤ 160 KiB, images ≤ 300 KiB, scripts ≤ 250 KiB, third-party ≤ 150 KiB, total ≤ 800 KiB). The page-specific `warn` overrides for assertions that don't pass yet each carry a `TODO(error)` that names the fix.
- **Lighthouse, `off`:** `uses-long-cache-ttl` and `cache-insight`. GitHub Pages always sends `max-age=600`, and that can't be changed.
- **axe, fail:** any `critical` or `serious` violation of a `wcag2a`/`wcag2aa`/`wcag21a`/`wcag21aa` rule.
- **axe, warn:** WCAG 2.2 rules (`target-size`), plus the entries in `known` in `a11y.config.mjs`. Each entry is limited to one rule, the listed pages and viewports, and the nodes that match its regex, so a new violation under the same rule still fails.
- **Contrast:** a page with `max` fails when it has more contrast failures than that number. Pages that are clean today are pinned at `max: 0` (`/search/`). `/news/` and the post are report-only until the theme's badge-link and inline-code colours are fixed.

## Tightening

When a fix lands, delete its `known` entry or its `warn` override, or add `max: 0`, in the same PR as the fix. The axe job prints a notice when a `known` entry stops reproducing. Run the checks locally against a build:

```bash
bash scripts/ci/build.sh            # safe-mode overlay build -> _site
cd .github/site-quality && PUPPETEER_SKIP_DOWNLOAD=1 PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci
node serve-site.mjs ../../_site 4000 &
npx lhci autorun --config=lighthouserc.cjs   # Lighthouse collect + assert
node a11y-check.mjs && node contrast-check.mjs
```

The scripts use the installed Google Chrome. Set `CHROME_PATH` for pa11y, or `PW_CHANNEL=` to use Playwright's own Chromium (`npx playwright install chromium`).
