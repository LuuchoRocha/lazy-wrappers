---
layout: page
title: Why
---

# Why lazy-wrappers exists

You open a new terminal. The UI appears, but the shell is still busy. Your next command is just `git status`, yet you're waiting for startup scripts to finish.

Version managers like `nvm` and `rbenv` are a common cause of that delay. They are useful, but they also do real work on every shell start: loading scripts, checking paths, enabling shims, and preparing hooks.

## The problem

- Version managers load for every shell session.
- Many sessions never use Node or Ruby.

Most terminal time goes to navigating repos, inspecting changes, searching, and monitoring—not running runtimes. Yet every new shell pays the same initialization cost.

## The fix

> Load version managers only when actually needed.

Shell starts fast. When you run `node`, `npm`, `ruby`, `bundle`, or another wrapped command, the version manager loads at that moment—then switches to direct execution for the rest of the session.

## Is this safe?

Yes. Same principle as deferring any expensive initialization that isn't always required.

The design is conservative:

- Wrappers exist only until the first real runtime command is invoked.
- After loading, wrapper paths are removed from `PATH`.
- Subsequent commands run as they would in a traditional setup.

lazy-wrappers does not replace `nvm` or `rbenv`. It keeps them as the source of truth and only changes when their initialization cost is paid.

## Who benefits most

You will likely notice the biggest benefit if you:

- open many terminal tabs/windows during the day
- use VS Code’s integrated terminal frequently
- switch contexts often (projects, repos, tasks)
- want fast “utility shells” for quick commands

If you keep one long-lived terminal session and always need Node/Ruby immediately, the benefit may be smaller. In that case, traditional initialization may already feel acceptable.
