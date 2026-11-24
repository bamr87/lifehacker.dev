/*
 * Wargames — site scripts.
 *
 * The zer0-mistakes theme loads assets/js/user-overrides.js whenever `user_overrides: true` is set in
 * _config.yml (needed for assets/css/user-overrides.css), after its own scripts. This is the theme's
 * documented customisation layer, so no theme file is overridden. Contents:
 *   1. Search index URL fix.
 */

/*
 * 1. Search index URL.
 *
 * The theme's search modal (assets/js/search-modal.js) loads its index from
 * `new URL('/search.json', window.location.origin)`: the domain root, with no baseurl. This site is a
 * project site served under /wargames, so that request 404s and the modal reports "Search is
 * unavailable on this site" even though the index exists at /wargames/search.json.
 *
 * Rewrite just that one request to include the baseurl. The baseurl is derived from this script's own
 * URL (/<baseurl>/assets/js/user-overrides.js), so nothing is hard-coded, and the shim does nothing
 * when the site is served from the domain root.
 */
(function () {
  'use strict';
  var script = document.currentScript || document.querySelector('script[src*="user-overrides.js"]');
  if (!script || !script.src || typeof window.fetch !== 'function') return;

  var base = new URL('../..', script.src).pathname.replace(/\/$/, '');
  if (!base) return;

  var nativeFetch = window.fetch;
  window.fetch = function (input, init) {
    if (typeof input === 'string') {
      try {
        var url = new URL(input, window.location.href);
        if (url.origin === window.location.origin && url.pathname === '/search.json') {
          url.pathname = base + '/search.json';
          return nativeFetch.call(this, url.toString(), init);
        }
      } catch (e) {
        /* not a parseable URL: fall through to the untouched request */
      }
    }
    return nativeFetch.apply(this, arguments);
  };
})();
