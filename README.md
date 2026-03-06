<div align="center">

# simon-bot

**A 19-step autonomous coding pipeline for Claude Code —<br>22 experts, 5 domain teams, zero shortcuts.**

[![GitHub Stars](https://img.shields.io/github/stars/SW-in-beta/simon-bot?style=flat-square)](https://github.com/SW-in-beta/simon-bot/stargazers)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-compatible-blueviolet?style=flat-square)](https://claude.com/claude-code)

[한국어](./README.ko.md)

</div>

---

## Why simon-bot?

Most AI coding assistants generate code and hope for the best. simon-bot treats every task like a production deployment:

- **Ship with confidence** — A 19-step pipeline with mandatory TDD, 5 expert-team reviews, and a success-criteria gate means code is verified before you ever see a PR.
- **Scale without chaos** — Each work unit runs in an isolated git worktree. Parallel execution, zero interference, clean history.
- **Get smarter over time** — Built-in retrospectives feed back into future runs. A dedicated boost skill lets you teach it new tricks from articles, repos, and papers.
- **Stay safe by default** — No force pushes, no real DB access, no destructive commands. Ever.

## How It Works

```mermaid
graph LR
    A["Scope & Analyze"] --> B["Plan & Review"]
    B --> C["Expert Teams\n(22 specialists)"]
    C --> D["Implement\n(TDD enforced)"]
    D --> E["Multi-step\nVerification"]
    E --> F["Guided Review\n& PR"]

    style A fill:#e8f4f8,stroke:#2196F3
    style B fill:#e8f4f8,stroke:#2196F3
    style C fill:#fff3e0,stroke:#FF9800
    style D fill:#e8f5e9,stroke:#4CAF50
    style E fill:#e8f5e9,stroke:#4CAF50
    style F fill:#f3e5f5,stroke:#9C27B0
```

## Quick Start

```bash
git clone https://github.com/SW-in-beta/simon-bot.git
cd simon-bot
./install.sh
```

Then in Claude Code:

```
/simon-bot implement user authentication with JWT
```

## Skills

| Skill | What it does |
|-------|-------------|
| `/simon-bot` | Full 19-step pipeline — plan, implement, verify, PR |
| `/simon-bot-grind` | Same pipeline, maximum tenacity — 10x retries, auto-diagnosis, strategy pivots |
| `/simon-bot-sessions` | List, resume, or clean up worktree-based work sessions |
| `/simon-bot-boost` | Read external resources and improve simon-bot's own skills |
| `/simon-bot-pm` | Project manager — PRD-driven planning, distributes tasks to simon-bot instances |
| `/simon-bot-report` | Analysis documents (RFC, status report) via expert discussion — no code changes |

### Pick the Right Skill

| I want to... | Use |
|--------------|-----|
| Build a feature or fix a bug | `/simon-bot` |
| Tackle something complex that can't fail | `/simon-bot-grind` |
| Resume or manage previous sessions | `/simon-bot-sessions` |
| Improve simon-bot from an article or repo | `/simon-bot-boost` |
| Plan and build an entire app | `/simon-bot-pm` |
| Get an RFC or analysis without changing code | `/simon-bot-report` |

<details>
<summary><strong>Expert Teams (5 domains, 22 specialists)</strong></summary>

Experts operate as **teams that discuss and reach consensus**, not individual reviewers.

| Team | Members | Activation | Focus |
|------|---------|------------|-------|
| **Safety** | appsec, auth, infrasec, stability | Always (appsec + stability) | Security boundaries, auth bypass, failure recovery |
| **Code Design** | convention, idiom, design-pattern, testability | Always (convention + idiom) | Repo conventions, idioms, design patterns, testability |
| **Data** | rdbms, cache, nosql | Auto-detect (min 2) | Data consistency, cache invalidation, cross-storage integrity |
| **Integration** | sync-api, async, external-integration, messaging | Auto-detect (min 2) | Sync/async boundaries, error propagation, failure isolation |
| **Ops** | infra, observability, performance, concurrency | Auto-detect (min 2) | Operational stability, observability, performance |

</details>

<details>
<summary><strong>Configuration (config.yaml)</strong></summary>

Adjust thresholds, loop limits, and expert behavior in `.claude/workflow/config.yaml`:

```yaml
model_policy: opus              # Model for all agents
language: ko                    # Report language

unit_limits:
  max_files: 5
  max_lines: 200

size_thresholds:
  function_lines: 50
  file_lines: 300

loop_limits:
  critic_planner: 3
  step4b_critical: 2
  step7b_recheck: 1
  step7_8: 2
  step6_executor: 3
  step16: 3

expert_panel:
  mode: agent-team
  discussion_rounds: 2
  require_consensus: true

test_env:
  check_before_test: true
  skip_on_missing: true
```

Customize expert review criteria in `.claude/workflow/prompts/*.md` (22 expert prompts).
Past feedback is stored in `.claude/memory/retrospective.md` and automatically referenced in future runs.

</details>

<details>
<summary><strong>Safety Rules</strong></summary>

The following actions are **absolutely forbidden** at all times:

- `git push --force` — never, under any circumstances
- Merge to `main`/`master` — only PRs
- `rm -rf` — no destructive deletions
- Real DB access — `mysql`, `psql`, `redis-cli`, `mongosh`
- Real API calls — `curl`, `wget` to external endpoints
- Real server access — `ssh`, `scp`, `sftp`
- Secret commits — `.env`, credentials, API keys
- Tests with real external systems — mock/stub only

</details>

<details>
<summary><strong>Full Workflow Details (19 steps)</strong></summary>

### Phase A: Planning (Interactive)

| Step | What happens |
|------|-------------|
| **0** | Scope challenge — analyze existing code, determine minimum change, select review path (SMALL / STANDARD / LARGE) |
| **1-A** | Project analysis + Code Design Team pre-analysis (conventions, patterns, idioms) |
| **1-B** | Interview mode — break work into units, build plan |
| **2** | Critic-planner discussion (up to 3 rounds) |
| **3** | Meta-verification of critic's review |
| **4** | Over-engineering check (YAGNI/KISS) |
| **4-B** | All 5 expert teams review the plan, flag concerns |

### Phase B-E: Implementation & Verification (Autonomous)

Each unit runs in an isolated git worktree with mandatory TDD (RED -> GREEN -> REFACTOR).

| Step | What happens |
|------|-------------|
| **5** | Implementation with TDD |
| **6** | Purpose alignment review |
| **7-A** | 5 expert teams verify against real diff |
| **7-B** | Cross-check against Step 4-B concerns |
| **8** | Regression verification |
| **9** | File/function splitting |
| **10** | Integration/reuse review |
| **11** | Side effect check |
| **12** | Full change review |
| **13** | Dead code cleanup |
| **14** | Code quality assessment |
| **15** | Flow verification (backend/data/error/event) |
| **16** | MEDIUM issue resolution |
| **17** | Production readiness + success criteria gate |

### Finalization

| Step | What happens |
|------|-------------|
| **Integration** | Commit, resolve conflicts, build/test verification |
| **18** | Work report (before/after flows, trade-offs, risks) |
| **18-B** | Group changes into logical review units |
| **19** | Interactive guided review, success criteria verification, PR creation |

</details>

## Requirements

- [Claude Code](https://claude.com/claude-code) v2.0+
- Git

## License

MIT
