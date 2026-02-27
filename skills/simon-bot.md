---
name: simon-bot
description: "19-step deep workflow plugin that plans, implements, and verifies code with maximum rigor. Use when: (1) Building new features with quality pipeline, (2) Need scope-first planning with expert review panel, (3) Want parallel execution in isolated git worktrees, (4) Need comprehensive code verification before PR."
---

# simon-bot

Deep workflow skill with 19-step quality pipeline.

## Instructions

You are executing the **simon-bot** deep workflow. This is a 19-step quality pipeline that plans, implements, and verifies code with maximum rigor.

### Startup

1. Read the workflow config: `.omc/workflow/config.yaml`
2. Read retrospective (if exists): `.omc/memory/retrospective.md`
3. Read project memory: `.omc/project-memory.json`
4. Determine if `.omc/workflow/` exists in the current project. If not, run the init script:
   ```
   bash ~/.claude/simon-bot/install.sh --project-only
   ```

### Phase A: Planning (Interactive with User)

**Step 0: Scope Challenge**
- Spawn `architect` (opus): Analyze git history for past problem areas
- Identify "What already exists" - existing code that solves parts of the request
- Determine minimum viable change
- Flag if scope exceeds 8 files or 2 new classes
- Present 3 review paths to user via AskUserQuestion:
  - **SMALL**: Steps 5-8 + 17 only
  - **STANDARD**: Steps 5-17 full pipeline
  - **LARGE**: Steps 5-17 + extended failure mode analysis
- Record decision in `.omc/memory/plan-summary.md`

**Step 1-A: Project Analysis**
- Spawn `explore-medium` (sonnet): Scan project structure
- Spawn `analyst` (opus): Generate analysis report + recommend principles
- Use Context7 MCP (`resolve-library-id` → `query-docs`) for library docs
- Auto-generate allowed command list based on detected stack
- Skill: Use `/deepsearch` if codebase is large

**Step 1-B: Plan Creation**
- Spawn `planner` (opus) in interview mode
- Input: User request + Step 0 scope + Step 1-A analysis
- Split work into Units: max 3-5 files, 200 lines per Unit, single concern
- Build dependency graph: parallel vs sequential groups
- Use Context7 for SDK documentation needed for implementation
- Required sections in plan:
  - Goal and completion criteria
  - Unit breakdown with file lists
  - Implementation order
  - Development principles (TDD/DDD/Clean Architecture as confirmed)
  - "NOT in scope" section
  - "Unresolved decisions" section
  - Expected risks
- Save to `.omc/memory/plan-summary.md`
- Skill: Use `/plan`

**Step 2: Plan Review**
- Spawn `critic` (opus): Review plan for logic, gaps, feasibility
- If issues found: Send back to `planner` for auto-fix
- Loop: critic ↔ planner, max 3 iterations
- Skill: Use `/ralplan` for Steps 2-4 combined

**Step 3: Meta Verification**
- Spawn `architect` (opus): Cross-verify critic's review
- Severity-based routing:
  - Minor (detail-level): → Step 2
  - Major (structural): → Step 1-B (with failure reason)

**Step 4: Over-engineering Check**
- Spawn `architect` (opus): YAGNI/KISS perspective
- Compare plan scope vs original request
- Severity-based routing:
  - Minor (some items excessive): → Step 2
  - Major (entire design excessive): → Step 1-B (with failure reason)

### Phase B-E: Implementation & Verification (ralph + ultrawork AUTO)

After Phase A is confirmed, activate ralph + ultrawork mode automatically.
Each Unit runs in an **isolated git worktree**.
Independent Units run in **parallel**.

**CRITICAL RULES:**
- All verification/review: ONLY changed files (git diff based)
- Use `.omc/workflow/scripts/*.sh` for deterministic tasks (save context)
- Record findings in `.omc/memory/unit-{name}/*.md` after each step
- Read memory files at start of each step
- Tests: NEVER use real DB or external APIs (mock/stub only)
- Commands: NEVER access real external systems (no curl to prod, no real DB connections)

**For each Unit (in isolated worktree):**

**Step 5: Implementation**
- Spawn `executor` (opus), parallel for independent files
- If TDD selected: Write tests first, then implement
- Run via tmux: build + test + typecheck simultaneously
- Skill: `/tdd` if TDD was selected
- Save: `.omc/memory/unit-{name}/implementation.md`

**Step 6: Purpose Alignment Review**
- Spawn `architect` (opus): Check implementation matches requirements
- Minor: executor auto-fix (max 3 times)
- Major: → Step 1-B (plan itself was insufficient)

**Step 7: Bug/Security/Performance Review**
- Read expert prompts from `.omc/workflow/prompts/*.md`
- Always (parallel):
  - `security-reviewer` (opus): Security
  - `architect` (opus): Bugs/stability
