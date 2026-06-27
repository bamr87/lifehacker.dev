---
title: "Your first React app with Vite: components, props, and a useState counter"
description: "Scaffold a React app with Vite, render JSX, manage state with useState, pass props between components, and decode the two errors everyone hits first."
date: 2025-11-24
collection: hacks
author: amr
excerpt: "Four commands to a running React app, a counter that actually counts, and the two error messages that will greet you on the way — with the real fix for each."
tags: [react, vite, javascript, frontend]
---

Every React tutorial promises to demystify the framework. Most of them spend nine paragraphs on the philosophy of declarative UI before you type a single command. This is the other kind: four commands to a running app, one counter that counts, and the two errors you will hit on the way — left in, because hitting them is the actual lesson.

You need Node installed (any current LTS). Check it first:

```bash
node -v
npm -v
```

If those print version numbers, you're set. If `node` is "command not found," install it from [nodejs.org](https://nodejs.org/) and come back. The versions on the machine we used for this piece:

```text
v25.6.0
11.8.0
```

## Scaffold the app with Vite

Forget the older `create-react-app`. The current default is **Vite** — it scaffolds the project, runs a fast dev server, and builds for production. This step downloads packages from npm, so it's not something we can run in an offline sandbox; we ran it on a real machine and pasted what it printed.

```bash
npm create vite@latest my-react-app -- --template react
cd my-react-app
npm install
npm run dev
```

The `--` before `--template react` is not a typo. It tells npm to stop reading flags for itself and pass the rest to the `create-vite` tool underneath. Drop it and npm tries to interpret `--template` as its own option, and you get a different project than you asked for.

The scaffold step prints this:

```text
◇  Scaffolding project in /…/my-react-app...
│
└  Done. Now run:

  cd my-react-app
  npm install
  npm run dev
```

And `npm run dev` prints the URL you actually care about:

```text
  VITE v8.1.0  ready in 434 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

You'll know it worked when [http://localhost:5173](http://localhost:5173) opens to the spinning Vite + React starter page. The dev server stays running and reloads the page every time you save a file — leave it open in one terminal tab and do your editing in another.

## What's actually in the folder

Three files matter; the rest is configuration you can ignore for now. After scaffolding, `ls src` shows:

```text
App.css
App.jsx
assets
index.css
main.jsx
```

- `index.html` (in the project root) — the single HTML page. It contains one line that matters: `<div id="root"></div>`.
- `src/main.jsx` — the entry point. It finds that `root` div and mounts your app into it.
- `src/App.jsx` — the component you see in the browser. This is the file you'll edit.

Open `src/main.jsx`. This is the real content the current scaffold generates — note the named imports, not a default `React` import:

```jsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

That's the whole bridge between React and the page: `createRoot(document.getElementById('root'))` grabs the `root` div, and `.render(<App />)` draws your `App` component inside it. (Older tutorials show `import ReactDOM from "react-dom/client"` and `ReactDOM.createRoot(...)`. That still works, but it's not what Vite writes anymore — if you copy-paste an old guide's `main.jsx` over the new one, you'll just be using a more verbose spelling of the same thing.)

## Your first component

Replace the entire contents of `src/App.jsx` with this:

```jsx
function App() {
  return (
    <div>
      <h1>Your first React component</h1>
      <p>If you can read this, it rendered.</p>
    </div>
  );
}

export default App;
```

Save. You'll know it worked when the browser refreshes on its own and shows your heading and paragraph — no manual reload.

That `return` block looks like HTML but it's **JSX**: HTML-like syntax that compiles down to JavaScript. Two differences will bite you early:

- Write `className`, not `class` (`class` is a reserved word in JavaScript).
- Drop a `{}` anywhere you want to insert a JavaScript value.

```jsx
const name = "Ada";

function Greeting() {
  return <p>Hello, {name}!</p>;
}
```

The `{name}` is not a string — it's a hole where React drops the value of the `name` variable. Render that and you get "Hello, Ada!".

## Make it do something: useState

Static text is the boring 90% of any tutorial. The reason React exists is the other 10% — UI that changes when the user does something. The smallest honest example is a counter. Replace `src/App.jsx` again:

```jsx
import { useState } from "react";

function App() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <h1>React Counter</h1>
      <p>Current count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}

export default App;
```

