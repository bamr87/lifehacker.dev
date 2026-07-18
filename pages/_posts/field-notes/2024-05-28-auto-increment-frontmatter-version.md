---
title: "A pre-commit hook to bump front-matter versions, and the macOS Bash 3.2 traps along the way"
description: "A pre-commit hook that increments a version: field in Markdown front matter, plus the two macOS errors it hits first and the Bash 3.2-safe fixes."
date: 2024-05-28
categories: [Field Notes]
tags: [ci-cd, engineering]
author: amr
excerpt: "I wanted the version: in my front matter to tick up on every commit. macOS had two opinions about that first."
preview: /images/previews/a-pre-commit-hook-to-bump-front-matter-versions-an.png
---
I keep a `version:` field in the front matter of one Markdown file, and I wanted it to tick up by one every time I commit a change to that file. Not manually. Not "I'll remember." Automatically, on commit, scoped to only the files I'm actually staging.

A `pre-commit` hook is the right tool. The hook is the easy part. macOS had two separate objections before the easy part got to run, and both of them are the kind of thing that works fine on every Linux box in CI and then falls over on the laptop where you actually write.

Here is the whole trip, including the part where it broke. Twice.

## The plan

A `pre-commit` hook is a script Git runs before it finalizes a commit. Put an executable file at `.git/hooks/pre-commit`, and Git runs it every time — terminal, VS Code Source Control, GitHub Desktop, doesn't matter, they all shell out to the same Git. No file extension needed; Git cares that the file is executable, not what it's named.

The job: look at the staged files, find the ones that are Markdown with a `version: X.Y.Z` in their front matter, bump the last number, and re-stage the change so it lands in the same commit.

## The first thing that broke: `grep -oP`

The obvious way to pull the version out is a Perl-regex grep with a `\K` to drop everything before the match:

```bash
current_version=$(grep -oP 'version: \K.*' note.md)
```

Works great on Linux. On macOS it does this:

```console
$ /usr/bin/grep -oP 'version: \K.*' note.md
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxZz] [-A num] [-B num] [-C[num]]
	[-e pattern] [-f file] [--binary-files=value] [--color=when]
	[--context[=num]] [--directories=action] [--label] [--line-buffered]
	[--null] [pattern] [file ...]
```

