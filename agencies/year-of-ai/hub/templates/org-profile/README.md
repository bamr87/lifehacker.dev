<!--
  Org profile README, staged for the `year-of-ai/.github` repo.

GitHub shows this on https://github.com/year-of-ai when it lives at `profile/README.md` in a repo named `.github`. Publish it with:

    gh repo create year-of-ai/.github --public \
      --description "Org profile for the year-of-ai federated knowledge network"
    git clone https://github.com/year-of-ai/.github /tmp/org-profile
    mkdir -p /tmp/org-profile/profile
    cp templates/org-profile/README.md /tmp/org-profile/profile/README.md
    (cd /tmp/org-profile && git add -A && git commit -m "docs: org profile" && git push)

The hub registry already excludes `.github` from the content dashboard. -->

# Year of AI

**A federated network of self-growing knowledge bases — one repository per year, grown daily by AI, each publishing its own site.**

🌐 **Start here: [year-of-ai.github.io](https://year-of-ai.github.io/)** — the hub dashboard that tracks every year site.

## How it works

- Each year repo (1776–1778, 2005–2012, …) holds only **content**: encyclopedic pages about that year's history, science, arts, society, and people.
- The [hub repo](https://github.com/year-of-ai/year-of-ai.github.io) is the **central growth engine**: a daily orchestrator picks the stalest members and runs a 3-tier model escalation (Haiku draft → Sonnet expand → Opus enhance) that researches, writes, and publishes new topics into them.
- Every site renders with the shared [zer0-mistakes](https://github.com/bamr87/zer0-mistakes) Jekyll theme via `remote_theme` — no repo vendors theme files.
- The whole model is captured as a replantable [organizational genome](https://github.com/year-of-ai/year-of-ai.github.io/tree/main/genome), so a new org can grow a different concept the same way.

📖 The full explainer: [How it grows](https://year-of-ai.github.io/orchestration/) · 🤖 [The self-improvement fleet](https://year-of-ai.github.io/self-improvement/) · 📜 [Decision records](https://github.com/year-of-ai/year-of-ai.github.io/tree/main/lineage/decisions)
