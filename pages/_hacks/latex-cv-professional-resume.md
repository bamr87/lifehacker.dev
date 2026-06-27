---
title: "Version-control your CV: LaTeX, VS Code, and the .gitignore that hides the build mess"
description: "Compile a LaTeX resume in VS Code, then track it in git with the seven-line .gitignore that keeps .aux, .log, and the PDF out of your history."
date: 2026-06-26
collection: hacks
author: amr
excerpt: "Your CV in LaTeX, in git — minus the dozen build files every compile spits out and the one ordering mistake that commits them anyway."
tags: [latex, git, vscode, resume, macos]
---

A resume is a document that has to look the same in six months as it does today, that you will edit in a panic the night before you need it, and that you would like a clean record of. That is the exact shape of a problem version control was built for. So we are putting the CV in LaTeX and the LaTeX in git.

The catch nobody mentions: a single LaTeX compile leaves behind half a dozen files you never asked for — `.aux`, `.log`, `.out`, a `.synctex.gz`, sometimes a `.fdb_latexmk` — plus the PDF. Commit those by reflex and your git history fills up with regenerated junk and merge conflicts on a log file. The whole hack is one source file under version control and everything else swept under a `.gitignore`. We are going to prove that sweep works instead of assuming it.

## Install the toolchain (macOS)

This part downloads a few gigabytes over the network, so it is documentation, not something we ran in a sandbox. Run it on your own machine.

MacTeX is the full LaTeX distribution for macOS. Install it and VS Code via Homebrew:

```bash
brew update
brew install --cask mactex
brew install --cask visual-studio-code
```

MacTeX is large (~4 GB) and the cask install takes a while. You'll know it worked when a new shell can find the compiler:

```bash
which pdflatex
# /Library/TeX/texbin/pdflatex
```

If `which pdflatex` comes back empty, the installer added `/Library/TeX/texbin` to your `PATH` in a file your *current* shell hasn't re-read. Open a new terminal tab and try again before you debug anything else.

Then add the LaTeX Workshop extension to VS Code, which gives you build-on-save and a side-by-side PDF preview:

```bash
code --install-extension James-Yu.latex-workshop
```

## A resume that actually compiles

Create `resume.tex`. This is a deliberately plain template — no exotic packages, so it builds on a fresh MacTeX install with nothing extra:

```latex
\documentclass[11pt]{article}
\usepackage[utf8]{inputenc}
\usepackage[margin=1in]{geometry}
\usepackage{enumitem}
\usepackage{titlesec}
\titleformat{\section}{\large\bfseries}{}{0pt}{}[\titlerule]
\setlist[itemize]{leftmargin=*, topsep=2pt}

\begin{document}

\begin{center}
  {\Large\textbf{Your Name}}\\[2pt]
  \small Your City, State \textbullet\ you@example.com \textbullet\ (555) 555-0100
\end{center}

\section*{Experience}
\begin{itemize}
  \item \textbf{Job Title} --- Company, \textit{Mon Year -- Present}\\
        What you did and the number that proves it.
\end{itemize}

\section*{Education}
\begin{itemize}
  \item \textbf{Degree} --- University, \textit{Year}
\end{itemize}

\section*{Skills}
\begin{itemize}
  \item Skill, skill, skill.
\end{itemize}

\end{document}
```

Save it. With LaTeX Workshop installed, the build runs on save; otherwise hit the TeX badge in the status bar, or compile from the terminal:

```bash
pdflatex resume.tex
```

You'll know it worked when a `resume.pdf` appears next to your `.tex` file and the last line of output is roughly `Output written on resume.pdf (1 page, NNNNN bytes)`. If instead it stops at a `!` line — `! Undefined control sequence` is the classic — read the line number it prints, not the wall of text after it. That line is where your LaTeX is wrong; everything below is the compiler flailing.

> A note on honesty: this site's build host has no TeX installed, so the `pdflatex` lines above are documentation of a workflow, not output we captured here. The git half below, we ran for real.

## Put it in git — and keep the mess out

Here is what that compile *also* did: it dropped `resume.aux`, `resume.log`, `resume.out`, and a `resume.synctex.gz` into the folder, every one of them regenerated on the next build. None belong in version control. Write the `.gitignore` **before** your first `git add`, because the order is the entire trick.

Create `.gitignore` in the project root:

```text
# LaTeX build artifacts — regenerated on every compile
*.aux
*.log
*.out
*.fls
*.fdb_latexmk
*.synctex.gz
*.toc
# The compiled PDF: comment this out if you want the PDF tracked too
*.pdf
```

That last line is a judgment call. Tracking only the `.tex` keeps history tiny and diffs readable; tracking the PDF too means anyone can grab the finished resume without a LaTeX install. Pick one on purpose, rather than by accident.

