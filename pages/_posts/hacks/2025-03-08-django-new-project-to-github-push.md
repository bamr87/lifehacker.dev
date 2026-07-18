---
title: "New Django project to first GitHub push, without committing your secrets"
description: "Create a Django project in a virtualenv, write the four-line .gitignore that keeps your venv and .env out of git, and push to GitHub safely."
date: 2025-03-08
categories: [Hacks]
tags: [git, data]
author: amr
excerpt: "Five commands to a Django project on GitHub, and the .gitignore that stops you from publishing your SECRET_KEY to the whole internet."
preview: /assets/images/git-django.png
permalink: /hacks/django-new-project-to-github-push/
---
There is a specific kind of afternoon where you create a Django project, get it onto GitHub, and feel productive — right up until someone points out that your `.env` file, the one with `SECRET_KEY` in it, is now public.

![A retro illustration pairing the Django and git logos](/assets/images/git-django.png)

So this is the boring version that does not do that. New project, virtualenv, a four-line `.gitignore`, first commit, push. The interesting part is the one line in the middle that decides whether your secrets ship with your code, and we are going to prove it works instead of assuming it.

## Make the project

This part needs the network — `pip` downloads Django, `django-admin` is a real binary you install. So this is documentation, not something we ran in a sandbox. Run it on your own machine:

```bash
mkdir django-project && cd django-project
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install django
django-admin startproject myproject .
```

The trailing `.` on `startproject` matters: it puts `manage.py` in the current directory instead of nesting it one folder deeper. You'll know it worked when `ls` shows `manage.py` next to a `myproject/` folder and a `venv/` folder, and your prompt has `(venv)` stuck to the front of it.

## The four lines that matter

Before you put anything under version control, write the `.gitignore`. Do it *first*, because the order is the whole hack — if you `git add .` before this file exists, the secrets are already staged.

Create `.gitignore` in the project root:

```text
venv/
__pycache__/
db.sqlite3
.env
```

That is the entire list, and each line is there for a reason. `venv/` is hundreds of files nobody else needs (they make their own). `__pycache__/` is compiled bytecode that regenerates itself. `db.sqlite3` is your local database — your data, not your code. And `.env` is the one that ends careers: it holds your `SECRET_KEY` and any API keys, and it should never, ever leave your laptop.

## Commit it, and check what actually got tracked

Here is the part we ran for real, in a sandbox with no network — a throwaway directory standing in for a fresh Django project, the same `.gitignore`, the same commands. The output below is captured, not imagined:

```bash
cd "$(mktemp -d)"
# A throwaway dir that pretends to be a fresh Django project.
mkdir demo && cd demo

# Fake the files `django-admin startproject` would have created,
# plus the junk we do NOT want in git.
mkdir myproject venv __pycache__
touch manage.py myproject/settings.py
touch db.sqlite3 venv/pyvenv.cfg __pycache__/views.cpython-312.pyc
echo "SECRET_KEY=please-do-not-commit-me" > .env

# The whole point: the .gitignore.
cat > .gitignore <<'EOF'
venv/
__pycache__/
db.sqlite3
.env
EOF

git init -q
git config user.email you@example.com
git config user.name "You"
git add .
git commit -q -m "Initial commit"

echo "--- files git is actually tracking ---"
git ls-files

echo
echo "--- git status --porcelain (empty = clean, nothing leaked) ---"
git status --porcelain
echo "[end of status]"
```

Real output:

```text
--- files git is actually tracking ---
.gitignore
manage.py
myproject/settings.py

--- git status --porcelain (empty = clean, nothing leaked) ---
[end of status]
```

Read that tracked-files list closely, because it is the proof. We created `db.sqlite3`, a `venv/`, a `__pycache__/`, and a `.env` with a secret in it — and `git ls-files` shows **none of them**. Git is tracking exactly three things: the `.gitignore`, `manage.py`, and the settings file. The `.env` stayed home.

The empty `git status --porcelain` is the second tell. After a commit, a clean tree prints nothing. If your ignored files were leaking, they'd show up here as `??` untracked entries. They don't.

## The part where it broke

Here is the failure, left in, because it is the one that actually happens.

The first time, the order gets reversed. You `git init`, you `git add .` because that's the reflex, *then* you remember the `.gitignore` and write it. Too late: the secret is already staged. You won't see a warning. `git commit` succeeds. `git push` succeeds. Everything is green.

Then `git ls-files` (or a colleague, or a security scanner) shows you this:

```text
.env
.gitignore
__pycache__/views.cpython-312.pyc
db.sqlite3
manage.py
myproject/settings.py
venv/pyvenv.cfg
```

`.env`, `db.sqlite3`, and the whole `venv/` are in the list — `git add .` with no `.gitignore` grabs everything in the directory. Adding them to `.gitignore` *now* does nothing — `.gitignore` only stops *untracked* files. Git is already tracking these, so it keeps tracking them, secret and all.

The fix is to untrack everything that should have been ignored, without deleting your local copies:

```bash
git rm -r --cached venv __pycache__ db.sqlite3 .env
git commit -m "Stop tracking secrets, venv, and local db"
```

`-r` recurses into the directories; `--cached` removes them from git's index but leaves the actual files on disk. After this, `.gitignore` finally takes over and they stay out of future commits.

And the genuinely unpleasant truth: if you already **pushed** that `.env`, rotate the secret. It is in the git history on GitHub now, and removing it from the latest commit does not remove it from the history. Treat that `SECRET_KEY` as burned and generate a new one. This is the entire reason we write `.gitignore` first.

## Push it to GitHub

Once the local commit is clean, the remote part. This needs the network and your GitHub credentials, so again — documentation, run it yourself:

```bash
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/django-project.git
git push -u origin main
```

Create the repo at [github.com/new](https://github.com/new) first, and do **not** check the "Add a README" box — you already have local commits, and an initialized remote will reject your push with a `failed to push some refs` / `fetch first` error from the histories disagreeing.

You'll know it worked when `git push` prints `Branch 'main' set up to track 'origin/main'` and the file count it uploaded matches what `git ls-files` showed — three files, not three hundred. If the number is suspiciously large, your `venv/` is going up; stop, and revisit the section above.

## The honest accounting

This does not save you time. A Django project is five commands either way.

What it saves you is the afternoon where you rotate a leaked `SECRET_KEY`, force-rewrite git history you don't fully understand, and explain to someone why the API key was public for two hours. The `.gitignore` is four lines and it is the cheapest insurance in the whole workflow — but only if it exists *before* the first `git add`.

Write the four lines first. Run `git ls-files` once before you push. Then go build the thing.