Three things, no more:

- `useState(0)` creates a piece of state called `count`, starting at `0`.
- `setCount` is the only legal way to change it. You never write `count = count + 1` directly — React won't notice.
- Clicking the button calls `setCount(count + 1)`. React updates `count`, re-runs the component, and the `{count}` on the page changes.

You'll know it worked when clicking **Increment** ticks the number up and the page never reloads. If the number doesn't move, you almost certainly reassigned `count` by hand somewhere instead of calling `setCount` — that's the most common silent failure with state.

## Split it into components and pass props

One file is fine until it isn't. The moment you want two of something, you pull it into its own component and pass it data through **props**. Make `src/Counter.jsx`:

```jsx
import { useState } from "react";

function Counter({ label }) {
  const [value, setValue] = useState(0);

  return (
    <div>
      <h2>{label}</h2>
      <p>Value: {value}</p>
      <button onClick={() => setValue(value + 1)}>+1</button>
    </div>
  );
}

export default Counter;
```

The `{ label }` in the function signature is the prop — the parent hands it in. Now wire up two of them from `src/App.jsx`:

```jsx
import Counter from "./Counter.jsx";

function App() {
  return (
    <div>
      <h1>React Components</h1>
      <Counter label="First counter" />
      <Counter label="Second counter" />
    </div>
  );
}

export default App;
```

The payoff is in the behavior: click the first counter and the second one stays put. Same component, same code, but each `<Counter />` keeps its own private `value` state. That isolation is the whole reason to break UI into components.

To confirm the whole thing is correct (not just rendering, but compilable), run a production build:

```bash
npm run build
```

We ran it; this is the real output:

```text
> vite build

vite v8.1.0 building client environment for production...
✓ 17 modules transformed.
dist/index.html                   0.46 kB │ gzip:  0.29 kB
dist/assets/index-nqMpL4T3.css    1.78 kB │ gzip:  0.81 kB
dist/assets/index-BVO41b6l.js   190.78 kB │ gzip: 60.10 kB

✓ built in 324ms
```

You'll know it worked when you see `✓ built` and three files in `dist/`. A 190 kB JS bundle for a counter sounds like a lot — that's React itself; it barely grows as your app does.

## The part where it broke

Two errors greet nearly everyone in their first hour. Here they are with the real messages, because recognizing them is faster than re-reading the docs.

**Blank page, nothing in the terminal.** The dev server is green, the browser is white. Open the browser console (right-click → Inspect → Console). Nine times out of ten it's that `main.jsx` is rendering into an element that doesn't exist — the `id="root"` div is missing or renamed in `index.html`. React can't mount into thin air, and it tells you so only in the browser console, never in the terminal.

**Two things side by side.** This one is a guaranteed rite of passage. You try to return two sibling elements:

```jsx
function App() {
  return (
    <h1>React Counter</h1>
    <p>Current count: {count}</p>
  );
}
```

We built exactly that. The real error:

```text
[builtin:vite-transform] Adjacent JSX elements must be wrapped in an enclosing tag.
   ╭─[ src/App.jsx:8:5 ]
 8 │     <p>Current count: {count}</p>
   │ 
   │ Help: Did you want a JSX fragment `<>...</>`?
```

A component can only return **one** element. Two top-level tags is a syntax error, and Vite even hands you the fix in the "Help:" line. Wrap the siblings — either in a real `<div>`, or in a **fragment** (`<>...</>`) when you don't want an extra wrapper element in the DOM:

```jsx
function App() {
  return (
    <>
      <h1>React Counter</h1>
      <p>Current count: {count}</p>
    </>
  );
}
```

Save, and the error clears on the next reload. Read these messages instead of pasting them straight into a search box — React's errors are unusually specific, and the "Did you want a fragment?" hint is the answer, not a clue.

## The honest accounting

This does not make you a React developer. It gets you a running app, a component, a prop, and a piece of state — the four things every larger React app is just more of.

What's genuinely worth doing next, in order: render a list with `.map()`, fetch real data with `useEffect`, then add routing only when you actually have a second page. Skip the state-management libraries until the day a `useState` you're passing four levels deep makes you angry. That day tells you what to learn next far better than any roadmap.
