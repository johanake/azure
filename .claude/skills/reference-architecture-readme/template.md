# <Architecture name>

<One or two sentences: what this builds and the problem it solves.>

_Blog post coming soon._ <!-- replace with: 📝 Read the blog post: [<title>](<url>) -->

## Architecture

```
<diagram: what gets deployed, how it relates, and which folder deploys each part>
```

<Short explanation of the key ideas and terms in the diagram.>

## When to use it

- **Use it when:** <situations it fits>
- **Don't use it when:** <situations it doesn't fit>, and use <alternative> instead.

## What gets deployed

| Resource | Scope | Why |
|---|---|---|
| <resource> | <tenant / management group / subscription / resource group> | <purpose> |

## Prerequisites

- <tool> <minimum version>
- <role> at <scope> (needed for step <n>)
- <licensing or billing requirement>

## Deploy

Run every command from this folder.

```bash
cd reference-architectures/<name>
```

1. **<Step name>** (needs <role> at <scope>). <Why this step exists.>

   ```bash
   <command>
   ```

Preview any step by replacing `create` with `what-if`.

## Configuration

| Parameter / variable | File | Default | Effect |
|---|---|---|---|
| `<name>` | `<file>` | `<default>` | <effect> |

## Adapting it

- **<Change>:** <how to do it, which files to edit>

## Cost

- **Free:** <items>
- **Billed:** <items and what drives the cost>
- **Limits in place:** <caps and settings that bound spend>

## Clean up

Remove resources in this order:

```bash
<commands>
```

<Anything that can't be removed from code, and soft-delete gotchas.>

## Layout

```
<name>/
├── <file or folder>    <purpose>
```
