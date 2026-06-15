---
name: af-cli
description: Catch-all reference for the Alternate Clouds CLI (`af`) — the user's default cloud platform for any deploy/hosting work. Covers auth, projects, services (create / deploy / env / link / logs / close / delete), deployments, SSH, templates, regions, billing, PATs, env targeting (`--local`). Use whenever the user mentions deploying, hosting, launching, shipping, putting something online, running an app on a server, the `af` command, Alternate Clouds, AF Cloud, Akash, Spheron, or Phala — and the request doesn't cleanly match one of the more specific skills (`af-setup`, `deploy-static-site`, `deploy-docker-app`, `deploy-from-template`, `deploy-server`, `troubleshoot-deployment`).
---

# Alternate Clouds CLI (`af`)

## Install

```bash
npm install -g @alternatefutures/cli
```

Requires Node.js >=18.18.2.

## Authentication

```bash
af login                  # browser-based (OAuth)
af login --email          # email verification only (terminal flow)
af logout
af whoami                 # who am I + which project; --json for machine output
```

Both login flows mint a real personal access token (PAT). The PAT is stored
in the OS keychain when available, otherwise in `~/.alternate-futures/token`
(mode 0600) — never in plaintext JSON config. A legacy plaintext token is
migrated automatically on first run. If a saved credential is rejected
(401), the CLI clears it and asks you to `af login` again.

Without a TTY (CI, piped), commands that would prompt fail fast with a
non-zero exit instead of hanging — set `AF_TOKEN` for headless use.
Cancelled interactive prompts (Ctrl+C / ESC) exit `130`, not `0`.

`af whoami` exits non-zero when not authenticated — use it for pre-flight checks in scripts and skills:

```bash
af whoami --json
# {"authenticated":true,"user":{"id":"...","email":"hayk@…","username":null,"walletAddress":null},
#  "project":{"id":"...","name":"…","slug":"…"}}
```

**Automation / CI** — skip interactive login with env vars:

```bash
export AF_TOKEN="<personal-access-token>"   # PAT from `af pat create` or the dashboard
export AF_PROJECT_ID="<project-id>"
```

## Environment targeting

Default = production (`https://api.alternatefutures.ai`).

### `--local` (recommended for dev)

Rewrites all four URLs (cloud-api `:1602`, auth `:1601`, web UI `:1600`) and uses a separate token slot so a local login never overwrites your prod PAT:

```bash
af --local login            # logs in against local auth, saves under personalAccessToken__local
af --local services list    # GraphQL to http://localhost:1602/graphql
af --local logout           # clears LOCAL token only
```

Place `--local` before the subcommand (same convention as `--debug`).

### Env-var overrides

```bash
AF_API_URL=http://localhost:1602 af <cmd>      # cloud-api only
AUTH__API_URL=http://localhost:1601 af <cmd>   # auth service only
```

These don't split the token slot — prefer `--local` for local dev.

## Projects

```bash
af projects list
af projects create --name my-project
af projects switch [id-or-name]    # set active project
af projects update [id]
af projects delete [id]
```

## Services

Operate on the active project. Override with `-p <id-or-name>`:

```bash
af services list
af services -p my-project list
af services info [id-or-name-or-slug]
af services logs [id] --tail 100   # snapshot of recent lines — no --follow/stream mode
af services close [id]    # stop active deployment (Akash / Spheron / Phala)
af services delete [id]   # delete service (closes deployment first)
```

`[id]` accepts a service id, name, slug, or short id prefix. Omit to pick interactively.

### `services create` — full flag surface

```bash
af services create [options]
```

Top-level kind + per-kind source:

| Flag | Purpose |
|---|---|
| `--kind <k>` | `template` \| `docker` \| `server` (functions + GitHub deploys are dashboard-only) |
| `--name <name>` | Service name (validated against project's unique-slug constraint up-front) |
| `--template <id>` | (kind=template) skip the catalog browse |
| `--image <ref>` | (kind=docker) Docker image, e.g. `nginx:latest` |
| `--port <n>` | (kind=docker) container port, defaults to 80 under `-y` |
| `--os <base>` | (kind=server) base OS image, e.g. `ubuntu:24.04` |

Shared deploy-side flags (also accepted by `services deploy`):

| Flag | Purpose |
|---|---|
| `--confidential` | Phala TEE (verifiable compute). Otherwise Standard. |
| `--region <r>` | `us-east` \| `us-west` \| `eu` \| `asia`. Omit = "Any (cheapest globally)". |
| `--cpu <n>` | vCPUs |
| `--memory <s>` | e.g. `4Gi` |
| `--storage <s>` | e.g. `20Gi` |
| `--gpu` / `--no-gpu` | Attach a GPU (or skip even if template defaults to one) |
| `--gpu-model <m>` | e.g. `h100` (lowercase). Lists fetched live in interactive mode. |
| `--gpu-count <n>` | Number of GPUs |
| `--spend <mode>` | `payg` \| `budget` \| `stop` |
| `--budget-total <usd>` / `--budget-monthly <usd>` | spend caps |
| `--stop-hours <n>` / `--stop-days <n>` | auto-stop after duration |
| `--env KEY=VALUE` | required template env. Repeatable. |
| `-y, --yes` | Default everything unspecified + skip the final confirm |

`-y` defaults under non-interactive mode:
- spend → PAYG, mode → Standard, region → Any
- cpu/memory/storage → template defaults (or 1 vCPU / 2Gi / 20Gi if no template)
- gpu → off, UNLESS the template defaults to a GPU (then it's kept under `-y`; override with `--no-gpu`). Add `--gpu`/`--gpu-model` to force one on a non-GPU template.
- Server OS → `ubuntu:24.04`, Docker port → 80

Required template env vars under `-y` throw a clear error listing what's missing; pass each via `--env KEY=VALUE`.

### `services deploy` — redeploy an existing service

```bash
af services deploy [id] [--same flags as create]
```

Same prompt chain as create; closes any active deployment first (auto-confirms under `-y`). On Akash region soft-fail it surfaces 2–3 alternative regions with the exact retry command.

### `services env` — env var CRUD

```bash
af services env list [service]
af services env set <service> <key> <value> [--secret]   # --secret masks it in `list`
af services env unset <service> <key> [-y]
af services env reveal <service> <key>                    # print one var's plaintext (incl. secrets)
```

After any change, redeploy to apply: `af services deploy <service>`.

### `services link / unlink` — wire services together

```bash
af services link [source] [target] --alias DB    # target's connection info exposed to source as DB_*
af services unlink [source] [target] [-y]
```

Mirrors the web `ServiceLinker`. Redeploy the source service to materialize the new env keys.

### `services ports` — published ports

```bash
af services ports list [service]
af services ports add <service> <containerPort> [--public <n>] [--protocol tcp|http]
af services ports remove <service> <containerPort> [-y]
```

### `services health` — application health probe

```bash
af services health show [service]
af services health set <service> --path /healthz [--port <n>] [--expect 200] [--interval 30] [--timeout 5]
af services health disable <service> [-y]
```

### `services failover` — health-aware auto-failover

```bash
af services failover show [service]
af services failover enable <service> [--max-attempts 3] [--window-hours 24]
af services failover disable <service> [-y]
af services failover history [service]
```

Redeploys to a different provider on provider-side failure. Refused on services with persistent volumes (data-loss risk).

### `services config` — edit the persisted service record

```bash
af services config show [service]
af services config set <service> [--image <ref>] [--port <n>] [--priority <n>] \
  [--volume name:/mount/path:size ...] [--clear-volumes]
```

All four (`ports` / `health` / `failover` / `config`) mirror the web Config tab. Redeploy to apply changes.

## Provider routing (server-side — user doesn't pick)

- `--confidential` → Phala
- Standard + GPU → Spheron-first, Akash fallback on `NO_CAPACITY`
- Standard + no GPU → Akash directly (Spheron is GPU-only)
- Service has prior deployment → sticky to same provider while spec matches

## Deployments (cross-project view)

```bash
af deployments                  # active in current project
af deployments --all
af deployments --project <name>
af deployments --service <name>
af deployments --status ACTIVE
af deployments list --limit 20
```

## SSH

```bash
af ssh <serviceId>
af ssh <serviceId> --service web      # target specific container
af ssh <serviceId> --command /bin/sh  # custom shell
```

The remote PTY owns echoing; predictive local echo is off by default
(opt back in with `AF_SSH_LOCAL_ECHO=1` if you're on a high-latency link
and accept possible double-printing under raw-mode programs).

## Regions, templates, billing, PATs

```bash
af regions [--provider akash|phala] [--gpu h100|h200|a100|rtx4090]
af templates list
af templates info <templateId>
af billing balance        # wallet of the ACTIVE org (set at login / org switch)
af pat list
af pat create --name "CI token"
af pat delete <tokenId>
```

## Common non-interactive recipes

```bash
# Static Docker container on Akash, no GPU
af services create --kind docker --name web --image nginx:alpine --port 80 -y

# GPU workload (Spheron-first, Akash fallback)
af services create --kind docker --name infer --image my/llm:v1 --port 8080 \
  --gpu --gpu-model h100 --gpu-count 1 --region us-east -y

# Confidential TEE deploy from a template
af services create --kind template --template trusted-llm \
  --confidential --name secure-chat --env API_KEY=xxx -y

# Empty Ubuntu VM for SSH
af services create --kind server --name dev-box --os ubuntu:24.04 -y
af ssh dev-box
```

## Help

```bash
af help
af services help
af services create --help
```

## Exit codes

- `0` success
- `1` hard failure (auth, validation, server error)
- `2` Akash region soft-fail (`AWAITING_REGION_RESPONSE`) — surfaces alternative regions with retry commands
