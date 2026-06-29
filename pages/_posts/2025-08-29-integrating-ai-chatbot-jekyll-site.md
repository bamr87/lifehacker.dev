---
title: "Bolting an AI Chatbot onto a Jekyll Site: A Build-Log"
description: "A field note on wiring a custom AI chat widget into a static Jekyll site: the HTML/JS/SCSS, the serverless key-hider, and the steps I couldn't run."
date: 2025-08-29
categories: [Field Notes]
tags: [jekyll, chatbot, openai, serverless, javascript, static-sites]
author: amr
excerpt: "A static site has no backend. So I tried to give one a brain, and ran straight into the part where the brain lives somewhere I can't test."
---

A static site is fast, cheap, and has no server doing anything at request time. That last part is the whole point — until you decide it should answer questions, at which moment "no server" stops being a feature and starts being a problem you have to rent from someone.

This is the build-log for bolting a custom AI chat widget onto a Jekyll site. Not a third-party bubble you paste in and forget — a hand-rolled widget that talks to OpenAI through a serverless function so the API key never ships to the browser. The front-end code is real and runs locally. The back half — the API key, the serverless deploy — lives in a cloud I can't spin up on a plain dev box, so I did not run it, and I'm going to say so out loud every time we cross that line instead of pretending the curl came back 200.

## What I could test, and what I couldn't

Let me draw the line up front, because the honest version of this post is mostly about where the line is.

```text
[ runs on my laptop ]              [ does NOT run on my laptop ]

browser widget ──▶ fetch('/api/chat') ──▶ serverless fn ──▶ OpenAI API
HTML / SCSS / JS                          needs a cloud      needs a key
Jekyll include + plugin                   + a deploy         + a bill
```

Everything left of the arrow I built and rendered. Everything right of it needs a Netlify/Vercel account, an `OPENAI_API_KEY`, and a `git push` to a host I'm not standing up for a blog post. So the widget below is genuine and the serverless function is genuine code — but I have **not** executed the function, deployed it, or watched a real model reply. Where that matters, you'll see a flag.

## Why not just paste the third-party bubble

You can. It's three lines and it works:

```javascript
window.$crisp = [];
window.CRISP_WEBSITE_ID = "your-website-id";
(function () {
  const d = document, s = d.createElement("script");
  s.src = "https://client.crisp.chat/l.js";
  s.async = 1;
  d.getElementsByTagName("head")[0].appendChild(s);
})();
```

If that's what you need, take it and go — you don't need the rest of this post. The reason I didn't is control: I wanted the widget to read the page it's sitting on, feed that context to the model, and never expose a key. That means owning the front-end and renting only the part that holds the secret.

## The widget: HTML you can render today

This is a Jekyll include, gated behind a config flag so it only appears when you turn it on. It renders fine locally — no key required to draw a box.

```html
{% raw %}<!-- _includes/chatbot.html -->
{% if site.data.chatbot_config.chatbot.enabled %}
<div id="ai-chatbot-container" class="chatbot-container">
  <button id="chatbot-toggle" class="chatbot-toggle" aria-label="Open AI assistant">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
    </svg>
  </button>

  <div id="chatbot-widget" class="chatbot-widget" role="dialog"
       aria-labelledby="chatbot-title" aria-hidden="true">
    <div class="chatbot-header">
      <h3 id="chatbot-title">Ask the site</h3>
      <button id="chatbot-close" class="chatbot-close" aria-label="Close chat">&times;</button>
    </div>

    <div id="chatbot-messages" class="chatbot-messages" role="log" aria-live="polite">
      <div class="message bot-message">
        <div class="message-content"><p>Hi. Ask me about anything on this site.</p></div>
      </div>
    </div>

    <form id="chatbot-form" class="chatbot-input-form">
      <label for="chatbot-input" class="sr-only">Ask a question</label>
      <input type="text" id="chatbot-input" class="chatbot-input"
             placeholder="Ask me anything…" autocomplete="off" maxlength="500">
      <button type="submit" class="chatbot-send" aria-label="Send message">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
          <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
        </svg>
      </button>
    </form>

    <div class="chatbot-status" id="chatbot-status" aria-live="polite"></div>
  </div>
</div>
{% endif %}{% endraw %}

```

The `aria-*` attributes aren't decoration. A chat box that a screen reader can't follow is a chat box that excludes the people most likely to need help, so the messages region is a `role="log"` with `aria-live="polite"` and every control is labelled. You'll know the markup is right when you tab through it with your eyes shut and can still tell where you are.