Here is the part we ran for real, in a sandbox with no network: a throwaway directory standing in for the CV project, the same `.gitignore`, the same git commands. We faked the source file and the build artifacts a compile would leave, then checked what git actually tracked.

```bash
# lh:run
cd "$(mktemp -d)"
mkdir cv-demo && cd cv-demo

# The source, plus the junk a LaTeX build leaves behind.
touch resume.tex
touch resume.aux resume.log resume.out resume.synctex.gz resume.pdf

cat > .gitignore <<'EOF'
*.aux
*.log
*.out
*.synctex.gz
*.pdf
EOF

git init -q
git config user.email you@example.com
git config user.name "You"
git add .
git commit -q -m "Initial commit of LaTeX CV"

echo "--- files git is actually tracking ---"
git ls-files
echo
echo "--- git status --porcelain (empty = clean) ---"
git status --porcelain
echo "[end of status]"
```

Real output:

```text
--- files git is actually tracking ---
.gitignore
resume.tex

--- git status --porcelain (empty = clean) ---
[end of status]
```

Read the tracked-files list, because it is the proof. We created five build artifacts including `resume.pdf` — and `git ls-files` shows **none** of them. Git tracks exactly two things: the `.gitignore` and the source. The empty `git status --porcelain` is the second tell — after a clean commit it prints nothing, so the ignored files aren't leaking back in as untracked entries.

## The part where it broke

Here is the failure, left in, because it is the one that actually happens.

The first time, the order gets reversed. You `git init`, you `git add .` because that's the reflex, you compile a few times — *then* you remember the `.gitignore`. Too late. The build artifacts are already tracked, and `.gitignore` only ever stops *untracked* files. We ran that exact mistake:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir cv-broken && cd cv-broken

touch resume.tex
touch resume.aux resume.log resume.out resume.synctex.gz resume.pdf

git init -q
git config user.email you@example.com
git config user.name "You"

# The reflex: add everything BEFORE writing .gitignore.
git add .
git commit -q -m "Initial commit"

# Now, too late, write the .gitignore.
cat > .gitignore <<'EOF'
*.aux
*.log
*.out
*.synctex.gz
*.pdf
EOF

echo "--- git ls-files: the junk is already tracked ---"
git ls-files
```

Real output:

```text
--- git ls-files: the junk is already tracked ---
resume.aux
resume.log
resume.out
resume.pdf
resume.synctex.gz
resume.tex
```

Every artifact is in there. Adding them to `.gitignore` now changes nothing — git is already tracking them, so it keeps doing so. The fix is to untrack them without deleting your local copies, then commit the `.gitignore`:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir cv-broken && cd cv-broken
touch resume.tex resume.aux resume.log resume.out resume.synctex.gz resume.pdf
git init -q
git config user.email you@example.com
git config user.name "You"
git add .
git commit -q -m "Initial commit"
printf '%s\n' '*.aux' '*.log' '*.out' '*.synctex.gz' '*.pdf' > .gitignore

# The fix: --cached removes from git's index but leaves files on disk.
git rm -r --cached resume.aux resume.log resume.out resume.synctex.gz resume.pdf -q
git add .gitignore
git commit -q -m "Stop tracking build artifacts"

echo "--- git ls-files after the fix ---"
git ls-files
```

Real output:

```text
--- git ls-files after the fix ---
.gitignore
resume.tex
```

`--cached` is the load-bearing flag: it drops the files from git's index while leaving the actual files on your disk, so your next compile still has somewhere to write. After this commit, the `.gitignore` finally takes over and the artifacts stay out of every future commit.

## Push it to GitHub

Once the local tree is clean, the remote part — network and credentials required, so run it yourself. Create an empty repo at [github.com/new](https://github.com/new) first, and do **not** tick "Add a README," because you already have a commit and an initialized remote will reject your push with `failed to push some refs` / `fetch first` from the two histories disagreeing.

```bash
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/resume.git
git push -u origin main
```

You'll know it worked when `git push` reports a new branch tracking `origin/main` and the object count it uploaded matches a two-file tree (or three with the PDF), not a dozen. A suspiciously large number means your build artifacts are riding along — go back to the section above.

## The honest accounting

This does not make your resume better. The bullet points are still your job to write, and no amount of typesetting will rescue a hollow one.

What it buys you is a clean history of a document you will edit under pressure, a diff that shows what actually changed instead of a churn of regenerated log files, and the ability to compile last year's version exactly as it was. The cost is seven lines of `.gitignore` — written *before* the first `git add`, every time, because that is the one rule the whole thing hangs on.

Write the `.gitignore` first. Run `git ls-files` once before you push. Then go fix the bullet points.
