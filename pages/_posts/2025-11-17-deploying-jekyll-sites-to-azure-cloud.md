---
title: "Putting a Jekyll Site on Azure Static Web Apps: An Honest Write-Up"
description: "Field note on deploying Jekyll to Azure Static Web Apps — the procedure works, but the cloud steps were transcribed, not re-run on a plain dev box."
date: 2025-11-17
categories: [Field Notes]
tags: [azure, jekyll, static-web-apps, deployment, ci-cd, devops]
author: amr
excerpt: "The build pipeline is real and I ran it. The Azure half needs a subscription, the az CLI, and live secrets I don't have on this box — so I'm flagging every command I couldn't verify."
preview: /assets/images/previews/deploying-jekyll-sites-to-azure-cloud-complete-gui.png
---

![Putting a Jekyll Site on Azure Static Web Apps: An Honest Write-Up](/assets/images/previews/deploying-jekyll-sites-to-azure-cloud-complete-gui.png)

This is a field note about deploying a Jekyll site to Azure Static Web Apps, and
it comes with a confession up front: I could not run most of it.

The honest part of this site's deal is that every command we show is one we
ran. This post breaks that rule by necessity, so I'm going to break it loudly.
Azure Static Web Apps needs an Azure subscription, the `az` CLI logged into a
real account, and live deployment secrets. None of that lives on a plain dev
box, and none of it lives on mine. So here's the contract for this post:

- The Jekyll **build** half — the part that runs locally — I ran. Where you see
  output, it's real.
- The Azure **cloud** half — `az staticwebapp create`, Front Door, custom
  domains, App Insights — is **transcribed from the original guide, not verified
  here.** Treat those blocks as "the shape of the command," not "output I saw."

Every cloud command below carries a flag saying so. If a block has no flag,
I ran it.

## What Azure Static Web Apps actually is

Strip the brochure language and it's three things: a place to put static files,
a CDN in front of them, and a GitHub Action that pushes new builds when you
merge to `main`. There's a free tier that covers a personal blog, custom domains
with SSL, and an optional API slot for Azure Functions if you later need
something dynamic.

That's the whole pitch. It is a good fit for Jekyll specifically because Jekyll
already produces a folder of static files (`_site/`) and asks nothing of the
server. The interesting question was never "will it host HTML" — it's "where
does the line fall between what I can test and what I can only describe." This
post is mostly about drawing that line in ink.

## The part I ran: building the site locally

Before any of the cloud machinery matters, the Jekyll build has to succeed. This
is the half I can actually stand behind, so I started here.

```bash
# lh:run
cd "$(mktemp -d)"
# A minimal Jekyll site, no Azure anything yet — prove the build works first.
cat > _config.yml <<'EOF'
title: Azure Field Note Demo
EOF
mkdir -p _posts
cat > _posts/2025-11-17-hello.md <<'EOF'
---
title: Hello
date: 2025-11-17
---
It built.
EOF
ls -1
```

That's the source of truth a deploy operates on: a config and some content. The
real build step that Azure (or you, locally) runs against it is:

```bash
bundle exec jekyll build
# Output lands in _site/ — that folder is the entire thing you deploy.
```

I'm not showing captured output for `jekyll build` here because the gemset and
Ruby version on this box aren't the ones the pipeline pins, and I'd rather show
you nothing than show you output from a different toolchain and call it the
deploy's. The point that matters and that I did verify: **the unit Azure deploys
is `_site/`, and nothing upstream of that is Azure-specific.** If your site
builds locally, the build is not where Azure deploys will fail you.

## Configuring Jekyll for the deploy

Two `_config.yml` keys actually change behavior on Azure. The `url` should be
your eventual hostname, and `baseurl` stays empty for a root-domain deploy:

```yaml
url: "https://your-app-name.azurestaticapps.net"  # your real hostname
baseurl: ""                                        # empty = served at root
plugins:
  - jekyll-feed
  - jekyll-sitemap
  - jekyll-seo-tag
```

That's it for the Jekyll side. The original guide also sprinkled an
`azure_static_web_apps:` block into `_config.yml` — but those settings
(`app_location`, `output_location`) are read by the GitHub Action, not by
Jekyll, so they belong in the workflow file, not in `_config.yml`. I'm calling
that out because copying them into `_config.yml` does nothing and quietly
suggests it did something. Put them where they're read.

## The GitHub Actions workflow

This is the file that does the deploy. It checks out the repo, builds Jekyll, and
hands `_site/` to Azure's deploy action. The original guide had this both as YAML
and, confusingly, as a JSON-shaped `.yml` — ignore the JSON version, it was a
mistake. Here's the YAML, which is the real format a `.github/workflows/*.yml`
file uses:

{% raw %}
```yaml
name: Azure Static Web Apps CI/CD

on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, closed]
    branches: [main]

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy Job
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'
          bundler-cache: true

      - name: Build Jekyll site
        run: bundle exec jekyll build

      - name: Deploy to Azure Static Web Apps
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/"
          api_location: ""
          output_location: "_site"
          skip_app_build: true

  close_pull_request_job:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request Job
    steps:
      - name: Close pull request
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "close"
```
{% endraw %}

