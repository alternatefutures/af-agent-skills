# AlternateFutures CLI Plugin

AI coding assistant plugin for the [AlternateFutures CLI](https://www.npmjs.com/package/@alternatefutures/cli) (`af`).

Gives your AI agent full knowledge of the `af` CLI — authentication, projects, services, deployments, SSH, billing, and environment targeting.

## Install

### Cursor

Available on the [Cursor Marketplace](https://cursor.com/marketplace):

```
/add-plugin af-cli
```

### Claude Code

Add the marketplace, then install:

```
/plugin marketplace add https://github.com/alternatefutures/cursor-plugin-af-cli
/plugin install af-cli@af-plugins
```

### OpenAI Codex

```
$skill-installer af-cli
```

Or copy `skills/af-cli/` to `~/.agents/skills/af-cli/`.

### Manual (any agent)

Copy `skills/af-cli/SKILL.md` into your agent's skills directory:

- Cursor: `~/.cursor/plugins/local/af-cli/skills/af-cli/SKILL.md`
- Claude Code: `~/.claude/skills/af-cli/SKILL.md`
- Codex: `~/.agents/skills/af-cli/SKILL.md`

## What's included

| Skill | Description |
|:------|:------------|
| `af-cli` | Full CLI reference — auth, projects, services, deployments, SSH, billing, PATs, env targeting |

## Links

- CLI: [@alternatefutures/cli](https://www.npmjs.com/package/@alternatefutures/cli)
- Platform: [alternatefutures.ai](https://alternatefutures.ai)
- Docs: [alternatefutures.ai/docs](https://alternatefutures.ai/docs)

## License

AGPL-3.0-only