The flag it's gated on lives in a data file:

```yaml
# _data/chatbot_config.yml
chatbot:
  enabled: true
  api_endpoint: "/api/chat"
  fallback_responses:
    - "I'm still learning about that. Try the docs?"
    - "Good question — have you checked the latest posts?"
```

## The SCSS, trimmed to the part that bites

The original styling I started from was ~350 lines. Most of it is unremarkable — gradients, a slide-in keyframe, a typing dot. I'll spare you the bulk and keep the two rules that actually matter, because they're the ones I'd have skipped and regretted.

First, full-screen on mobile. A 350px floating panel on a phone is a panel that covers nothing and obscures everything:

```scss
.chatbot-widget {
  position: absolute;
  bottom: 80px;
  right: 0;
  width: 350px;
  height: 500px;
  display: none;

  &.active { display: flex; }

  @media (max-width: 768px) {
    position: fixed;
    inset: 0;          // top/right/bottom/left: 0
    width: 100%;
    height: 100%;
    border-radius: 0;
  }
}
```

Second, scope your styles or the theme will eat them. The widget inherits the host site's `line-height`, `font-family`, and box model unless you wall it off:

```scss
.chatbot-container {
  --chatbot-primary: #4f46e5;
  * { box-sizing: border-box; }      // don't trust the theme's reset
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  line-height: 1.5;
}
```

I'm flagging this from experience, not from this build: every time I've dropped a widget into a themed site, the first render looked broken because the theme's `* { margin: 0 }` or its `line-height: 1.8` leaked in. Scope first, debug never.

## The JavaScript: the front-end is the easy half

The widget class is long but boring in the good way — open/close, append a message, scroll to bottom, post to an endpoint. Here's the spine of it, cut down to the parts that carry weight. This runs locally; it just gets a network error instead of an answer, because there's nothing on the other end of `/api/chat` on my laptop.

```javascript
// assets/js/chatbot.js
class SiteChatbot {
  constructor(config = {}) {
    this.endpoint = config.apiEndpoint || "/api/chat";
    this.history = [];
    this.loading = false;
    this.context = this.readPage();          // feed the model the page it's on
    document.addEventListener("DOMContentLoaded", () => this.wire());
  }

  // Scrape just enough of the current page to give the model context.
  readPage() {
    const meta = (n) =>
      document.querySelector(`meta[name="${n}"]`)?.getAttribute("content") ?? null;
    return {
      url: location.pathname,
      title: document.title,
      description: meta("description"),
      headings: [...document.querySelectorAll("h1,h2,h3")]
        .map((h) => h.textContent.trim()).slice(0, 10),
    };
  }

  async send(message) {
    this.history.push({ role: "user", content: message });
    const res = await fetch(this.endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        messages: this.history.slice(-10),
        site_context: this.context,         // the server folds this into the prompt
      }),
    });
    if (!res.ok) throw new Error(`API ${res.status} ${res.statusText}`);
    const data = await res.json();
    const reply = data.message ?? data.choices?.[0]?.message?.content;
    this.history.push({ role: "assistant", content: reply });
    return reply;
  }

  // Map ugly errors to human ones. This is the only output I can vouch for,
  // because it's the path that fires when the backend isn't there.
  errorText(err) {
    if (err.message.includes("Failed to fetch"))
      return "Can't reach the assistant. Check your connection.";
    if (err.message.includes("429")) return "Too many requests — give it a sec.";
    if (err.message.includes("401")) return "Auth failed. Refresh and retry.";
    return "Something broke. Try again.";
  }
}
```

Notice what `readPage()` does: it scrapes the title, description, and first ten headings off the live DOM and ships them to the server as `site_context`. That's the trick that makes the bot feel like it knows where you are — it's not trained on your site, it's just handed a paragraph about the current page on every request. Cheap, effective, and entirely client-side, so I can confirm it produces a sane object: open the console, instantiate the class, log `this.context`, see your headings. That part I checked.

One thing I did **not** keep from the source I started with: it stuffed the OpenAI API key into the front-end config (`config.apiKey`, sent as a `Bearer` header from the browser). Do not do this. A key in client JavaScript is a key in everyone's DevTools, and a key in everyone's DevTools is a charge on your card. The whole reason the next section exists is to keep the key off the wire.

