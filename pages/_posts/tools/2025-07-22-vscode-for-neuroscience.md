---
title: "VS Code as a Python research IDE: conda envs, Jupyter cells, and a debugger that actually stops"
description: "VS Code as a Python research IDE — per-project envs, # %% cells, an inline debugger, and the two config traps (wrong interpreter, dead launch type)."
date: 2025-07-22
categories: [Tools]
tags: [data, system, editor]
author: amr
verdict: "Use it — but pin the interpreter per project or it will silently run the wrong Python"
excerpt: "A free editor that runs cells, stops on breakpoints, and finds the wrong Python by default. Verdict: use it, after you pin the interpreter."
preview: /images/previews/section-tools.svg
permalink: /tools/vscode-for-neuroscience/
---
**Verdict: use it as your research IDE — once you've pinned the right Python per project.** VS Code is a free editor that does the three things a Python researcher actually needs in one window: run code cell-by-cell like a notebook, stop on a breakpoint and let you poke at variables, and autocomplete a library you half-remember. It's for people who've outgrown a bare terminal and `print()` but don't want to live inside a heavyweight scientific IDE. It is not for people who want zero configuration — the default "which Python am I running?" behavior will burn you at least once, and that's where this review spends its time.

VS Code is free (MIT-licensed core; the Microsoft-branded build adds telemetry and a non-OSS license — VSCodium is the fully-open rebuild if that matters to you). We have no relationship with the project and nothing to sell. The Python and Jupyter extensions are also free, also from Microsoft.

This piece uses a neuroscience setup (EEG, PsychoPy, a decision model) as the worked example, but nothing here is field-specific — swap the libraries and it's the same IDE.

## Install

```bash
brew install --cask visual-studio-code   # macOS
# or download from code.visualstudio.com
```

Then the three extensions that turn the editor into a Python IDE. You can do this from the GUI, but the CLI is faster and scriptable:

```bash
code --install-extension ms-python.python      # language support + interpreter picker
code --install-extension ms-python.vscode-pylance  # type-aware autocomplete
code --install-extension ms-toolsai.jupyter    # # %% cells and .ipynb notebooks
```

The box we wrote this on:

```bash
$ code --version
1.125.1

$ code --list-extensions --show-versions | grep ms-python
ms-python.debugpy@2026.6.0
ms-python.python@2026.4.0
ms-python.vscode-pylance@...
```

That `debugpy` line matters later — hold onto it.

## Step 1: a per-project environment (and where VS Code finds it)

The single most useful habit is one isolated environment per project, so `pip install` in one analysis can't break another. The original Anaconda route works, but plain `venv` ships with Python and is enough for most research code:

```bash
# lh:run
cd "$(mktemp -d)"
python3 -m venv .venv
. .venv/bin/activate
python3 -c "import sys; print(sys.executable)"
```

Real output from that run:

```console
/private/var/folders/.../tmp.YaJO2lbdNl/.venv/bin/python3
```

The point of that last line: once activated, `python3` resolves *inside* the project, not to your system Python. If you prefer conda for the binary scientific stack (MNE, nibabel), `conda create -n research python=3.11 numpy scipy mne` does the same job; the rest of this review is identical either way.

**You'll know it worked when** your shell prompt shows `(.venv)` and `which python3` points inside the project folder.

## Step 2: tell VS Code which Python to use — this is the trap

Here's the part the quick-start guides gloss over and the part that wastes the afternoon. VS Code does **not** automatically use the environment you activated in your terminal. It picks an interpreter on its own — often your system Python, which doesn't have your packages — and then you get this, in an editor that was autocompleting `mne` a second ago:

```console
ModuleNotFoundError: No module named 'mne'
```

The package is installed. The environment is fine. VS Code is just running a different Python than your terminal. This is the most common "it broke and I don't know why" moment with this editor, and it looks like a dependency problem when it's a configuration problem.

The fix, every time:

1. `Cmd+Shift+P` → **Python: Select Interpreter**
2. Choose the one whose path ends in `.venv/bin/python` (or `envs/research/bin/python` for conda)

To make it stick for everyone who opens the project, commit a `.vscode/settings.json`:

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "search.exclude": {
    "**/data/**": true,
    "**/*.nii.gz": true,
    "**/*.fif": true
  }
}
```

We wrote that file and confirmed it's valid before trusting it:

```console
both .vscode JSON files parse OK
```

(The `search.exclude` block is a bonus: it keeps Cmd+Shift+F from grinding through gigabytes of raw recordings. Add your own large-data globs.)

**You'll know it worked when** the bottom-right status bar shows your env name, and an import that just failed now resolves.

## Step 3: cells, without leaving a `.py` file

The feature that wins most converts from a plain editor: write `# %%` in an ordinary `.py` file and the lines below it become a runnable cell. `Shift+Enter` runs it in an interactive window and keeps the variables warm, exactly like a notebook — but the file stays a normal script you can diff, lint, and import. A cell-marked file is still just Python; we ran this one as a plain script to prove it:

```bash
# lh:run
cd "$(mktemp -d)"
cat > model.py <<'PY'
# %%
import statistics
# %%
samples = [0.41, 0.55, 0.39, 0.62, 0.48]
print(f"mean rt: {statistics.mean(samples):.3f}s")
PY
python3 model.py
```

Real output:

```console
mean rt: 0.490s
```

For a worked example shaped like real analysis — an EEG load, a quick PSD, then filtering — the cells map one-to-one onto the steps you'd run in any order:

```python
# %%
import mne
raw = mne.io.read_raw_fif('sample_data.fif', preload=True)

# %%
raw.plot_psd(fmax=50)   # plots render inline in the interactive window

# %%
raw.filter(l_freq=1, h_freq=40)
raw.set_eeg_reference('average')
```

That block is documentation, not something we ran — it needs MNE and a real recording, which the offline sandbox here doesn't have. Treat it as the shape, not as captured output.

If you want a true `.ipynb` notebook instead, `Cmd+Shift+P` → **Create: New Jupyter Notebook**, then click **Select Kernel** and pick the same environment. If the kernel list is empty, you're missing one package — see the breakage section.

## Step 4: a debugger that actually stops (and the config that's gone stale)

This is the reason to stop debugging with `print()`. Click left of a line number to set a breakpoint, hit `F5`, and execution stops *on that line* with every variable inspectable — DataFrames, NumPy arrays, the lot — in the left panel. For a model where you can't tell why the numbers drift, stepping through one trial beats sprinkling print statements.

Most of the time `F5` just works. The moment you write a custom `launch.json`, beware the most-copied stale snippet on the internet. Older guides give the debug `"type"` as `"python"`:

```json
{ "type": "python", "request": "launch", "program": "${file}" }
```

That type name was **renamed to `debugpy`** when the debugger moved into its own extension (the `ms-python.debugpy@2026.6.0` from our version check above). Use the old name and the launch silently does nothing, or VS Code complains it can't find the debug type. The current, working config:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Current File",
      "type": "debugpy",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": false
    }
  ]
}
```

`justMyCode: false` is the one worth knowing for research: it lets you step *into* library code, which is the whole point when you suspect the bug is in how you're calling MNE, not in your own loop.

**You'll know it worked when** `F5` halts on your breakpoint and the Variables pane fills in. If nothing happens at all, check that `"type"` says `debugpy`.

## What it costs and the free alternatives

The editor and the extensions cost nothing. The honest comparisons:

- **Spyder** ships a variable explorer and an interactive console out of the box with zero interpreter-picking — if that one-shot simplicity is all you want, it's the lower-friction choice. VS Code earns its extra setup with the debugger, Git integration, and being the same editor for your non-Python files.
- **JupyterLab** in a browser is the closest thing to the notebook experience if you live entirely in `.ipynb`. VS Code's edge is keeping cells inside diff-able `.py` files and the inline debugger.
- **PyCharm** Community is free and has a stronger debugger and refactoring tools, at the cost of being heavier and slower to start.

VS Code's actual niche: one window for cells, debugging, Git, and your shell, all free, at the price of configuring the interpreter yourself.

## The part where it broke (left in, because it's the point)

These are the real failures, with the message and the fix:

- **`ModuleNotFoundError` on a package you definitely installed.** VS Code is running a different interpreter than your terminal. `Cmd+Shift+P` → Python: Select Interpreter, pick the `.venv` one, then `Cmd+Shift+P` → Developer: Reload Window. This is the big one; suspect it first, every time.
- **Empty kernel list when creating a notebook.** The environment lacks `ipykernel`. Activate it and run `pip install ipykernel`, then `python -m ipykernel install --user --name research`. Reload the window and the kernel appears.
- **`F5` does nothing / "configured debug type is not supported".** Your `launch.json` says `"type": "python"`. Change it to `"debugpy"`.
- **Search and the editor crawl on a data-heavy repo.** You're indexing raw recordings. Add your large-file globs to `search.exclude` (see Step 2). And keep `data/` out of Git — a `.gitignore` with `*.nii.gz`, `*.fif`, `*.edf`, `*.h5` saves you from committing a several-gigabyte file you can never cleanly remove.

## What made us close the tab

Nothing made us uninstall it — it stays. The two honest caveats:

- **The interpreter is yours to manage, forever.** Per project, per machine, VS Code can and will pick the wrong Python, and the error it throws (`ModuleNotFoundError`) points you at the wrong problem. Commit `python.defaultInterpreterPath` once and most of this evaporates.
- **The Microsoft build phones home.** Telemetry is on by default. You can turn most of it off in settings, or switch to VSCodium if you want the open build. Neither changes the workflow above.

**When it goes wrong:** an import fails that worked a minute ago — check the interpreter in the status bar before you touch your code. The notebook kernel list is empty — `pip install ipykernel`. The debugger won't stop — your `launch.json` is using the dead `python` type instead of `debugpy`. Learn those three and the editor stops fighting you and starts disappearing into the work.