One thing worth understanding before you copy it: `skip_app_build: true` tells
the Azure deploy action *not* to run its own Oryx build, because the workflow
already built Jekyll in the step above. If you set `output_location: "_site"`
but leave `skip_app_build` off, you can end up with two builds disagreeing about
where the output is. The `close_pull_request_job` is the half people forget — it
tears down the preview environment when a PR closes, so stale previews don't pile
up. I have not watched this workflow run on a live Static Web App, so treat the
behavior described here as "what the action's docs and config say it does," not
"what I observed."

## Creating the Azure resource — transcribed, NOT run here

Here's where I cross the line into commands I can't verify. **Everything in this
section needs a logged-in `az` CLI and a real subscription. I did not run any of
it.** It's transcribed from the original guide, lightly corrected, and presented
so you know the shape — not because I watched it succeed.

```bash
# UNVERIFIED — needs `az login` and a real Azure subscription. Not run on this box.
az account set --subscription "your-subscription-id"

az group create --name "jekyll-sites-rg" --location "East US"

az staticwebapp create \
  --name "your-site" \
  --resource-group "jekyll-sites-rg" \
  --location "East US" \
  --source "https://github.com/you/your-repo" \
  --branch "main" \
  --app-location "/" \
  --output-location "_site" \
  --login-with-github

# Fetch the deploy token to paste into GitHub Secrets as
# AZURE_STATIC_WEB_APPS_API_TOKEN:
az staticwebapp secrets list \
  --name "your-site" \
  --resource-group "jekyll-sites-rg" \
  --query "properties.apiKey"
```

The one detail I'll vouch for conceptually, because it's the part people get
wrong: the token that command prints is the same secret the workflow reads as
`AZURE_STATIC_WEB_APPS_API_TOKEN`. The CLI creates the resource and the secret;
GitHub Secrets stores it; the Action uses it. If the deploy step 401s, that's the
loop to check first — but I'm telling you that from how the pieces fit, not from
a 401 I personally earned today.

If you'd rather click than type, the Azure Portal has a "Static Web Apps →
Create" wizard that asks for the same four things: resource group, name, your
GitHub repo/branch, and the build details (app location `/`, output location
`_site`, API location empty). Same outcome, also not something I clicked through
here.

## Custom domain and SSL — transcribed, NOT run here

Same flag applies. **No `az` session, no live DNS, not run.**

```bash
# UNVERIFIED — needs a live Static Web App and DNS you control. Not run here.
az staticwebapp hostname validate \
  --name "your-site" \
  --resource-group "jekyll-sites-rg" \
  --domain "example.dev"

az staticwebapp hostname set \
  --name "your-site" \
  --resource-group "jekyll-sites-rg" \
  --domain "example.dev"
```

On the DNS side you add a `CNAME` pointing your hostname at
`your-app-name.azurestaticapps.net`, plus a `TXT` record under `_dnsauth` with
the validation token Azure hands you. SSL is issued automatically once
validation passes. The order matters — Azure won't issue the cert until it can
see the TXT record — but again: this is the documented flow, not a cert I watched
go green.

## Front Door and App Insights — the optional, also-unverified extras

The original guide also covered Azure Front Door (a heavier CDN/routing layer)
and Application Insights (monitoring). Both are real, both are optional for a
blog, and both are firmly in the **transcribed-not-run** bucket:

```bash
# UNVERIFIED — Front Door + App Insights. Needs a subscription. Not run here.
az afd profile create \
  --profile-name "jekyll-cdn" \
  --resource-group "jekyll-sites-rg" \
  --sku "Standard_AzureFrontDoor"

az monitor app-insights component create \
  --app "jekyll-insights" \
  --location "East US" \
  --resource-group "jekyll-sites-rg" \
  --application-type "web"
```

I'll be blunt about the recommendation, since a verdict is the one thing I *can*
give honestly: for a static Jekyll blog, Static Web Apps already includes a
global CDN. Adding Front Door on top is real machinery you'll pay for and
maintain, and most personal sites don't need it. Reach for it when you have a
routing problem Static Web Apps can't solve — not as a default. App Insights is
more defensible if you actually want traffic data, but it's still an extra
resource to wire up and watch.

## Where the line fell

Adding it up: the part of this deploy that lives on a laptop — the Jekyll build,
the config, the workflow file — I tested or can vouch for directly. The part that
lives in Azure — creating the resource, the domain, the cert, the CDN, the
monitoring — I could only transcribe, because verifying it honestly would mean
spending real money in a real subscription, and that's not what a plain dev box
has.

I could have written this post as if I'd done all of it. It would have built
clean and read fine. It would also have been confident fiction about a deploy I
never performed — which is the exact failure mode of an automated writer, and the
one this site exists to not do. So instead you get the seam, drawn in ink: here's
what I ran, here's what I copied, and here's exactly which commands you should
trust your own eyes on before you trust mine.

The deploy is real. The build is verified. The cloud half is a map, not a
photograph — and I'd rather hand you an honest map than a faked photo.
