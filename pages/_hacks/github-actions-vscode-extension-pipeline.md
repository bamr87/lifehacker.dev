---
title: "Two GitHub Actions workflows that lint, test, and package a VS Code extension"
description: "A CI workflow that lints/builds/tests on a Node matrix, a Release workflow that packages and publishes the .vsix, and the xvfb error that breaks headless tests."
date: 2026-03-07
preview: /assets/images/previews/foundational-ci-cd-pipelines-github-vscode-extensions.png
collection: hacks
author: amr
excerpt: "Two YAML files take your extension from push to Marketplace — plus the headless-display crash that fails every integration test until you fix it."
tags: [github-actions, ci-cd, vscode-extension, devops]
---

![A retro diagram of a CI/CD pipeline with two parallel tracks](/assets/images/previews/foundational-ci-cd-pipelines-github-vscode-extensions.png)

A VS Code extension is a real software product with users, dependencies, and the same way of breaking on someone else's machine as anything else. The difference is that the consequences arrive in a one-star review instead of a Slack thread.

So you want two things automated: every push gets checked, and every tagged version gets packaged and shipped without you hand-cranking a `.vsix` at 11pm. That's two YAML files. Here they are, the gotcha that ate an afternoon included.

These run on GitHub's servers — they need npm, the network, and (for publishing) a token. None of it runs in a sandbox, so treat every block below as the config to commit, not output to trust. The one log excerpt below is the shape of a real failure, not a captured transcript — and it's flagged as such.

## The contract: your package.json scripts

The workflows don't know how to build your extension. They call npm scripts and trust you wired them up. This `scripts` block is the entire interface between the pipeline and your code:

```json
{
  "scripts": {
    "build": "esbuild src/extension.ts --bundle --outfile=dist/extension.js --external:vscode --format=cjs --platform=node --sourcemap",
    "lint": "eslint src/",
    "test": "vitest run",
    "package": "vsce package"
  }
}
```

If `npm run lint` works in your terminal, it works in CI. If it doesn't exist, CI fails on a missing script before it ever looks at your code. Get these green locally first.

## Workflow 1: CI on every push and PR

Create `.github/workflows/ci.yml`. This is the quality gate that runs on every push to `main` and every pull request against it:

{% raw %}
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [20, 22]

    steps:
      - uses: actions/checkout@v4

      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Build
        run: npm run build

      - name: Test
        run: npm test
```
{% endraw %}

Three details that aren't decoration:

**`npm ci`, not `npm install`.** `ci` wipes `node_modules/` and installs exactly what's in `package-lock.json` — no surprise version drift, no "works on my machine because my lockfile is stale." It's also faster because it skips dependency resolution. If `npm ci` itself fails, your lockfile is out of sync: run `npm install` locally and commit the changed `package-lock.json`.

**The matrix runs the whole job twice**, once on Node 20 and once on Node 22 — the active LTS versions as of this writing. Your dev dependencies (esbuild, eslint, the test runner) can behave differently across Node versions, and so can the machines your contributors clone onto. Two rows catch that before a user does. (Node 18 hit end-of-life in April 2025; don't pin a matrix to a dead runtime out of habit.)

**`cache: npm`** tells `setup-node` to cache `~/.npm` keyed on your lockfile. Same lockfile next run, dependencies come from cache instead of the registry — often a minute saved per row.

The steps run in order, and any failure stops the job: **lint, then build, then test.** That ordering is on purpose. Lint is the cheapest check and tests are the most expensive, so you get the fastest possible "you broke something" signal. Fail cheap, fail first.

You'll know it worked when the **Actions** tab shows a green check with two matrix rows (Node 20, Node 22), both passed.

## The part where it broke: headless tests and a missing display

Here's the failure I'm leaving in, because it's specific to VS Code extensions and nothing in the generic CI advice warns you about it.

The CI above uses a pure unit-test runner, which runs fine headless. But the moment you add *real* integration tests — the kind that launch an actual VS Code instance with `@vscode/test-electron` to exercise your commands — that test step dies on the runner with something like:

```
[main 2026-03-07T18:42:11.903Z] update#setState idle
Error: Failed to connect to the bus: Could not parse server address: Unknown address type
...
[ERROR:ozone_platform_x11.cc] Missing X server or $DISPLAY
[ERROR:env.cc] The platform failed to initialize. Exiting.
Exit code: 1
```

VS Code is an Electron app. Electron wants a display server to draw a window. A GitHub Actions Ubuntu runner is headless — there is no `$DISPLAY` — so the test host can't start and every integration test "fails" without a single assertion running.

The fix is `xvfb`, a virtual framebuffer that gives Electron a fake screen to render into. Install it and wrap the test command with `xvfb-run`:

```yaml
      - name: Install xvfb
        run: sudo apt-get update && sudo apt-get install -y xvfb

      - name: Test (headless VS Code)
        run: xvfb-run -a npm test
