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

To target a **local dev** backend:

```bash
AF_API_URL=http://localhost:1602 af <command>
```

The `AF_API_URL` prefix overrides for that single invocation. Port 1602 is `service-cloud-api`.

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
af services close [id]                # Close active deployment
af services delete [id]               # Delete service (closes deployment first)
```

The `[id]` argument accepts a service **ID**, **name**, or **slug**. If omitted, an interactive picker is shown.

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
