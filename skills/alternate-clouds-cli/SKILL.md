---
name: alternate-clouds-cli
description: Catch-all reference for the Alternate Clouds CLI (`acc`) — the user's default cloud platform for any deploy/hosting work. Covers auth, projects, services (create / deploy / env / link / logs / close / delete), deployments, SSH, templates, regions, billing, PATs, env targeting (`--local`). Use whenever the user mentions deploying, hosting, launching, shipping, putting something online, running an app on a server, the `acc` command, Alternate Clouds, AF Cloud, Akash, Spheron, or Phala — and the request doesn't cleanly match one of the more specific skills (`af-setup`, `deploy-static-site`, `deploy-docker-app`, `deploy-from-template`, `deploy-server`, `troubleshoot-deployment`).
---

# Alternate Clouds CLI (`acc`)

## Install

```bash
npm install -g @alternatefutures/acc
```

Requires Node.js >=18.18.2.

## Authentication

```bash
acc login                  # browser-based (OAuth)
acc login --email          # email verification only (terminal flow)
acc logout
acc whoami                 # who am I + which project; --json for machine output
```

Both login flows mint a real personal access token (PAT). The PAT is stored
in `~/.alternate-futures/token` (mode 0600) — never in plaintext JSON config.
A legacy plaintext token is migrated automatically on first run. If a saved
credential is rejected (401), the CLI clears it and asks you to `acc login`
again.

Without a TTY (CI, piped), commands that would prompt fail fast with a
non-zero exit instead of hanging — set `AF_TOKEN` for headless use.
Cancelled interactive prompts (Ctrl+C / ESC) exit `130`, not `0`.

`acc whoami` exits non-zero when not authenticated — use it for pre-flight checks in scripts and skills:

```bash
acc whoami --json
# {"authenticated":true,"user":{"id":"...","email":"hayk@…","username":null,"walletAddress":null},
#  "project":{"id":"...","name":"…","slug":"…"}}
```

**Automation / CI** — skip interactive login with env vars:

```bash
export AF_TOKEN="<personal-access-token>"   # PAT from `acc pat create` or the dashboard
export AF_PROJECT_ID="<project-id>"
```

## Environment targeting

Default = production (`https://api.alternatefutures.ai`).

### `--local` (recommended for dev)

Rewrites all four URLs (cloud-api `:1602`, auth `:1601`, web UI `:1600`) and uses a separate token slot so a local login never overwrites your prod PAT:

```bash
acc --local login            # logs in against local auth, saves under personalAccessToken__local
acc --local services list    # GraphQL to http://localhost:1602/graphql
acc --local logout           # clears LOCAL token only
```

Place `--local` before the subcommand (same convention as `--debug`).

### Env-var overrides

```bash
AF_API_URL=http://localhost:1602 acc <cmd>      # cloud-api only
AUTH__API_URL=http://localhost:1601 acc <cmd>   # auth service only
```

These don't split the token slot — prefer `--local` for local dev.

## Projects

```bash
acc projects list
acc projects create --name my-project
acc projects switch [id-or-name]    # set active project
acc projects update [id]
acc projects delete [id]
```

## Services

Operate on the active project. Override with `-p <id-or-name>`:

```bash
acc services list
acc services -p my-project list
acc services info [id-or-name-or-slug]
acc services logs [id] --tail 100   # snapshot of recent lines — no --follow/stream mode
acc services close [id]    # stop active deployment (Akash / Spheron / Phala)
acc services delete [id]   # delete service (closes deployment first)
```

`[id]` accepts a service id, name, slug, or short id prefix. Omit to pick interactively.

### `services create` — full flag surface

```bash
acc services create [options]
```

Top-level kind + per-kind source:

