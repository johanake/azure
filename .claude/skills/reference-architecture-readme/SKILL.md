---
name: reference-architecture-readme
description: Ensures every reference architecture in this repo has a README that explains what it is and how to apply it. Use whenever creating, adding, renaming or substantially changing anything under reference-architectures/ (new architecture, new module, new deployment step, changed parameters), and when asked to write or review a reference architecture README.
---

# Reference architecture README

This repo is a collection of Azure reference architectures that accompany
blog posts. Every folder `reference-architectures/<name>/` **must** contain a
`README.md` that lets a reader who has never seen the code:

1. understand what the architecture is, and whether it fits their situation, and
2. deploy it, adapt it to their own environment and remove it again.

A change to an architecture isn't finished until its README matches the code.

## When this applies

- **New architecture:** create the README from [template.md](template.md) in
  the same change as the code, and add a row to the index table in the root
  `README.md`.
- **Changed architecture:** update the README sections that the change touches
  (deploy steps, parameters, prerequisites, cost, clean-up, layout).
- **Review:** check the README against the checklist below and fix gaps.

## Required sections, in this order

| Section | What it must answer |
|---|---|
| Title + summary | One or two sentences: what it builds and the problem it solves. |
| Blog post | Link to the post. If it isn't published yet, write `_Blog post coming soon._`, never a fake URL. |
| Architecture | A diagram (ASCII tree or Mermaid) of what gets deployed and how the pieces relate, with each piece mapped to the folder that deploys it. |
| When to use it | Who it's for, when it fits, when it doesn't, and what to use instead. |
| What gets deployed | Table of each resource, its scope (tenant / management group / subscription / resource group) and why it's there. |
| Prerequisites | Tools with minimum versions, Azure roles at each scope, licensing or billing requirements (for example MCA/EA for subscription creation). |
| Deploy | Numbered, copy-pasteable steps run from the architecture folder, in dependency order, each saying what it does and which permissions it needs. Mention `what-if`. |
| Configuration | Every parameter and environment variable a user must or may set, with its default and effect. Values that identify a real account (subscription/tenant IDs, billing scopes) go in the gitignored `.env`; the README points to `.env.example`. |
| Adapting it | Concrete ways to fit it to your own environment: renaming, adding instances (for example another workload), extending it, going toward production. |
| Cost | What costs money, what's free, and what caps or settings limit spend. Describe the cost drivers; don't quote exact prices, since they change and vary by region. |
| Clean up | Commands to remove everything in the correct order, plus anything that can't be removed from code (for example cancelling a subscription) and soft-delete gotchas. |
| Layout | Folder tree with a one-line purpose per file or folder. |

Optional sections go after Layout, for example "Bicep concepts shown" for
teaching-oriented architectures.

## Rules

- **Self-contained:** paths and commands are relative to the architecture
  folder, and the README never depends on another architecture's files.
  Readers often copy just one folder.
- **No real identifiers:** use placeholders like `<tenant-id>` and
  `<subscription-id>`. Never paste values from `.env` or deployment output.
  The gitleaks pre-commit hook will block subscription IDs and billing scopes.
- **Match the code:** parameter names, defaults, folder names and deploy
  commands must match the files exactly. After writing, grep the code for
  every parameter and path the README mentions.
- **Explain why, not only how:** each deploy step and each design choice gets
  one line of reasoning. The reader came from a blog post to learn.
- **Plain, short sentences.** Define a term (management group, landing zone)
  the first time it appears.

## Checklist before finishing

- [ ] Every required section is present, in order.
- [ ] Each deploy step lists its required role and scope.
- [ ] Every parameter in each `.bicepparam` file and every variable in
      `.env.example` is documented.
- [ ] Clean-up removes everything that deploy creates.
- [ ] No real IDs, tenant names or billing details anywhere.
- [ ] The root `README.md` index table lists the architecture.
