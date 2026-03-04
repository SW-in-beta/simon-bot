# simon-bot

[한국어](./README.ko.md)

A 19-step deep workflow plugin for [Claude Code](https://claude.com/claude-code) that plans, implements, and verifies code with maximum rigor.

Built on [oh-my-claudecode](https://github.com/nicepkg/oh-my-claudecode) multi-agent orchestration.

## Features

- **Scope-first planning** — Analyzes existing code and git history before planning
- **19-step quality pipeline** — From scope challenge to production readiness
- **Parallel execution** — Independent work units run simultaneously in isolated git worktrees
- **5 domain expert teams** — 22 specialists organized into teams that discuss and reach consensus (Security, Code Design, Data, Integration, Ops)
- **Code Design pre-analysis** — Convention, idiom, pattern, and testability experts analyze the repo before planning
- **Interactive guided review** — Plan-mapped code review with rich before/after context
- **Context-efficient** — Scripts handle deterministic tasks; memory files prevent context loss
- **PR-reviewer friendly** — Work split into small units (3-5 files, 200 lines max)
- **Self-improving** — Retrospective feedback automatically improves future runs
- **Safe by design** — No force push, no real DB/API access, no destructive commands

## Variants

| Skill | Description |
|-------|-------------|
| `/simon-bot` | Standard 19-step pipeline |
| `/simon-bot-grind` | Grind mode — all retry limits set to 10, auto-diagnosis/recovery/strategy pivots |
| `/simon-bot-sessions` | Session management — list, resume, delete previous work sessions |

## Installation

```bash
git clone https://github.com/yourname/simon-bot
cd simon-bot
chmod +x install.sh
./install.sh
```

This installs:
- Global skill → `~/.claude/skills/simon-bot/SKILL.md`
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
| **1-A** | `explore-medium` → `analyst` → **Code Design Team** | Project analysis + repo convention/pattern/idiom pre-analysis |
| **1-B** | `planner` | Interview mode → Unit breakdown + plan |
| **2** | `critic` ↔ `planner` (Agent Team) | Plan review via direct discussion (max 3 iterations) |
| **3** | `architect` (Agent Team) | Meta-verification of critic's review |
| **4** | `architect` (Agent Team) | Over-engineering check (YAGNI/KISS) |
| **4-B** | 5 domain expert teams | Pre-implementation plan review — teams discuss and flag concerns |

User chooses a review path in Step 0:

| Path | Steps | Best for |
|------|-------|----------|
| **SMALL** | 5→6→7→8→17 | Bug fixes, small features |
| **STANDARD** | 5→6→7→...→17 | Most features |
| **LARGE** | 5→6→7→...→17 + extras | Architecture changes |

### Phase B-E: Implementation & Verification (Autonomous)

Runs automatically with `ralph + ultrawork` mode.

**Pre-Phase: Base Branch Sync** — Fetches latest `origin/main` (or `master`) and creates a worktree with the user-provided branch name.

Each Unit executes in an isolated git worktree.

| Step | Agent | Role |
|------|-------|------|
| **Pre** | `setup-test-env.sh` | Test environment setup — auto-install deps if missing |
| **5** | `executor` | Implementation (reads expert concerns + code design analysis) |
| **6** | `architect` | Purpose alignment review |
| **7-A** | 5 domain expert teams | Bug/security/performance verification via team discussion |
| **7-B** | `architect` | Cross-check against Step 4-B concerns; fix missed items |
| **8** | `architect` | Regression verification |
| **9** | `architect` → `executor` | File/function splitting |
| **10** | `architect` → `executor` | Integration/reuse review |
| **11** | `architect` | Side effect check |
| **12** | `code-reviewer` | Full change review |
| **13** | `architect` → `executor` | Dead code cleanup |
| **14** | `code-reviewer` | Code quality assessment |
| **15** | `architect` | Flow verification (backend/data/error/event flows) |
| **16** | `architect` | MEDIUM issue resolution |
| **17** | `architect` + `security-reviewer` | Production readiness |

### Finalization

| Step | Role |
|------|------|
| **Integration** | Commit to user-named branch → resolve conflicts → build/test verification |
| **18** | Work report (before/after flow, trade-offs, risks, tests) |
| **18-B** | Review sequence — group changes into logical units, map to plan |
| **19** | **Interactive guided review → PR creation** |

## Step 19: Interactive Guided Review

Step 19 is an interactive code review with the user, conducted after all implementation and verification is complete. **PR is created after review, not before.**

### 19-A: Review Overview (Plan-Mapped)

Instead of simple stats, presents a **plan-to-implementation mapping**:

- **Plan summary reminder** — Original goals and key requirements
- **Implementation mapping table** — Which plan Units map to which logical change units
- **Relationship diagram** — How change units connect (data/call flow)
- **Review order rationale** — Why this sequence (upstream → downstream)

### 19-B: Sequential Review (Rich Context)

Each logical change unit is presented with:

| Item | Description |
|------|-------------|
| **Plan mapping** | "This change implements [Unit N: title]" |
| **Before state** | What the existing code did, how it worked, its limitations |
| **What changed** | Specifically what was improved/added |
| **Key diff** | Before/After code (important parts only) |
| **Cross-references** | Relationship to previous/next change units |
| **Review points** | Areas requiring careful attention |
| **Expert concerns** | How relevant expert concerns were addressed |
| **Trade-offs** | Design decisions and their rationale |

For each unit, feedback is collected: **OK / Revision requested / Question**.

### 19-C: PR Creation & Wrap-up

After review is complete, the user chooses:

- **Create Draft PR** — `gh pr create --draft`
- **Create Ready PR** — `gh pr create` (ready immediately)
- **More revisions needed** — Return to 19-B

Step 18 report content is included in the PR description.

## Session Management

Use `/simon-bot-sessions` to manage work sessions across Claude Code sessions.

| Command | Description |
|---------|-------------|
| `/simon-bot-sessions list` | List all active worktree sessions |
| `/simon-bot-sessions info feat/add-auth` | Show session details (commits, memory files, status) |
| `/simon-bot-sessions delete feat/add-auth` | Delete session (worktree + branch) |
| `/simon-bot-sessions resume feat/add-auth` | Resume previous work with context restoration |
| `/simon-bot-sessions pr feat/add-auth` | Create PR from session |

Or use the shell script directly:

```bash
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh list
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh info <branch>
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh delete <branch>
```

## Flow Diagram

```
Startup: Branch name input (user provides branch name)
        │
Step 0: Scope Challenge
  └─ git history + what exists → SMALL / STANDARD / LARGE
        │
Phase A (interactive)
  ├─ 1-A Analysis + Code Design Team (convention, idiom, pattern, testability)
  ├─ 1-B Planning (Unit split, NOT in scope, Unresolved)
  ├─ 2-4 Review loop (Agent Team: planner ↔ critic ↔ architect)
  └─ 4-B Expert Plan Review (5 domain teams discuss concerns)
        │
Pre-Phase: Base Branch Sync
  └─ git fetch origin main → worktree from origin/main
        │ ralph + ultrawork starts
        ▼
Phase B-E (autonomous, worktree isolated)
  Pre: Test env setup (auto-install deps if missing)
  ┌─────────────────┐  ┌─────────────────┐
  │ worktree/unit-1 │  │ worktree/unit-2 │  ← parallel
  │ Step 5~17       │  │ Step 5~17       │
  └────────┬────────┘  └────────┬────────┘
           └──────┬─────────────┘
                  ▼
          worktree/unit-3 (depends on 1,2)
                  │
                  ▼
          Integration (commit, build, test)
                  │
                  ▼
          Report → Review Sequence
                  │
                  ▼
          Interactive Guided Review (19-A → 19-B → 19-C)
                  │
                  ▼
          PR creation → feedback.md
                        (persistent across sessions)
```

## Expert Panel (5 Domain Teams)

Experts operate as **teams that discuss and reach consensus**, not as individual reviewers.

### Team Structure

| Team | Members | Activation | Discussion Focus |
|------|---------|------------|------------------|
| **Safety** | appsec, auth, infrasec, stability | Always (appsec + stability) | Security boundaries, auth bypass, failure recovery |
| **Code Design** | convention, idiom, design-pattern, testability | Always (convention + idiom) | Repo conventions, language idioms, design patterns, testability |
| **Data** | rdbms, cache, nosql | Auto-detect (min 2) | Data consistency, cache invalidation, cross-storage integrity |
| **Integration** | sync-api, async, external-integration, messaging | Auto-detect (min 2) | Sync/async boundaries, error propagation, failure isolation |
| **Ops** | infra, observability, performance, concurrency | Auto-detect (min 2) | Operational stability, observability, performance |

### Team Activation by Review Path

| Path | Teams |
|------|-------|
| SMALL | Safety + Code Design (always members only) |
| STANDARD | Safety + Code Design + auto-detected Data/Integration/Ops |
| LARGE | All teams + extended failure mode analysis |

### Expert Involvement Points

Experts participate **twice** in the workflow:
1. **Step 4-B** (Plan Review): Teams discuss the plan → flag concerns (CRITICAL/HIGH/MEDIUM)
2. **Step 7** (Verification): Teams verify implementation against actual diff + cross-check Step 4-B concerns

## Customization

### config.yaml

Adjust thresholds, loop limits, and expert configuration:

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

### Expert Prompts

Modify expert review criteria in `.omc/workflow/prompts/*.md` (22 expert prompts).

### Retrospective

Past feedback is stored in `.omc/memory/retrospective.md` and automatically referenced in future runs.

## Safety Rules

The following actions are **absolutely forbidden** at all times:

- `git push --force` — never, under any circumstances
- Merge to `main`/`master` — only PRs
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
