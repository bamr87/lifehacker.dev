---
title: "A CMS in Python and JavaScript: What ChatGPT's Build Plan Actually Gives You"
description: "An old ChatGPT outline for a Python/JavaScript CMS, reproduced verbatim and read honestly: a clean roadmap with no code, nothing run, nothing verified."
date: 2023-12-14
categories: [Field Notes]
tags: [ai, engineering]
author: amr
excerpt: "I asked a chatbot how to build a CMS. It gave me eleven confident steps and zero lines of code. Here is the whole plan, plus the part nobody ran."
preview: /images/previews/a-cms-in-python-and-javascript-what-chatgpt-s-buil.png
---
Back in late 2023 I typed one sentence at ChatGPT: *I want to build a CMS application in Python as the backend and JavaScript to render the front end.* What came back was a tidy, eleven-step build plan that I saved and never executed.

I am keeping it as a Field Note, because it is a clean specimen of a thing that happens constantly now and rarely gets labeled: a roadmap that reads like a procedure but has never touched a terminal.

So, the framing up front, before the list seduces anyone: **what follows is an AI-generated outline, not a tested procedure.** None of these steps were run. There is no code below — there was no code in the answer either. It is a conceptual plan, reproduced as-is, and then a few honest notes about where a plan like this quietly skips the hard parts.

## The plan, verbatim

This is the answer as it arrived, condensed only by dropping the chat pleasantries. The words are the model's, not mine.

1. **Define the requirements.** Decide what the CMS needs: user authentication, content creation, editing and publishing, and support for different content types (articles, images, videos).
2. **Set up the backend in Python.** Pick a web framework like Django or Flask, install it, start a new project.
3. **Design the database schema.** Identify the models — users, content types, content items, categories, tags — define the relationships, create the tables.
4. **Implement user authentication.** Use the framework's built-in auth for registration, login, and session management.
5. **Create APIs for the frontend.** Build endpoints that take requests, read or write the database, and return JSON.
6. **Set up the frontend in JavaScript.** Choose React, Vue, or Angular; install the dependencies; start a project.
7. **Design the UI.** Build the components and layouts — forms for creating and editing, views for displaying content, navigation.
8. **Wire frontend to backend.** Use `fetch` or Axios to call the APIs, and handle the responses.
9. **Implement frontend behavior.** Handle form submissions, editing, publishing; manage state and routing.
10. **Test and debug.** Write backend tests with pytest or Django's tools, frontend tests with Cypress or Jest.
11. **Deploy.** Ship it to a host that runs Python and serves the frontend files.

And the closing note, also verbatim: *follow best practices for security, performance, and scalability throughout, and keep your dependencies updated.*

That is the entire artifact. Read it again and notice what your brain does — it nods. Each step is correct in isolation. The nodding is the trap.

## What did not happen here

I want to be exact about the receipts on this one, because the whole point of a Field Note is the verified after-state, and this post does not have one.

- **Nothing in the list was run.** I did not `django-admin startproject`. I did not `npm create vite`. There is no repo behind this post, no schema, no passing test suite. I cannot show you command output because I did not generate any.
- **There is no screenshot,** because there is no running app to capture. A real, embedded shot of a styled CMS dashboard would be a fabrication, and the rule here is that I do not paste pictures of things that don't exist.
- **The plan was never re-tested in this environment.** Even if I wanted to, a full Python-plus-JS CMS with a database and a deploy target is not something a plain dev box runs end to end in one sitting. So I am not pretending it was.

If you want a working procedure, this is not it. This is the map someone drew before the expedition, and the expedition's status is "never departed."

## Where a plan like this skips the hard part

The reason I keep this around is that the gap between *plan* and *procedure* is exactly the gap that costs the weekends. The outline is right about the shape and silent about every place the shape gets sharp:

- **"Implement user authentication" is one bullet and roughly half the project.** Sessions versus tokens, password resets, CSRF on the API, who can edit whose content — none of that fits in step four. It just sits there looking finished.
- **"Create APIs for the frontend" hides the contract.** The plan never says what the JSON looks like, how errors come back, or how pagination works. That contract is the thing your React code and your Django code will fight about for a week.
- **"Test and debug" is the step everyone deletes from their own plan.** It is listed tenth, which is roughly when energy runs out. A plan that lists testing late is a plan that is describing how projects actually skip it.
- **"Deploy" is a single word covering static files, a WSGI server, a database that survives restarts, and secrets that are not in the repo.** Each of those is its own bad evening.

This is not a knock on the model. The answer is genuinely a fine starting outline — better than the blank page I started from. It is a knock on reading any such outline as if it were tested. It compiles in your head; that is not the same as it running on a machine.

## The honest verdict

As a tested procedure, this post has nothing to offer, and I will not dress it up as if it does. As a specimen, it is useful: this is what "the AI told me how to build it" looks like when you strip out the part where you nod along.

The list is real, reproduced exactly, and worth thirty seconds as a checklist of *areas to plan for*. Hold it at the right distance, though. It is a roadmap a language model drew in 2023, not a thing I built, ran, or verified — and the moment a plan starts feeling like progress is the moment to go open a terminal and find out which of these eleven confident steps was lying.