## The backend I did NOT run

Here's where I stop being able to vouch for anything. The front-end POSTs to `/api/chat`. On a real deploy, that's a serverless function holding the key. This is the code; I have **not** deployed or executed it, because doing so needs a Netlify/Vercel account, a funded `OPENAI_API_KEY`, and a `git push` to a live host — none of which a dev box has, and none of which I'm going to fake the output of.

```javascript
// netlify/functions/chat.js  (or api/chat.js on Vercel)
// NOT EXECUTED HERE — needs OPENAI_API_KEY + a cloud deploy.
const OpenAI = require("openai");
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

exports.handler = async (event) => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json",
  };
  if (event.httpMethod === "OPTIONS") return { statusCode: 200, headers, body: "" };
  if (event.httpMethod !== "POST")
    return { statusCode: 405, headers, body: JSON.stringify({ error: "Method not allowed" }) };

  try {
    const { messages, site_context } = JSON.parse(event.body);

    // Fold the page context into the system message before it hits the model.
    const system = {
      role: "system",
      content: `You are an assistant embedded on a website.
Current page: ${site_context?.title} (${site_context?.url})
Headings: ${site_context?.headings?.join(", ") || "none"}
Answer in under 200 words. Say so when you don't know.`,
    };

    const completion = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [system, ...messages],
      max_tokens: 500,
      temperature: 0.7,
    });

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ message: completion.choices[0].message.content }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Upstream error" }),
    };
  }
};
```

I can read this and tell you the shape is right — CORS preamble, method guard, key from `process.env`, context folded into the system prompt, errors caught so you return JSON instead of a stack trace. What I **cannot** tell you is that it returns a 200, what a real reply looks like, or how the latency feels, because I never ran it. If I printed a sample model response here it would be fiction, so I'm not going to. When you deploy this, the things to actually verify are: the function reads `OPENAI_API_KEY` from the host's environment (not a committed file), the CORS origin is locked to your domain and not `*` in production, and the browser's Network tab shows the request going to `/api/chat` and never to `api.openai.com`.

## The Jekyll plugin, also not exercised end-to-end

There's an optional Ruby plugin that runs at build time to hand the widget a knowledge base — a JSON list of your posts, so the bot can suggest "see also" links. It's a `post_write` hook that writes a JS file into the built site.

```ruby
{% raw %}# _plugins/chatbot_config.rb
Jekyll::Hooks.register :site, :post_write do |site|
  kb = site.posts.docs.sort_by { |p| p.date }.reverse.first(50).map do |post|
    {
      "title" => post.data["title"],
      "url"   => post.url,
      "tags"  => post.data["tags"] || [],
    }
  end
  config = { "knowledge_base" => kb }
  File.write(File.join(site.dest, "assets/js/chatbot-config.js"),
             "window.chatbotConfig = #{config.to_json};")
end{% endraw %}
```

I'm being honest about this one too: custom `_plugins/` only run on a self-hosted Jekyll build (`github-pages` disables them, and a remote-theme/Docker-CI build is its own can of worms), and I didn't stand up that full pipeline to watch the file land. The Ruby is straightforward and I'd expect it to work, but "I'd expect it to work" is exactly the phrase this post exists to flag. If you wire it in, the tell is a `assets/js/chatbot-config.js` file in your `_site/` after a build, containing a `window.chatbotConfig` object with your latest posts in it. No file, no knowledge base.

## What this build actually taught me

- **The hard part of a static-site chatbot isn't the chat.** The widget is an afternoon. The architecture decision — where does the key live — is the whole game, and the answer is "anywhere but the browser."
- **Context beats training.** You don't fine-tune a model on your blog. You scrape the current page into a paragraph and hand it over on every request. The source I started from already knew this; it was the one genuinely good idea in it.
- **A dev box can prove the front-end and only assert the back-end.** I can render the widget, log the scraped context, and watch the error path fire when `/api/chat` 404s. I cannot prove the model replies without a key and a deploy — so I didn't claim to.

If you want a version of this you can fully test on a laptop, that's a different post: point the widget at a local mock server that returns canned JSON, and you can exercise everything left of the cloud arrow with no key and no bill. I may write that one, because it's the half I can actually stand behind.

And no — before anyone reaches for it — this is not a *"seamless, AI-powered"* anything. It's a `<div>`, a `fetch`, and a serverless function I described honestly instead of pretending I deployed.
