# Ralph

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that runs AI coding agents repeatedly until all PRD items are complete. Each iteration is a fresh agent instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Supported CLI tools: [Amp](https://ampcode.com), [OpenCode](https://opencode.ai), Mino, MiMo, Kilo, [Pi](https://github.com/agentics-ai/pi), [Agy](https://agy.sh), [Command Code](https://commandcode.ai), [Codex](https://github.com/openai/codex), and [GitHub Copilot](https://docs.github.com/copilot/how-tos/copilot-cli).

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

[Read my in-depth article on how I use Ralph](https://x.com/ryancarson/status/2008548371712135632)

## Prerequisites

- One of the supported CLI tools installed and authenticated:
  - [Amp CLI](https://ampcode.com)
  - [OpenCode CLI](https://opencode.ai)
  - Mino / MiMo / Kilo CLI
  - [Pi CLI](https://github.com/agentics-ai/pi)
  - [Agy CLI](https://agy.sh)
  - [Command Code CLI](https://commandcode.ai)
  - [Codex CLI](https://github.com/openai/codex)
  - [GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli)
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Setup

### Option 1: Copy to your project

Copy the ralph files into your project:

```bash
# From your project root
mkdir -p scripts/ralph
cp /path/to/ralph/ralph.sh scripts/ralph/
cp /path/to/ralph/prompt-*.md scripts/ralph/
chmod +x scripts/ralph/ralph.sh
```

Check usage here for OpenCode https://github.com/snarktank/ralph/pull/21

### Option 2: Install skills globally

Copy the skills to your Amp config for use across all projects:

```bash
cp -r skills/prd ~/.config/amp/skills/
cp -r skills/ralph ~/.config/amp/skills/
```

### Configure Amp auto-handoff (recommended)

Add to `~/.config/amp/settings.json`:

```json
{
  "amp.experimental.autoHandoff": { "context": 90 }
}
```

This enables automatic handoff when context fills up, allowing Ralph to handle large stories that exceed a single context window.

## Workflow

### 1. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
Load the prd skill and create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph format

Use the Ralph skill to convert the markdown PRD to JSON:

```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
# Default: Amp with 10 iterations
./scripts/ralph/ralph.sh

# Specify iterations and CLI tool
./scripts/ralph/ralph.sh [max_iterations] [cli_tool] [model] [share]

# Examples:
./scripts/ralph/ralph.sh 5 opencode                          # OpenCode
./scripts/ralph/ralph.sh 10 mimo mimo/mimo-auto true          # MiMo
./scripts/ralph/ralph.sh 10 kilo kilo/kilo-auto true          # Kilo
./scripts/ralph/ralph.sh 10 pi google/gemini-2.0-flash        # Pi
./scripts/ralph/ralph.sh 10 pi claude-sonnet:high             # Pi with thinking
./scripts/ralph/ralph.sh 10 agy claude-sonnet                 # Agy
./scripts/ralph/ralph.sh 10 cmd claude-sonnet                 # Command Code
./scripts/ralph/ralph.sh 10 codex o3                          # Codex
./scripts/ralph/ralph.sh 10 copilot gpt-5.2                   # Copilot
```

Default is 10 iterations with Amp.

Ralph will:
1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
   - If `knownIssues` exist, prioritize stories that resolve them
3. Implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh agent instances |
| `prompt-amp.md` | Instructions for Amp CLI |
| `prompt-opencode.md` | Instructions for OpenCode CLI |
| `prompt-mino.md` | Instructions for Mino/MiMo/Kilo CLI |
| `prompt-pi.md` | Instructions for Pi CLI |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `skills/prd/` | Skill for generating PRDs |
| `skills/ralph/` | Skill for converting PRDs to JSON |
| `flowchart/` | Interactive visualization of how Ralph works |

## Flowchart

[![Ralph Flowchart](ralph-flowchart.png)](https://snarktank.github.io/ralph/)

**[View Interactive Flowchart](https://snarktank.github.io/ralph/)** - Click through to see each step with animations.

The `flowchart/` directory contains the source code. To run locally:

```bash
cd flowchart
npm install
npm run dev
```

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new Amp instance** with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Ralph updates the relevant `AGENTS.md` files with learnings. This is key because Amp automatically reads these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

Examples of what to add to AGENTS.md:
- Patterns discovered ("this codebase uses X for Y")
- Gotchas ("do not forget to update Z when changing W")
- Useful context ("the settings panel is in component X")

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Browser Verification for UI Stories

Frontend stories must include "Verify in browser using dev-browser skill" in acceptance criteria. Ralph will use the dev-browser skill to navigate to the page, interact with the UI, and confirm changes work.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Debugging

Check current state:

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Customizing prompt.md

Edit `prompt.md` to customize Ralph's behavior for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Amp documentation](https://ampcode.com/manual)