macOS ships BSD `grep`, and BSD `grep` has no `-P`. There is no Perl mode to fall back to. (If you've installed GNU grep via Homebrew it'll be there as `ggrep`, but I'm not going to write a hook that assumes everyone on the repo did that.)

The portable replacement is `sed`, which is on every machine and doesn't need a `-P`:

```bash
current_version=$(sed -n 's/^version: \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$/\1/p' note.md)
```

You'll know it worked when `echo "$current_version"` prints `0.1.3` and not an empty line.

## The second thing that broke: `version_parts[-1]`

With the version string in hand, the tidy way to bump the last segment is to split on `.` and index the last element with `-1`:

```bash
IFS='.' read -ra version_parts <<< "$current_version"
version_parts[-1]=$(( version_parts[-1] + 1 ))
```

On macOS:

```console
$ bash increment.sh
increment.sh: line 2: version_parts: bad array subscript
increment.sh: line 2: version_parts[-1]: bad array subscript
```

Negative array indices are a Bash 4.0 feature. macOS still ships Bash 3.2 — has since 2007, for GPLv3-licensing reasons that aren't going to change — so `[-1]` is a syntax it has never heard of. And it's not hypothetical: the laptop I'm writing this on is current macOS, and `/bin/bash --version` still says `3.2.57(1)-release`. Your `#!/bin/bash` shebang gets that, not whatever newer Bash you may have installed elsewhere.

The 3.2-safe way is to compute the last index by hand from the array length:

```bash
IFS='.' read -ra version_parts <<< "$current_version"
last=$(( ${#version_parts[@]} - 1 ))
version_parts[$last]=$(( ${version_parts[$last]} + 1 ))
new_version=$(IFS=. ; echo "${version_parts[*]}")
```

`${#version_parts[@]}` is the element count; subtract one for the last index. No negative subscript, no Bash 4.

One thing to notice while we're here: this does integer math on the *last segment*, so `0.1.9` becomes `0.1.10`, not `0.2.0`, and definitely not `0.2` the way a `float + 0.1` would. If you've ever seen a version "increment" turn `1.9` into `2.0` and silently eat a release, that's why I'm doing string-segment math instead of treating the version as a number.

## The third thing, which isn't an error but bites anyway: scope

Two more things the naive version gets wrong, both silent:

It edits one hard-coded filename instead of the files you're committing. A hook should act on what's staged: `git diff --cached --name-only`.

And a blind `s/version: .../.../g` will happily rewrite the word "version" anywhere in the body, not just the front matter. The fix is to restrict `sed` to the first front-matter block — the lines from the top of the file to the first closing `---`:

```bash
sed -i '' -e "1,/^---$/{ s/^version: $current_version$/version: $new_version/; }" "$file"
```

(That `-i ''` is also macOS-specific: BSD `sed` requires an argument after `-i` for the backup-file suffix, and `''` means "no backup." GNU `sed` wants a bare `-i`. Another place this hook is quietly not portable to Linux without a tweak — but the hook only ever runs on my machine, so I optimized for the machine it runs on.)

## The hook that actually survives all three

Putting it together:

```bash
#!/bin/bash
# .git/hooks/pre-commit  —  bump version: in staged Markdown front matter

for file in $(git diff --cached --name-only); do
  case "$file" in
    *.md) : ;;
    *) continue ;;
  esac

  # pull X.Y.Z from the front-matter block only
  current=$(sed -n '1,/^---$/{ s/^version: \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$/\1/p; }' "$file")
  [ -n "$current" ] || continue

  # bump the last segment, Bash-3.2-safe
  IFS='.' read -ra parts <<< "$current"
  last=$(( ${#parts[@]} - 1 ))
  parts[$last]=$(( ${parts[$last]} + 1 ))
  new=$(IFS=. ; echo "${parts[*]}")

  # rewrite in the front matter only, then re-stage
  sed -i '' -e "1,/^---$/{ s/^version: $current$/version: $new/; }" "$file"
  git add "$file"
  echo "$file: $current -> $new"
done
```

Save it as `.git/hooks/pre-commit`, then `chmod +x .git/hooks/pre-commit`.

I ran this end-to-end on a throwaway repo on Bash 3.2 to make sure the story has a happy ending and not a third error:

```bash
# lh:run
cd "$(mktemp -d)"
git init -q
git config user.email demo@example.com
git config user.name demo

cat > note.md <<'EOF'
---
title: Some note
version: 1.4.9
---
the body also says version: 1.4.9 and must NOT change
EOF
git add note.md && git commit -qm "initial"

# make a change and stage it
printf 'one more line\n' >> note.md
git add note.md

# run the hook body under bash explicitly
for file in $(git diff --cached --name-only); do
  case "$file" in *.md) : ;; *) continue ;; esac
  current=$(sed -n '1,/^---$/{ s/^version: \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$/\1/p; }' "$file")
  [ -n "$current" ] || continue
  IFS='.' read -ra parts <<< "$current"
  last=$(( ${#parts[@]} - 1 ))
  parts[$last]=$(( ${parts[$last]} + 1 ))
  new=$(IFS=. ; echo "${parts[*]}")
  sed -i '' -e "1,/^---$/{ s/^version: $current$/version: $new/; }" "$file"
  git add "$file"
  echo "$file: $current -> $new"
done

echo "--- staged front matter ---"
git show :note.md | sed -n '1,4p'
```

The output:

```console
note.md: 1.4.9 -> 1.4.10
--- staged front matter ---
---
title: Some note
version: 1.4.10
---
```

`1.4.9 -> 1.4.10`, the body line still says `1.4.9`, and the bump is already in the staged copy, so it rides along in the commit you were about to make.

## When this goes wrong

A few honest edges:

- **The hook only fires on commits made through Git.** That's every normal client, but if some tool writes commits a stranger way, it won't run. Hooks aren't a security boundary — they're a convenience that can be skipped with `git commit --no-verify`.
- **`.git/hooks` is not version-controlled.** Nobody else on the repo gets this hook by cloning. If you want it shared, move the script into the repo and point Git at it with `git config core.hooksPath .githooks`, or reach for a manager like `pre-commit`.
- **It's deliberately macOS-flavored.** The `-i ''` and the 3.2-safe array math are there *because* of macOS. On a Linux CI box you'd want `-i` with no argument. I kept it macOS-shaped on purpose, since that's the only place this particular hook ever runs — but if you lift it into CI, that's the line that'll bite you back.
- **No version, no bump.** Files without a `version: X.Y.Z` in the front matter are skipped, silently. That's intended, but it does mean a typo'd version field (`version : 0.1.0`, extra space) just gets quietly ignored rather than flagged.

The feature is four lines of logic. The other twenty are macOS reminding you that the laptop is not the CI box, one error at a time.
