---
name: af-cli
description: Use the AlternateFutures CLI (`af`) to manage cloud infrastructure. Covers authentication, projects, services, deployments, SSH, billing, and personal access tokens. Use when the user asks about deploying, managing services, shell access, or any `af` command.
---

# AlternateFutures CLI (`af`)

## Install

```bash
npm install -g @alternatefutures/cli
```

Requires Node.js >=18.18.2.

## Authentication

```bash
af login                  # Opens browser for OAuth
af login --email          # Email-based verification (no browser)
af logout
```

**Automation / CI** — skip interactive login with env vars:

```bash
export AF_TOKEN="<personal-access-token>"
export AF_PROJECT_ID="<project-id>"
```

Create tokens in the dashboard or via `af pat create --name "CI"`.

## Environment Targeting

By default the CLI talks to **production** (`https://api.alternatefutures.ai`).

### `--local` (recommended)

The cleanest way to point at a local dev backend is the global `--local` flag. It rewrites all four URLs (cloud-api `:1602`, auth `:1601`, web UI `:1600`) **and** uses a separate token slot so a local login NEVER overwrites your prod PAT.

```bash
af --local login              # logs you in against local auth, saves token under personalAccessToken__local
af --local ssh <serviceId>    # WS to ws://localhost:1602/ws/shell with local token
af --local services list      # GraphQL to http://localhost:1602/graphql
af --local logout             # clears LOCAL token only, prod is untouched
```

`af logout` (no flag) clears the prod token only. The two profiles are fully independent.

Place `--local` **before** the subcommand (`af --local <cmd>`) — same convention as `--debug`.

### Env-var overrides (power users / CI)

```bash
AF_API_URL=http://localhost:1602 af <command>      # cloud-api only
AUTH__API_URL=http://localhost:1601 af <command>   # auth service only
```

These still work but DO NOT split the token slot — a login flow triggered while these are set will overwrite whatever PAT is currently saved. Prefer `--local` for local dev.

## Projects

```bash
af projects list
af projects create --name my-project
af projects switch [id-or-name]      # Set active project context
af projects update [id]
af projects delete [id]
```

## Services

All service commands operate on the **active project** (set via `af projects switch`).
Use `-p <id-or-name>` to target a different project:

```bash
af services list
af services -p "my-project" list
af services info [id-or-name-or-slug]
af services create                    # Interactive template picker
af services deploy [id]               # Deploy or redeploy
af services logs [id] --tail 100
af services close [id]                # Close active deployment (Akash / Spheron / Phala)
af services delete [id]               # Delete service (closes deployment first)
```

The `[id]` argument accepts a service **ID**, **name**, or **slug**. If omitted, an interactive picker is shown.

For Spheron deploys (Standard mode auto-routed), `af services info` adds GPU / region / Spheron-provider rows; `af services close` warns when the VM is < 20 min old (Spheron's server-side minimum-runtime contract still bills until the floor lifts). `af services deploy` itself is currently Akash-only — Standard auto-routing for fresh CLI deploys is web-only today; existing Spheron deployments are managed end-to-end via the CLI.

## Deployments

```bash
af deployments                        # Active deployments (current project)
af deployments --all                  # Include closed/old
af deployments --project <name>       # Filter by project
af deployments --service <name>       # Filter by service
af deployments --status ACTIVE        # Filter by status
af deployments list --limit 20
```

## SSH / Shell Access

```bash
af ssh <serviceId>
af ssh <serviceId> --service web      # Target specific container
af ssh <serviceId> --command /bin/sh  # Custom shell
```

Requires an active Akash deployment on the service.

## Billing

```bash
af billing balance
```

## Templates

```bash
af templates list
af templates info <templateId>
```

## Personal Access Tokens

```bash
af pat list
af pat create --name "CI token"
af pat delete <tokenId>
```

## Common Workflows

**First-time setup:**

```bash
af login
af projects create --name my-app
af services create          # Pick a template, configure, deploy
```

**Redeploy an existing service:**

```bash
af services deploy my-service
```

If a deployment is running, the CLI prompts to close it first, then deploys fresh.
The deploy command shows **real-time step-by-step progress** (creating tx → waiting bids → creating lease → sending manifest → container starting → live). It polls the backend every 3 seconds and exits when the deployment reaches a terminal state (ACTIVE, FAILED, CLOSED). On success it prints provider info and service URLs.

**Check what's running:**

```bash
af services list
af deployments --all
```

**SSH into a running service:**

```bash
af ssh <serviceId>
```

**Scripted / CI deploy (non-interactive):**

```bash
export AF_TOKEN="pat_..."
export AF_PROJECT_ID="cmn..."
af services deploy my-service
```

## Help

```bash
af help
af services help
af services deploy --help
```
