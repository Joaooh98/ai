# Stack Profile

## Summary (3 lines)

This repository (`Joaooh98/ai`, remote confirmed at `git remote -v`) is **not an application** —
it is a Claude Code tooling library: agent definitions, skills, hooks and read-only shell scripts
that a "team" of subagents uses to run an SDLC/incident workflow inside *other* projects
(`README.md:1-14`, `.claude/toolbelt.md:6-7`). There is no build, no runtime dependency manifest,
and no Docker artifact anywhere in the tree today — the only Docker references are detection
strings inside shell scripts that look for `Dockerfile`/`compose.yml` **in target projects**, not
in this repo. The goal stated by the team lead ("git clone + full dev/run inside Docker, resilient
to dropped connections") has **no existing partial implementation** to build on; it would be new
tooling (most likely a new `tools/*.sh` + a skill), following the same "read-only script does the
work, skill/agent narrates it" pattern already used throughout the repo.

## Languages & runtimes | version | evidence

| Item | Version / evidence |
|---|---|
| Primary content type | Markdown (agents/skills/docs) + Bash scripts. No compiled/application language at the repo root. |
| Shell | `#!/usr/bin/env bash` in every script under `tools/`, `workflow/hooks/`, `agents/install.sh`, `workspace/go` (e.g. `tools/repo-facts.sh:1`, `workflow/hooks/guard-artifacts.sh:1`, `agents/install.sh:1`) |
| Python | Only inside `prompts/mba-ia-prompt-engineering/*` and `prompts/prompt-library*/` — each chapter/library has its **own** `requirements.txt` (`prompts/mba-ia-prompt-engineering/1-tipos-de-prompts/requirements.txt`, `prompts/prompt-library/requirements-prompt-library.txt` at `prompts/requirements-prompt-library.txt`). No shared venv, no root Python manifest. This is course material, unrelated to the agent tooling. `.claude/toolbelt.md:12-14` states explicitly: "um venv e um `requirements.txt` por capítulo... Nunca instale dependência na raiz nem assuma um ambiente compartilhado." |
| No `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `*.csproj`, `pubspec.yaml`, `pom.xml`, `build.gradle` at the repo root | confirmed by exhaustive `find` — the only manifests in the whole tree are the per-chapter `requirements.txt` files listed above |
| Host git | `git version 2.34.1` (observed, `git --version` on this machine — not a repo constraint) |

## Frameworks & libraries | version | evidence

None. There is no application framework in this repository. What exists instead is a **domain
vocabulary of Claude Code primitives**:
- **Agents**: 24 Markdown files with YAML frontmatter (`name`, `description`, `skills`, `model`,
  `color`) under `agents/00-orchestration/` … `agents/07-incident/` (`agents/00-orchestration/project-analyst.md:1-8`), installed via symlink by `agents/install.sh`.
- **Skills**: directories containing `SKILL.md` with frontmatter (`name`, `description`,
  `argument-hint`, `allowed-tools`, `disable-model-invocation`, `user-invocable`) under `skills/`
  (`skills/sdlc/SKILL.md:1-8`, `skills/verify-live/SKILL.md:1-7`).
- **Hooks**: 3 Bash scripts wired through `.claude/settings.json` (`PreToolUse`, `PostToolUse`,
  `SessionStart`) — `workflow/hooks/guard-artifacts.sh`, `register-artifact.sh`, `sdlc-context.sh`
  (`.claude/settings.json:1-30`, `workflow/README.md:11-30`).

## Architecture style (observed)

**Not a software architecture** in the traditional sense — a **tooling/workflow repository** with
three cooperating layers, all observed directly in the tree and READMEs:

1. **`agents/`** — 27 role definitions (24 SDLC-phase agents + incident agents + orchestration),
   each a Markdown file with frontmatter, Mission/Method/Standards/Output-contract/Boundaries
   sections (`agents/00-orchestration/project-analyst.md`, full file). Installed as symlinks into
   `.claude/agents/` (`.gitignore:2-4`, `agents/install.sh:12-13`).
2. **`skills/`** — 16 procedures (`skills/README.md:16-38` lists them exactly), the largest being
   the `/sdlc` entry point that reads on-disk state and dispatches wave skills
   (`skills/sdlc/SKILL.md`, full file read).
3. **`workflow/hooks/`** — enforcement layer: `guard-artifacts.sh` denies writes outside an
   agent's assigned `docs/sdlc/<phase>/` directory by inspecting `agent_type` + `tool_input.file_path`
   from the hook JSON on stdin (`workflow/hooks/guard-artifacts.sh:1-90`, full file read).
4. **`tools/`** — 9 read-only Bash scripts the skills/agents shell out to
   (`tools/README.md:22-38` full table), e.g. `repo-facts.sh`, `diff-scope.sh`, `preview-env.sh`,
   `sdlc-state.sh`, `incident-evidence.sh`, `calibrate.sh`, `tracker.sh`, `git-conventions.sh`,
   plus the non-tool helper `_workspace.sh` (sourced, not called — `tools/README.md:15-16`).

**Key design fact for the Docker/devflow goal**: this repo explicitly declares itself "the
workshop" — no product work happens inside it. Actual projects are registered under
`workspace/projects/*.md` (gitignored, absolute local paths — `.gitignore:11-13`) and a session is
opened *inside the target project* via `./workspace/go <name>`, which symlinks
`<target>/.claude/ai-toolkit → this repo` and merges `workflow/settings.hooks.json` into the
target's `.claude/settings.json` (`workspace/go:170-233`, full `cmd_wire` function read;
`workspace/README.md:60-75`). So "git clone the project and run dev+exec entirely in Docker" is a
capability that would apply to **target projects reached through `workspace/go`**, not to this
repo's own code — there is no compiled/runnable artifact here to containerize.

## Persistence & migrations

None. No database driver, ORM, migration directory or schema file exists anywhere in the repo
(confirmed by the same manifest/tree search — no `*.sql`, `migrations/`, `prisma/`, `alembic/`,
etc. were found in the `find` output). Not applicable to this repository.

## Testing (frameworks, dirs, how to run)

- No test framework or test directory at the repo root. `.claude/toolbelt.md:19` states outright:
  "Não existe suíte de testes na raiz. `pytest` só funciona dentro dos capítulos que o declaram."
- The closest thing to "tests" for this repo's own artifacts is `agents/install.sh --check`, which
  validates: agent frontmatter (`name` kebab-case, unique, `description` present, `model` in an
  allowed set), skill frontmatter, the 500-line skill limit, and that every `` !`cmd` `` injection
  in a skill matches an `allowed-tools` pattern (`agents/install.sh:1-30` header comment;
  `workflow/README.md:96-107` "Portão de coerência das skills").
- Hooks are tested manually by piping JSON into them, documented with copy-pasteable examples
  (`workflow/README.md:73-92`, e.g. `echo '{"agent_type":"code-reviewer",...}' | bash workflow/hooks/guard-artifacts.sh`).
- `prompts/validate_prompt_libraries.py` validates the prompt libraries under `prompts/`
  (file exists at `prompts/validate_prompt_libraries.py`, not read in full — listed in tree only).

## Build & delivery (CI, containers, IaC)

- **No CI workflow** exists (`.github/workflows/` was not found in the tree listing).
- **No Dockerfile, docker-compose.yml/yaml, compose.yml/yaml, or `.devcontainer/` anywhere in the
  repo** — confirmed by an explicit recursive `find` for those names/patterns, which returned zero
  results.
- Every "docker" occurrence in the codebase is a **detection string inside a read-only script**,
  looking for Docker artifacts *in whatever project the script is run against* (a target project,
  via `workspace/go`), never describing this repo itself:
  - `tools/repo-facts.sh:91` — CI/infra file detector: `for c in .gitlab-ci.yml Jenkinsfile Dockerfile docker-compose.yml compose.yaml`
  - `tools/calibrate.sh:132` — CLI presence probe: `for cli in gh glab docker kubectl terraform`
  - `tools/calibrate.sh:141` — same CI/infra file list as above
  - `tools/diff-scope.sh:62` — risk-area regex: `'\.github/workflows|gitlab-ci|Dockerfile|compose|terraform|helm|k8s'`
  - `tools/incident-evidence.sh:33` — same risk-area regex
  - `skills/practices/mcp-toolbelt/detect-toolbelt.sh:174` — same CI/infra file list
  - `tools/preview-env.sh` (full file read) — the most relevant existing script: it is explicitly
    **read-only** ("NÃO sobe, NÃO derruba, NÃO altera nada" — `tools/preview-env.sh:3`), detects a
    `docker-compose.yml`/`compose.yaml` in the **target** project and prints the commands a human/
    agent should run (`docker compose up -d`, `ps`, `logs -f`, `down -v`), checks `docker compose ps`
    to see if something is already running, and falls back to `package.json` dev scripts, Python
    entrypoints (`manage.py`/`app.py`/`main.py`) or Maven. It never invokes `docker` to start
    anything itself — it hands the plan to `skills/verify-live/SKILL.md`, whose `allowed-tools`
    includes `Bash(docker compose *)` for the actual up/down (`skills/verify-live/SKILL.md:6`,
    Passo 1 and Passo 4 of that file).
- No IaC (Terraform/Helm/Ansible/CloudFormation) files were found anywhere in the tree.
- `agents/install.sh` (full header read) is the only "installer" in the repo, and it only creates
  symlinks from `agents/`/`skills/` into `.claude/` scope — it does not build, package, or containerize
  anything (`agents/install.sh:1-13`).

## Conventions (lint, format, commits, branching)

- **No linter/formatter config** for the Bash/Markdown content (no `.shellcheckrc`, `.editorconfig`,
  Prettier config found at the root). `agents/install.sh --check` runs `bash -n` (syntax check)
  on hooks (`workflow/README.md:71`, "`./agents/install.sh --check` roda `bash -n` em cada hook").
- **Shell script style**, observed consistently across `tools/*.sh` and `workflow/hooks/*.sh`:
  - `set -uo pipefail` in read-only `tools/` scripts that must never abort a caller
    (`tools/repo-facts.sh:13`, `tools/preview-env.sh:8`, `tools/git-conventions.sh:20`)
  - `set -euo pipefail` in the hooks and the installer, which are allowed to fail hard
    (`workflow/hooks/guard-artifacts.sh:13`, `agents/install.sh:12`)
  - Every script resolves its own directory via
    `SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"` before doing anything path-relative
    (`tools/repo-facts.sh:16`, `tools/git-conventions.sh:24`)
  - Portuguese comments explaining *why*, not *what*; English is reserved for `agents/*.md` bodies
    (all `agents/*.md` Mission/Method sections are in English, e.g.
    `agents/00-orchestration/project-analyst.md`, while `tools/`, `workflow/`, `skills/*.md` content
    is Portuguese)
  - Read-only tools never write, install, or touch the network — stated as an explicit rule and
    followed in every script inspected (`tools/README.md:5-6` "Todos são somente leitura. Nenhum
    instala, builda, acessa a rede ou altera arquivo.")
  - Hooks read JSON from stdin via `jq`, fail **open** (exit 0, no block) when `jq` is missing
    (`workflow/hooks/guard-artifacts.sh:15-18`)
- **Skill authoring convention** (`skills/README.md:41-49`, full "Convenções para adicionar uma
  skill" section): a directory with `SKILL.md`, unique directory name = command name, required
  frontmatter (`name`, `description` that states *when to use*), **hard 500-line cap** enforced by
  the installer, `disable-model-invocation: true` for side-effecting skills, `user-invocable: false`
  for background-knowledge skills, and packaged scripts invoked as
  `` !`${CLAUDE_SKILL_DIR}/script.sh` `` (pre-injected before the agent sees the content).
- **Commit/branch conventions**: not directly inspected in this pass (would require running
  `tools/git-conventions.sh`, which the task brief marked out of scope for me — I only ran
  read-only inventory commands). `.claude/toolbelt.md:16` states the git hosting is GitHub
  (`Joaooh98/ai`) and to use `gh`, not `glab` — confirmed independently by `git remote -v` →
  `https://github.com/Joaooh98/ai.git`.
- Recent commit subjects (from `git log`, visible in the session's `gitStatus`) follow
  Conventional-Commits-style prefixes: `feat(workspace): ...`, `feat: ...` — observed, not
  exhaustively verified against a written rule file.

## Docker / isolation / worktree / session tooling already in the repo

This is the section most relevant to the stated goal. Everything found:

| Artifact | What it actually does (read, not assumed) |
|---|---|
| `tools/preview-env.sh` | Read-only detector. Finds a compose file or dev-server script **in the target project**, prints the up/ps/logs/down commands, checks what's already running via `docker compose ps`. Does not itself start/stop anything. Explicitly the input to `verify-live`, not a dev-loop tool. |
| `skills/verify-live/SKILL.md` | Consumes `preview-env.sh`'s output to spin up a **temporary, disposable** environment (compose preferred), verify a change in a browser/endpoint, then **tear it down** (Passo 4: "Derrube o que subiu. Pare os containers, remova volumes temporários"). This is a one-shot verification flow, not a persistent dev/exec loop, and has no resilience-to-dropped-connection concept at all. |
| `tools/_workspace.sh` | Not Docker-related. Defines "workspace" (a non-git root containing multiple git repos) purely for `git`-based scripts to iterate members. Sourced by `repo-facts.sh`, `diff-scope.sh`, `incident-evidence.sh`, `detect-toolbelt.sh`. |
| `workspace/go` | The closest thing to "session management" in the repo, but it manages **Claude Code sessions on the host**, not containers: `cmd_open` does `cd "$target" && exec claude "$@"` (`workspace/go:230-231`) — a plain `exec`, replacing the current shell process, with no `tmux`/`screen`/`nohup` wrapper and no reconnection logic. If the terminal/SSH connection drops, the `claude` process dies with it — there is currently no protection against exactly the failure mode the goal wants to avoid. |
| `.claude/settings.json` | Only the 3 hooks (guard-artifacts, register-artifact, sdlc-context) — no Docker, no devcontainer, no session config (full file read, 30 lines). |
| `.mcp.json` | **Does not exist** in this repo (`find . -maxdepth 2 -iname '.mcp.json'` returned nothing) despite `.gitignore:15-16` explicitly saying it would be versioned if present ("`.mcp.json` NÃO está ignorado... deve ser versionado quando existir"). |
| MCP `MCP_DOCKER` server | Configured, but at **user/global** scope (`~/.claude.json`, confirmed present by `grep`), not in this repo. `.claude/toolbelt.md:17-18` records it explicitly as broken: "Servidores MCP `MCP_DOCKER` e `hostinger-*` estão cadastrados mas **não conectam** (verificado em 27/07/2026, `Connection closed`). Não conte com eles." Any new flow should not depend on this MCP server. |
| Devcontainer | No `.devcontainer/` directory, no `devcontainer` CLI on `$PATH` (`which devcontainer` returned nothing). |
| `.claude/worktrees/arch-conformance/` | An existing sibling worktree directory present on disk (untracked, per `gitStatus`), evidence that the git-worktree isolation pattern (the same one used to isolate *this* session) is already in active use for other work — but it is a host-level git worktree, unrelated to Docker containers. |

**Conclusion**: nothing in this repository already solves "clone + dev/run entirely in Docker,
resilient to dropped connections." The nearest building blocks are `preview-env.sh` (detection
only, no execution) and `verify-live` (execution, but one-shot and torn down at the end, the
opposite of a persistent dev loop). A new capability would need: (1) a script/skill to actually
launch and keep a container running (not just detect it), and (2) a session-persistence mechanism
(the host has none of `tmux`/`screen` installed — see below — so today `workspace/go`'s
`exec claude` is a single point of failure for any long session).

## How skills are discovered and invoked

- Skills live in this repo under `skills/<name>/SKILL.md` (source of truth, versioned — confirmed
  by the full directory listing in the first inventory pass).
- `agents/install.sh` (no args) creates **symlinks** from this repo's `skills/` (and `agents/`)
  into the current project's `.claude/skills/` and `.claude/agents/` (project scope), or into
  `~/.claude/skills/` / `~/.claude/agents/` with `--user` (`agents/install.sh` header comment,
  lines 1-13: "escopo projeto (.claude/)" vs "escopo usuário (~/.claude/) — sem hooks").
- `.gitignore:2-4` confirms `.claude/agents/`, `.claude/skills/`, `.claude/commands/` are generated
  symlinks and are gitignored in this repo — the versioned sources are `agents/`, `skills/`,
  `workflow/hooks/`.
- For **this session specifically**, running inside `.claude/worktrees/sdlc-docker-devflow`
  (a git worktree of the parent `ai` repo, confirmed by `.git:1` containing
  `gitdir: /home/smart/Documents/person/ai/.git/worktrees/sdlc-docker-devflow`), `/sdlc` resolved
  because the team is already installed at **user scope** (`~/.claude/skills/`,
  `~/.claude/agents/`) by a prior `agents/install.sh --user` run, not because this worktree itself
  was wired — worktrees don't get their own `.claude/ai-toolkit` symlink automatically; only
  `workspace/go` or `agents/install.sh` create that.
- **Consequence for the stated goal**: a new Docker/devflow artifact needs to be written as source
  under this repo's `agents/`, `skills/`, `tools/`, or `workflow/hooks/` (so `install.sh`/`go` can
  distribute it to target projects) — writing it directly into `.claude/skills/` anywhere would be
  writing into a generated/gitignored symlink target and would not survive a reinstall.

## Host tooling available (this machine, observed via direct commands)

| Command | Output |
|---|---|
| `docker --version` | `Docker version 29.6.2, build dfc4efb` |
| `docker compose version` | `Docker Compose version v2.22.0-desktop.2` |
| `docker info --format '{{.ServerVersion}} {{.OperatingSystem}}'` | `24.0.6 Docker Desktop` |
| `git --version` | `git version 2.34.1` |
| `tmux -V` | **not found** (`/bin/bash: line 14: tmux: command not found`) |
| `screen --version` | **not found** (`/bin/bash: line 15: screen: command not found`) |
| `which devcontainer` | empty — not installed |
| `nproc` | `12` |
| `free -h` | total `23Gi`, used `12Gi`, free `6.6Gi`, available `8.0Gi`, swap `2.0Gi` total / `1.9Gi` used |
| `df -h /` | `468G` size, `411G` used, `34G` avail, **93% used** |

Note the `docker --version` (29.6.2) vs `docker info` ServerVersion (24.0.6) mismatch and "Docker
Desktop" as the reported OS — this is a Docker Desktop (likely WSL2/VM-backed) install, not a bare
Linux dockerd; this affects volume-mount performance and networking assumptions for any devflow
design. **Disk is at 93% on `/`** — relevant risk for a design that clones repos and builds images
inside containers, since image layers and clones will consume this same filesystem unless routed
elsewhere.

## Constraints & risks

- **No `tmux`/`screen` on this host** — any "survive a dropped connection" design cannot assume a
  terminal multiplexer is available; it must either depend on `docker`/`docker compose` itself
  running detached (containers keep running after the client disconnects, which is Docker's normal
  behavior) or explicitly install/require one of those tools.
- **`93% disk usage on /`** is a real constraint for a flow that clones repositories and builds
  images — worth flagging to whoever designs the flow, not just noting.
- **No CI, no lint config, no test suite at the root** — any new script can only be validated by
  `agents/install.sh --check` (frontmatter/line-count/allowed-tools coherence) and manual
  `bash -n` / piped-JSON testing, matching the pattern in `workflow/README.md:73-92`.
- **`workflow/hooks/guard-artifacts.sh`** enforces per-agent write boundaries by `agent_type` +
  path (full logic read above). Any new agent added for this goal (e.g. a "docker-devflow" role)
  would need an explicit entry in that `case` statement, or it falls through to "no restriction"
  (the `*) exit 0 ;;` branch, `workflow/hooks/guard-artifacts.sh` end) — meaning by default a new
  agent has **no** write restriction unless deliberately added.
- **MCP `MCP_DOCKER` is configured but non-functional** (`.claude/toolbelt.md:17-18`, "Connection
  closed", verified 2026-07-27) — do not design the flow around it; use the `docker`/`docker
  compose` CLI directly, consistent with how `preview-env.sh` and `verify-live` already do it.
- **No secrets, credentials, or `.env` files were found** in the repo tree during this scan;
  `.gitignore` shows deliberate care around what's versioned (worktrees, local settings, project
  registry with absolute paths are all excluded — `.gitignore` full file read).
- **This repo is explicitly not meant to contain product work** (`.claude/toolbelt.md:9-10`,
  `README.md:14`) — if the intended goal is to run *this* repo's own future application code in
  Docker, that would contradict the stated purpose; if the goal is a **tool that this repo ships**
  for cloning/running *other* people's projects in Docker (my reading, based on the phrasing "faz
  git clone do projeto" mirroring `workspace/go`'s own vocabulary), it fits the existing
  `tools/` + `skills/` + `workflow/hooks/` pattern well.
- **Sandbox note for this analysis**: I ran only read-only commands (`find`, `cat`, `grep`, version
  probes, `docker info`) as instructed — I did not run `git-conventions.sh`, `calibrate.sh`, or any
  build/install command, and did not start or stop any container.

## Unknowns (and how to resolve them)

1. **Exact commit/branch convention** (Conventional Commits enforcement, required branch prefix,
   whether MRs are mandatory) — not verified against a rule file. Resolve by running
   `tools/git-conventions.sh --resumo` (read-only, ~ms cost, documented in `tools/README.md`).
2. **Whether Docker Desktop's WSL2/VM backend vs a native Linux dockerd matters for the intended
   design** — I only captured the version strings; did not inspect `docker context ls` or the VM
   configuration. Resolve with `docker context ls` and `docker info` (full output, not just the
   formatted line) if bind-mount performance or rootless/rootful behavior becomes a design
   constraint.
3. **Whether any other worktree in `.claude/worktrees/` (e.g. `arch-conformance`) already contains
   in-progress Docker/devflow work that should be reconciled** — I saw the directory exists
   (untracked per `gitStatus`) but did not read its contents, since it's outside this worktree and
   out of scope for a read-only profile of `sdlc-docker-devflow`. Resolve by listing that worktree's
   diff/branch before the design phase, to avoid duplicate work.
4. **Root cause of the `MCP_DOCKER` "Connection closed" failure** — not investigated (would require
   write/network actions outside this agent's read-only mandate). Resolve with `claude mcp list`
   and, if the user wants it, reconfiguration — but per `.claude/toolbelt.md:18`, do not attempt
   this without being asked.
5. **`prompts/validate_prompt_libraries.py` and the prompt-library `registry.yaml` schemas** were
   located but not read in full — irrelevant to the stated Docker/devflow goal, so left
   unexamined; flagging only so it isn't mistaken for a gap.

## Recommended specialist agents

- **`solution-architect`** — to decide the actual shape of the new capability (new `tools/*.sh` +
  skill vs. a new agent role vs. extending `verify-live`/`preview-env.sh`), given there is no
  existing partial implementation to extend cleanly.
- **`devops-engineer`** — owns containerization/CI conventions in this team's own taxonomy
  (`agents/05-delivery/devops-engineer.md`, full file read) and is the natural implementer once
  the architecture is decided; its existing Standards ("Everything that runs in CI must be runnable
  locally with one documented command", "No manual step... every manual gate is documented") map
  directly onto a resilient clone-and-run-in-Docker flow.
- **`threat-modeler`** — a flow that clones arbitrary repos and runs them in Docker is new external
  input + code execution surface; worth a STRIDE pass before build, per this team's own convention
  of threat-modeling new external-input surfaces.
- **`sre-observability`** — "don't lose work when the connection drops" is a resilience/operability
  requirement (detached execution, log persistence, recoverable state) squarely in this agent's
  mandate.
