# simon-bot

[한국어](./README.ko.md)

A 19-step deep workflow plugin for [Claude Code](https://claude.com/claude-code) that plans, implements, and verifies code with maximum rigor.

Built on [oh-my-claudecode](https://github.com/nicepkg/oh-my-claudecode) multi-agent orchestration.

## Features

- **Scope-first planning** — Analyzes existing code and git history before planning
- **19-step quality pipeline** — From scope challenge to production readiness
- **Parallel execution** — Independent work units run simultaneously in isolated git worktrees
- **Expert review panel** — Up to 9 specialized reviewers (security, DB, API, concurrency, etc.)
- **Context-efficient** — Scripts handle deterministic tasks; memory files prevent context loss
- **PR-reviewer friendly** — Work split into small units (3-5 files, 200 lines max)
- **Self-improving** — Retrospective feedback automatically improves future runs
- **Safe by design** — No force push, no real DB/API access, no destructive commands

## Installation

```bash
git clone https://github.com/yourname/simon-bot
cd simon-bot
chmod +x install.sh
./install.sh
```

This installs:
- Global skill → `~/.claude/skills/simon-bot.md`
- Project workflow → `.omc/workflow/` (config, prompts, scripts, templates)

### Project-only install

If you only need workflow files in a specific project:

```bash
./install.sh --project-only
```

## Usage

In Claude Code:

```
/simon-bot implement user authentication with JWT
```

Or naturally:

```
simon-bot으로 결제 시스템 구현해줘
```

## Workflow

### Phase A: Planning (Interactive)

| Step | Agent | Role |
|------|-------|------|
| **0** | `architect` | Scope Challenge — what exists, minimum change, review path |
| **1-A** | `explore-medium` → `analyst` | Project analysis + principle recommendations |
| **1-B** | `planner` | Interview mode → Unit breakdown + plan |
| **2** | `critic` ↔ `planner` | Plan review loop (max 3 iterations) |
| **3** | `architect` | Meta-verification of critic's review |
| **4** | `architect` | Over-engineering check (YAGNI/KISS) |

User chooses a review path in Step 0:

| Path | Steps | Best for |
|------|-------|----------|
| **SMALL** | 5→6→7→8→17 | Bug fixes, small features |
| **STANDARD** | 5→6→7→...→17 | Most features |
| **LARGE** | 5→6→7→...→17 + extras | Architecture changes |

### Phase B-E: Implementation & Verification (Autonomous)

Runs automatically with `ralph + ultrawork` mode. Each Unit executes in an isolated git worktree.

| Step | Agent | Role |
|------|-------|------|
| **5** | `executor` | Implementation (TDD if selected) |
| **6** | `architect` | Purpose alignment review |
| **7** | `security-reviewer` + `architect` + experts | Bug/security/performance review |
| **8** | `architect` | Regression verification |
| **9** | `architect` → `executor` | File/function splitting |
| **10** | `architect` → `executor` | Integration/reuse review |
| **11** | `architect` | Side effect check |
| **12** | `code-reviewer` | Full change review |
| **13** | `architect` → `executor` | Dead code cleanup |
| **14** | `code-reviewer` | Code quality assessment |
| **15** | `architect` | UX flow verification |
| **16** | `architect` | MEDIUM issue resolution |
| **17** | `architect` + `security-reviewer` | Production readiness |

### Integration & Reporting

| Step | Role |
|------|------|
| **Integration** | Merge worktrees → resolve conflicts → Draft PR |
| **18** | Work report (before/after flow, trade-offs, risks, tests) |
| **19** | Retrospective (user feedback → workflow improvement) |

## Flow Diagram

```
Step 0: Scope Challenge
  └─ git history + what exists → SMALL / STANDARD / LARGE
        │
Phase A (interactive)
  ├─ 1-A Analysis (Context7)
  ├─ 1-B Planning (Unit split, NOT in scope, Unresolved)
  └─ 2-4 Review loop
        │ ralph + ultrawork starts
        ▼
Phase B-E (autonomous, worktree isolated)
  ┌─────────────────┐  ┌─────────────────┐
  │ worktree/unit-1 │  │ worktree/unit-2 │  ← parallel
  │ Step 5~17       │  │ Step 5~17       │
  └────────┬────────┘  └────────┬────────┘
           └──────┬─────────────┘
                  ▼
          worktree/unit-3 (depends on 1,2)
                  │
                  ▼
          Integration + AI Merge
                  │
                  ▼
          Draft PR → Report → Retrospective
```

## Expert Panel (Step 7)

Always active:

| Expert | Focus |
|--------|-------|
| `security-reviewer` | OWASP Top 10, injection, auth |
| `architect` (bugs) | Race conditions, edge cases, error handling |

Auto-detected based on project analysis:

| Expert | Activated when |
|--------|---------------|
| DB expert | Database usage detected |
| API expert | REST/gRPC/WebSocket detected |
| Concurrency expert | Multi-thread/async patterns |
| Infra expert | Docker/K8s/CI code detected |
| Caching expert | Caching layer detected |
| Messaging expert | Kafka/RabbitMQ detected |
| Auth expert | Authentication logic is core |

## Customization

### config.yaml

Adjust thresholds, loop limits, and expert configuration:

```yaml
# Change unit size limits
unit_limits:
  max_files: 5
  max_lines: 200

# Adjust code size thresholds
size_thresholds:
  function_lines: 50
  file_lines: 300
```

### Expert Prompts

Modify expert review criteria in `.omc/workflow/prompts/*.md`:

```
.omc/workflow/prompts/
├─ db-expert.md
├─ api-expert.md
├─ concurrency-expert.md
├─ infra-expert.md
├─ caching-expert.md
├─ messaging-expert.md
└─ auth-expert.md
```

### Retrospective

Past feedback is stored in `.omc/memory/retrospective.md` and automatically referenced in future runs. The workflow improves over time based on your feedback.

## Safety Rules

The following actions are **absolutely forbidden** at all times:

- `git push --force` — never, under any circumstances
- Merge to `main`/`master` — only Draft PRs
- `rm -rf` — no destructive deletions
- Real DB access — `mysql`, `psql`, `redis-cli`, `mongosh`
- Real API calls — `curl`, `wget` to external endpoints
- Real server access — `ssh`, `scp`, `sftp`
- Secret commits — `.env`, credentials, API keys
- Tests with real external systems — mock/stub only

## Requirements

- [Claude Code](https://claude.com/claude-code) v2.0+
- [oh-my-claudecode](https://github.com/nicepkg/oh-my-claudecode) v4.0+
- Git

## License

MIT
