---
title: "Scaffold a VS Code extension in five minutes: yo code, F5, ship"
description: "Scaffold a VS Code extension with yo code, run it with F5, and wire one real command — plus the activate quirk that registers a command nobody can run."
date: 2024-02-14
categories: [Hacks]
tags: [web-dev]
author: amr
excerpt: "The whole loop from empty folder to a working command in the palette — and the one-line mismatch that makes your command vanish."
preview: /images/previews/scaffold-a-vs-code-extension-in-five-minutes-yo-co.webp
permalink: /hacks/building-code-extension/
---
You have an editor command you run by hand forty times a week: select some text, reformat it, save it somewhere. The productivity blogs wave a hand and say "write a VS Code extension." They never show you the part where you spend an afternoon fighting the generator and staring at a Command Palette that swears your command doesn't exist.

So here's the actual loop: empty folder to a working command in the palette, in about five minutes, with the one mismatch that eats the afternoon called out by name.

The concrete example is the one I needed: take a chat transcript open in the editor and reformat it into clean Markdown headings. But the scaffold is identical for any "do a thing to the current file" command — swap the transform, keep everything else.

A note on what's runnable here. `yo code` and `npm` need the network and an interactive terminal, so those blocks are the config to type, not output to trust. The transform logic in the middle is plain Node — I ran it on this machine and pasted the real output, because that's the only part that actually does the work.

## Step 1: scaffold with yo code

The generator is a one-time global install. It scaffolds the folder layout, the `package.json`, and a working hello-world command so you start from something that already runs:

```bash
npm install -g yo generator-code
yo code
```

`yo code` is interactive. The answers that matter:

- **What type of extension?** → **New Extension (JavaScript)**. (TypeScript is the better long-term choice, but JavaScript skips the build step, which is what you want for your first one.)
- **Name** → `copilot-md-export` (this becomes the folder name).
- **Initialize a git repository?** → yes.
- **Bundle with esbuild / install dependencies with npm?** → yes to both.

You'll know it worked when there's a new folder named after your extension containing `package.json`, `extension.js`, and a `.vscode/` directory. The generator already wired up a `helloWorld` command — you haven't written anything yet and you already have a runnable extension.

Open it:

```bash
cd copilot-md-export
code .
```

## Step 2: F5 to run it

This is the part the tutorials gloss over. You do not install your extension to test it. You run it in a second VS Code window that loads your code from source.

Press **F5**.

A new window opens with `[Extension Development Host]` in the title bar. That window is running your extension. Open the Command Palette there (`Cmd+Shift+P` / `Ctrl+Shift+P`), type **Hello World**, and run it — a notification pops up in the bottom corner.

You'll know it worked when you see the **Hello World** notification in the Extension Development Host window. That's the entire dev loop: edit code in the first window, hit the green restart arrow in the debug toolbar (or `Cmd+Shift+F5`), test in the second. No publish, no install, no reload-the-whole-app.

## Step 3: replace the command with one that does real work

Now make it yours. Two files change: `package.json` declares the command exists, and `extension.js` says what it does. Both have to agree on the command's ID — hold that thought, it's the gotcha.

In `package.json`, the generator left a `contributes.commands` block. Replace the hello-world entry:

```json
{
  "contributes": {
    "commands": [
      {
        "command": "copilotMdExport.toMarkdown",
        "title": "Copilot: Export Conversation as Markdown"
      }
    ]
  }
}
```

`command` is the internal ID your code registers against. `title` is the human-readable string you'll actually search for in the palette. They are not the same string and they don't have to be.

In `extension.js`, the body is a handful of `vscode` API calls around a plain function. Here's the whole thing — read the active editor, run a transform, open the result in a new tab:

```javascript
const vscode = require('vscode');

// The pure transform. No vscode import needed — which is why it's testable.
function toMarkdown(raw) {
  // Role lines look like "bamr87:" or "GitHub Copilot:". Turn each into an
  // H2 heading; leave every other line untouched.
  return raw
    .split('\n')
    .map((line) => {
      const m = line.match(/^(bamr87|GitHub Copilot):\s*(.*)$/);
      if (!m) return line;
      const speaker = m[1] === 'GitHub Copilot' ? 'Copilot' : 'You';
      return `## ${speaker}\n\n${m[2]}`;
    })
    .join('\n');
}