| Flag | Purpose |
|---|---|
| `--kind <k>` | `template` \| `docker` \| `server` (functions + GitHub deploys are dashboard-only) |
| `--name <name>` | Service name. Unique **platform-wide** (the slug becomes the public `<slug>-app.alternatefutures.ai` subdomain), not just per-project. Collisions inside the current project are caught up-front; a name held by a service in another project (possibly another user's) surfaces as a server error at create time — pick a different name. |
| `--template <id>` | (kind=template) skip the catalog browse |
| `--image <ref>` | (kind=docker) Docker image, e.g. `nginx:latest` |
| `--port <n>` | (kind=docker) container port, defaults to 80 under `-y` |
| `--os <base>` | (kind=server) base OS image, e.g. `ubuntu:24.04` |
| `--ssh-key <pubkey>` | (kind=server) break-glass OpenSSH public key (e.g. `"ssh-ed25519 AAAA…"`). Baked into the box's `authorized_keys` so you keep direct SSH even if the platform channel dies. Spheron raw boxes only — ignored on Akash/Phala. |
| `--ssh-key-file <path>` | (kind=server) read the break-glass public key from a file, e.g. `~/.ssh/id_ed25519.pub`. Mutually exclusive with `--ssh-key`. |

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
acc services deploy [id] [--same flags as create]
```

Same prompt chain as create; closes any active deployment first (auto-confirms under `-y`). On Akash region soft-fail it surfaces 2–3 alternative regions with the exact retry command.

### `services env` — env var CRUD

```bash
acc services env list [service]
acc services env set <service> <key> <value> [--secret]   # --secret masks it in `list`
acc services env unset <service> <key> [-y]
acc services env reveal <service> <key>                    # print one var's plaintext (incl. secrets)
```

After any change, redeploy to apply: `acc services deploy <service>`.

### `services link / unlink` — wire services together

```bash
acc services link [source] [target] --alias DB    # target's connection info exposed to source as DB_*
acc services unlink [source] [target] [-y]
```

Mirrors the web `ServiceLinker`. Redeploy the source service to materialize the new env keys.

### `services ports` — published ports

```bash
acc services ports list [service]
acc services ports add <service> <containerPort> [--public <n>] [--protocol tcp|http]
acc services ports remove <service> <containerPort> [-y]
```

### `services health` — application health probe

```bash
acc services health show [service]
acc services health set <service> --path /healthz [--port <n>] [--expect 200] [--interval 30] [--timeout 5]
acc services health disable <service> [-y]
```

### `services failover` — health-aware auto-failover

```bash
acc services failover show [service]
acc services failover enable <service> [--max-attempts 3] [--window-hours 24]
acc services failover disable <service> [-y]
acc services failover history [service]
```

Redeploys to a different provider on provider-side failure. Refused on services with persistent volumes (data-loss risk).

### `services config` — edit the persisted service record

```bash
acc services config show [service]
acc services config set <service> [--image <ref>] [--port <n>] [--priority <n>] \
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
acc deployments                  # active in current project
acc deployments --all
acc deployments --project <name>
acc deployments --service <name>
acc deployments --status ACTIVE
acc deployments list --limit 20
```

## SSH

```bash
acc ssh <serviceId>
acc ssh <serviceId> --service web      # target specific container
acc ssh <serviceId> --command /bin/sh  # custom shell
```

The remote PTY owns echoing; predictive local echo is off by default
(opt back in with `AF_SSH_LOCAL_ECHO=1` if you're on a high-latency link
and accept possible double-printing under raw-mode programs).

## Copy files (cp)

Copy a single file to/from a deployment. Rides the same `/ws/shell` channel as
`acc ssh` (base64-framed; no server change, no separate SSH/scp keys). Mark
the remote side as `<serviceId>:<path>` — exactly one side must be remote.

```bash
acc cp ./local.bin <serviceId>:/root/model.bin     # upload   (local -> deployment)
acc cp <serviceId>:/root/model.bin ./model.bin     # download (deployment -> local)
acc cp <serviceId>:/root/f ./f --service web       # multi-service SDL: pick the service
```

Binary-safe and byte-exact (proven against a 127 MB model checkpoint).
Requires the deployment to be `ACTIVE`. No recursive/directory mode yet —
one file at a time; tar a directory first if needed.

## Chat (end-to-end encrypted)

Talk to a deployed **alt-chat** relay from the terminal — for humans and agents.
No `acc login` required (the passphrase is the only credential — it alone selects
the room, there is no room name). A passphrase is **exactly 6 space-separated
words** (e.g. `zebra zero zone zoom yoga word`); anything else is rejected. See
the `alternate-chat` skill for the full agent guide.

```bash
acc chat join [target]                 # interactive TUI (humans): /reply (last msg), @mentions, 👑
acc chat send [target] --message "hi" --json   # post one message, exit (agents/CI)
acc chat send [target] --message "ok" --reply-to "<pubkey>:<seq>" --json   # thread a reply
acc chat read [target] --json                  # history; messages carry pubkey/seq/replyTo/edited/deleted
acc chat read [target] --watch --json          # stream live (NDJSON): message/edit/delete/join/sys-join…
```

`[target]` = a URL/host (`https://chat.alternatefutures.ai`), your own service
name, or omitted (uses `AF_CHAT_URL`, else the public demo). Prefer env vars for
secrets — `--password` on argv leaks via `ps`/history:

```bash
export AF_CHAT_URL=https://chat.alternatefutures.ai \
       AF_CHAT_PASSWORD=… AF_CHAT_USERNAME=claude-code AF_CHAT_IDENTITY=~/.af-chat-id
acc chat send --message "deploy finished" --json   # {"ok":true,…,"seq":7}
# The passphrase ALONE selects the room (no room name); JSON "room" is the derived 2-word label.
```

The relay is blind (ciphertext-only); the Ed25519 **fingerprint** — not the
display name — identifies a peer.

## Regions, templates, billing, PATs

```bash
acc regions [--provider akash|phala] [--gpu h100|h200|a100|rtx4090]
acc templates list
acc templates info <templateId>
acc billing balance        # wallet of the ACTIVE org (set at login / org switch)
acc billing topup --crypto --amount 25 \
    [--chain base|ethereum|arbitrum|optimism|polygon] \  # default: base
    [--token USDC|USDT|DAI] \                            # default: USDC
    [--org <idOrSlug>] [--no-wait]
acc pat list
acc pat create --name "CI token"
acc pat delete <tokenId>
```

`billing topup` is crypto-only (card top-ups happen in the web dashboard) and
needs the OWNER or ADMIN org role. It prints a stablecoin deposit address
(plus a terminal QR when colors are supported) and polls the balance until
the credit lands or the ~1-hour payment window expires; Ctrl-C while waiting
is safe — funds credit automatically once the transfer confirms. Send ONLY
the chosen token on the chosen network to the printed address. Max $10,000
per top-up; creation is rate-limited to 10/min.

## Common non-interactive recipes

```bash
# Static Docker container on Akash, no GPU
acc services create --kind docker --name web --image nginx:alpine --port 80 -y

# GPU workload (Spheron-first, Akash fallback)
acc services create --kind docker --name infer --image my/llm:v1 --port 8080 \
  --gpu --gpu-model h100 --gpu-count 1 --region us-east -y

# Confidential TEE deploy from a template
acc services create --kind template --template trusted-llm \
  --confidential --name secure-chat --env API_KEY=xxx -y

# Empty Ubuntu VM for SSH
acc services create --kind server --name dev-box --os ubuntu:24.04 -y
acc ssh dev-box
```

## Help

```bash
acc help
acc services help
acc services create --help
```

## Exit codes

- `0` success
- `1` hard failure (auth, validation, server error)
- `2` Akash region soft-fail (`AWAITING_REGION_RESPONSE`) — surfaces alternative regions with retry commands
