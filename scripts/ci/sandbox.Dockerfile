# =============================================================================
# sandbox.Dockerfile — the Prime Directive command sandbox
# -----------------------------------------------------------------------------
# A throwaway environment for run_hack_commands.rb to execute shell blocks from
# hacks/tools. It is run with --network=none --read-only and a non-root user, so
# a hostile or broken command can only scribble on an ephemeral tmpfs HOME.
#
# Keep the toolset to the common shell vocabulary our hacks assume (bash,
# coreutils, git, grep, sed, awk, curl, jq). A block that needs a tool NOT here
# (ripgrep, fzf, tmux) is expected to install it first — and with no network it
# will fail, which is the correct signal: an un-annotated block that can't run
# from a clean shell is a Field Note candidate, not a publishable hack.
# =============================================================================
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash coreutils git grep sed gawk curl jq ca-certificates less \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m -u 10001 run

# Sensible git identity so `git commit` demos in a hack don't abort.
RUN git config --system user.email "sandbox@lifehacker.dev" \
 && git config --system user.name  "lh sandbox"

USER run
WORKDIR /home/run
ENTRYPOINT []