```

`xvfb-run -a` starts a throwaway X server on a free display number, points `$DISPLAY` at it, runs your command, and tears it down. The exact same `npm test` that crashed now passes because Electron finally has somewhere to draw.

You'll know it's fixed when the test step logs your test runner's summary (the `Error: Missing X server` line is gone) and exits 0. If you only run unit tests with no VS Code host, you don't need this — but the day you add one integration test, this is the error, and now you'll recognize it.

## Workflow 2: Release on a version tag

Create `.github/workflows/release.yml`. This one fires when you push a tag like `v0.1.0`. It rebuilds, retests, packages the `.vsix`, and publishes:

{% raw %}
```yaml
name: Release

on:
  push:
    tags: ["v*"]
  workflow_dispatch:

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Use Node.js 20
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Test
        run: npm test

      - name: Install vsce
        run: npm install -g @vscode/vsce

      - name: Package extension
        run: vsce package

      - name: Upload VSIX artifact
        uses: actions/upload-artifact@v4
        with:
          name: extension-vsix
          path: "*.vsix"

      - name: Publish to Marketplace
        if: startsWith(github.ref, 'refs/tags/v')
        run: vsce publish
        env:
          VSCE_PAT: ${{ secrets.VSCE_PAT }}
```
{% endraw %}

Yes, it builds and tests again even though CI already did. That's deliberate: a tag can be applied to an old commit that never went through CI, so the release job re-checks the exact commit it's about to ship. Never publish code you haven't verified moments before.

`vsce` is Microsoft's extension manager. `vsce package` produces the `.vsix` — a zip of your extension ready to install or upload. The upload-artifact step attaches it to the workflow run so you can download and sanity-check it, and `vsce publish` pushes it to the Marketplace. The `if:` guard means publish only happens on a real `v*` tag, not on a manual `workflow_dispatch` run, so you can dry-run the package step without shipping.

You'll know it worked when the run's artifact list contains a `.vsix` and the Marketplace shows the new version.

## The one secret you need: VSCE_PAT

`vsce publish` authenticates with a Personal Access Token from Azure DevOps (the Marketplace runs on Microsoft's identity, not GitHub's). Create one, then hand it to Actions:

1. At [dev.azure.com](https://dev.azure.com), sign in with the Microsoft account that owns your Marketplace publisher.
2. Profile icon, then **Personal access tokens**, then **New Token**.
3. Set **Organization** to **All accessible organizations**, **Scopes** to **Custom defined**, and check **Marketplace, Manage**. Pick an expiry and set a calendar reminder to rotate it.
4. **Create**, then copy the token immediately — it's shown once.
5. In your GitHub repo: **Settings**, then **Secrets and variables**, then **Actions**, then **New repository secret**. Name it `VSCE_PAT`, paste the value.

Now {% raw %}`${{ secrets.VSCE_PAT }}`{% endraw %} resolves at runtime and never appears in logs. When `vsce publish` fails with a 401, the token expired — regenerate and re-paste. That's the single most common release-day failure, and it's always the token.

## Shipping a version

With both files committed, a release is three commands:

```bash
git switch main
git pull
npm version patch        # bumps package.json, commits, and tags v0.1.1
git push --follow-tags   # pushes the commit AND the tag — the tag is what fires Release
```

`npm version patch` bumps the version in `package.json`, makes a commit, and creates a matching git tag in one step. The `--follow-tags` flag is the part people forget: a plain `git push` sends the commit but **not** the tag, and the Release workflow only listens for tags — so nothing happens and you stare at a quiet Actions tab wondering why. Push the tag.

## When it goes wrong

A quick map from symptom to cause, all of these seen for real:

- **`npm ci` fails** — lockfile out of sync. `npm install` locally, commit `package-lock.json`.
- **Test step dies with `Missing X server or $DISPLAY`** — headless Electron, no display. Wrap the test in `xvfb-run -a` (above).
- **`vsce package` fails** — `package.json` is missing a required field: usually `publisher`, `repository`, or an `icon`. Fill them in.
- **`vsce publish` returns 401** — `VSCE_PAT` expired. Regenerate the Azure DevOps token, update the secret.
- **Release ran nothing after `npm version`** — you pushed the commit without the tag. `git push --follow-tags`.

Two files, one token, and a virtual screen for the one app that insists on having a monitor. That's the whole pipeline — push code, push a tag, watch the green check, and stop building `.vsix` files by hand at 11pm.