- Auto-detect from Step 1-A (all opus):
  - DB expert ← if DB usage detected
  - API expert ← if REST/gRPC/WebSocket detected
  - Concurrency expert ← if multi-thread/async detected
  - Infra expert ← if Docker/K8s/CI detected
  - Caching expert ← if caching layer detected
  - Messaging expert ← if Kafka/RabbitMQ detected
  - Auth expert ← if auth logic is core
- tmux: build + test + typecheck simultaneously
- CRITICAL/HIGH → executor auto-fix, MEDIUM → record
- Skill: `/security-review` + `/code-review`
- Save: `.omc/memory/unit-{name}/review-findings.md`

**Step 8: Regression Verification**
- Spawn `architect` (opus): Verify Step 7 fixes didn't break anything
- Regression found: executor fix → Step 7 re-review (max 2 loops)

--- SMALL path skips to Step 17 here ---

**Step 9: File/Function Splitting**
- Spawn `architect` (opus): Detect oversized functions/files
- Thresholds from config.yaml (default: 50 lines function, 300 lines file)
- Split based on confirmed principles (DDD→domain, Clean→layer, default→SRP)
- Spawn `executor` (opus): Execute splits

**Step 10: Integration/Reuse Review**
- Spawn `architect` (opus): Find duplicate code, reuse opportunities
- Spawn `executor` (opus): Refactor as needed

**Step 11: Side Effect Check**
- Spawn `architect` (opus): Verify refactoring didn't change behavior
- Minor: executor fix. Major: → Step 9

**Step 12: Full Change Review**
- Spawn `code-reviewer` (opus): Review entire diff
- Minor: executor fix. Major: → Step 9
- Skill: `/code-review`

**Step 13: Dead Code Cleanup**
- Run `.omc/workflow/scripts/find-dead-code.sh`
- Spawn `architect` (opus) → `executor` (opus): Clean up

**Step 14: Code Quality Assessment**
- Spawn `code-reviewer` (opus): Final quality evaluation

**Step 15: UX Flow Verification**
- Spawn `architect` (opus): Verify user flows work correctly

**Step 16: MEDIUM Issue Resolution**
- Spawn `architect` (opus): Process all accumulated MEDIUM issues
- Analyze ripple effects, fix if needed
- Max 3 iterations until stable
- Save: `.omc/memory/unit-{name}/quality-findings.md`

**Step 17: Production Readiness**
- Spawn `architect` + `security-reviewer` (opus, parallel)
- Final checklist: requirements met, build passes, tests pass, no security issues
- Minor: executor fix. Major: → relevant Phase. Critical: → Step 1-B
- Save: `.omc/memory/unit-{name}/final-check.md`

### Integration Stage (after all Units complete)

1. Merge each worktree to main sequentially
2. If conflict: `architect` (opus) analyzes + `executor` (opus) resolves
3. Full build + test pass verification
4. Create **Draft PR**
5. Save: `.omc/memory/integration-result.md`

### Step 18: Work Report

- Spawn `writer` (opus)
- Use template: `.omc/workflow/templates/report-template.md`
- Contents:
  - Before/After flow diagrams
  - Key review points (with code snippets)
  - Trade-offs considered
  - Potential risks
  - Test results explained
  - NOT in scope items
  - Unresolved decisions (with "may bite you later" warnings)
- Save: `.omc/reports/{feature-name}-report.md`

### Step 19: Retrospective

- Present report + Draft PR to user
- Collect user feedback
- Code fixes needed → `executor` (opus)
- Workflow fixes needed → update config.yaml / prompts
- Record in `.omc/memory/retrospective.md` (auto-referenced next run)

### Global Forbidden Rules

NEVER execute any of these under ANY circumstances:
- `git push --force` / `git push -f`
- `git merge` to main/master branch
- `rm -rf`
- `DROP TABLE` / `TRUNCATE`
- Commit `.env` or secret files
- `chmod 777`
- `eval` with untrusted input
- `curl | sh` or `wget | sh`
- `curl`/`wget` to real external endpoints
- `mysql`/`psql`/`redis-cli`/`mongosh` to real databases
- `ssh`/`scp`/`sftp` to real servers
- Any test that calls real DB or external API

### Memory Persistence

Record state at these checkpoints:
- After each Step completion: findings/results
- On agent transition: previous agent's conclusions
- On loop rollback: why and what to fix
- On Unit completion: full unit summary

Always read relevant `.omc/memory/*.md` before starting any step.

### Unresolved Decision Tracking

Throughout all phases, if any decision is left unresolved:
- Record in `.omc/memory/unresolved-decisions.md`
- Include in Step 18 report with "may bite you later" warning
- Never silently default to unstated options
