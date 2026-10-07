// =============================================================================
// a11y.config.mjs — pages, viewports and known issues for the PR a11y checks
// -----------------------------------------------------------------------------
// Read by a11y-check.mjs (axe-core via Playwright) and contrast-check.mjs
// (pa11y / HTML_CodeSniffer). Paths are served from the local _site build.
// =============================================================================
const POST = '/posts/2026/09/23/i-finished-a-pull-request-i-didnt-open/';

export default {
  viewports: [
    { name: 'mobile-390', width: 390, height: 844, mobile: true },
    { name: 'desktop-1366', width: 1366, height: 768 },
  ],

  // Key pages: home, the news landing, one hack, one post, tags, about, search.
  pages: ['/', '/news/', '/hacks/your-txt-is-a-jpeg/', POST, '/tags/', '/about/', '/search/'],

  axe: {
    // Any critical/serious violation of these rules FAILS the job...
    blockingTags: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'],
    blockingImpacts: ['critical', 'serious'],
    // ...while WCAG 2.2 rules (in practice `target-size`: the nav
    // split-toggle is 20x36 px) are reported as warnings only.
    // TODO(error): move 'wcag22aa' into blockingTags once the zer0-mistakes nav
    // toggle is >= 24 px wide.
    warnTags: ['wcag22a', 'wcag22aa'],

    // Violations that already exist on main. Each one is downgraded to a
    // WARNING — still listed in the job summary and as an annotation — but only
    // for this rule, on these pages, on nodes matching `nodes` (a regex over the
    // node's selector + HTML). Anything else under the same rule still fails.
    // Delete an entry when its fix lands; the job prints a notice when an entry
    // stops reproducing.
    known: [
      {
        rule: 'button-name',
        pages: ['*'],
        viewports: ['mobile-390'],
        nodes: 'shareDropdownBottom',
        todo: 'TODO(theme fix): intro "Share" dropdown is icon-only below 576 px (text is span.d-none.d-sm-inline) — zer0-mistakes _includes/content/intro.html',
      },
      {
        rule: 'link-name',
        pages: ['*'],
        viewports: ['mobile-390'],
        nodes: 'bd-intro-action-link',
        todo: 'TODO(theme fix): intro "Edit on GitHub" link is icon-only below 576 px — zer0-mistakes _includes/content/intro.html',
      },
    ],
  },

  contrast: {
    // `max` = most contrast failures allowed before the page FAILS. Pages that
    // are clean today are pinned at 0; the rest are report-only for now.
    pages: [
      // TODO(error): max: 0 once the theme's neon skin stops overriding badge
      // link colour ($link-light #5e22cc on bg-primary = 1.45:1).
      { path: '/news/' },
      // TODO(error): max: 0 once inline `code` (#d63384 on #f8f9fa, 4.27:1)
      // and the badge colours are fixed in the theme.
      { path: POST },
      { path: '/search/', max: 0 },
    ],
    // Gradient hero headings (e.g. the homepage Top Story on .zer0-bg-hero):
    // htmlcs measures them against the flat fallback colour and reports false
    // 1:1 failures, so they're hidden first.
    hideElements: '.zer0-bg-hero h1, .zer0-bg-hero h2, .bd-intro h1, .bd-intro h2',
  },
};