function activate(context) {
  const disposable = vscode.commands.registerCommand(
    'copilotMdExport.toMarkdown',
    async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) {
        vscode.window.showErrorMessage('No active editor — open a transcript first.');
        return;
      }
      const markdown = toMarkdown(editor.document.getText());
      const doc = await vscode.workspace.openTextDocument({
        content: markdown,
        language: 'markdown',
      });
      await vscode.window.showTextDocument(doc);
    }
  );
  context.subscriptions.push(disposable);
}

function deactivate() {}

module.exports = { activate, deactivate };
```

The early generators of this idea (mine included) prefixed `# ` to *every* line, which turns a 200-line transcript into 200 headings and zero readable text. Match only the role lines. That regex is the difference between "exported Markdown" and "a wall of broken headers."

Because the transform is a plain function with no `vscode` import, you can run it outside the editor entirely. That's worth doing before you fight the F5 loop. Copy the `toMarkdown` function into `fmt.js`, add two lines to feed it a sample and print the result:

```javascript
const sample = [
  'bamr87: how do I read the active editor text?',
  'GitHub Copilot: Use vscode.window.activeTextEditor.document.getText().',
].join('\n');
console.log(toMarkdown(sample));
```

Then run it. I ran exactly this on this machine and got:

```console
$ node fmt.js
## You

how do I read the active editor text?
## Copilot

Use vscode.window.activeTextEditor.document.getText().
```

Two role lines became two headings; the questions and answers stayed as body text. That's real output — and it means when the command later misbehaves in the editor, you already know the transform isn't the problem.

Press F5 again, open a transcript in the dev-host window, and run **Copilot: Export Conversation as Markdown** from the palette. A new untitled Markdown tab opens with the reformatted text.

You'll know it worked when a new editor tab appears showing `## You` / `## Copilot` headings instead of raw `name:` lines.

## The part where it broke: the command nobody can run

Here's the failure I'm leaving in, because it's the one that costs you the afternoon and the error message is uselessly vague.

You change `extension.js` to register `copilotMdExport.toMarkdown`, but you forget to update `package.json`, which still declares the generator's old `copilot-md-export.helloWorld`. You hit F5, open the palette, type your title — and either it isn't there, or you run it and get:

```
command 'copilotMdExport.toMarkdown' not found
```

The two files have to agree. The string in `contributes.commands[].command` (package.json) and the first argument to `registerCommand` (extension.js) must be **byte-for-byte identical**. A dot vs. a hyphen, a stray capital, a typo — VS Code shows the command in the palette because `package.json` declares it, but clicking it fails because nothing in your code answered to that exact ID. Or you registered an ID that `package.json` never declared, so it never shows up at all.

The fix is to read both strings out loud and make them match:

- `package.json` → `"command": "copilotMdExport.toMarkdown"`
- `extension.js` → `registerCommand('copilotMdExport.toMarkdown', ...)`

Then **fully restart** the Extension Development Host (`Cmd+Shift+F5` or stop and re-F5) — a hot reload doesn't always re-read `package.json` changes, only code changes, which is its own afternoon. After a clean restart, the title appears in the palette and actually runs.

## When this goes wrong

A map from symptom to cause, all of these seen for real:

- **`yo: command not found`** — the global install didn't land or isn't on `PATH`. Re-run `npm install -g yo generator-code` and reopen your terminal.
- **F5 does nothing / no second window** — you opened the folder as a plain folder, not via `code .` from inside it, so there's no `.vscode/launch.json` in scope. Open the extension's own folder as the workspace root.
- **Command not in the palette** — `package.json` doesn't declare it, or the dev host is running stale code. Check the `contributes.commands` ID, then restart the host fully.
- **`command '...' not found` on click** — the IDs in `package.json` and `registerCommand` don't match. Make them identical.
- **Every line became a heading** — your transform is prefixing all lines instead of only role lines. Match the `name:` pattern.

That's the loop: `yo code`, F5, two files that agree on one string. The five-minute promise is honest right up until the IDs drift apart — and now that you've read this, that's a thirty-second fix instead of an afternoon.
