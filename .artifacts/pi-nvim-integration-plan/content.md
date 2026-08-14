# Pi + Neovim Integration Plan

## Goal

Build a versatile, simple, solid Neovim integration for `pi` that upgrades the current `lua/mlamkadm/core/pi.lua` terminal wrapper into a real editor-native agent surface, without turning Neovim into a bloated IDE client.

## Current State

Existing file:

- `lua/mlamkadm/core/pi.lua`

Current behavior:

- `:Pi <prompt>` dumps smart buffer context to a temp file and opens `pi @file "prompt"` in a terminal split.
- `:PiSelection` sends visual selection.
- `:PiPrompt` picks a prompt from registry or `~/.pi/agent/prompts`.
- Keymaps: `<leader>pi`, visual `<leader>pi`, `<leader>pp`.

This is useful but coarse:

- no persistent RPC session
- no structured streaming
- no request/response correlation
- no session/model control
- no extension UI handling
- no clean diff/edit review loop

## Recommended Architecture

Use `pi --mode rpc` as the integration boundary.

Reason:

- Official, documented JSONL protocol.
- Process-isolated; no Node embedding inside Neovim.
- Supports streaming events, sessions, model control, abort, compaction, command discovery, extension UI requests, tool execution events.
- Lua can speak JSONL over `vim.system`/`vim.uv` pipes.

Avoid for v1:

- Node daemon wrapping the SDK.
- Full custom frontend replacing Pi TUI.
- Inline completion. That is a separate problem and conflicts with Copilot/LSP completion surfaces.

## Design Principles

1. **Project-scoped session by default**
   - One Pi RPC subprocess per project root/CWD.
   - Reuse until explicitly killed.
   - Session name: `nvim:<project-name>`.

2. **Editor sends context, Pi owns reasoning/tools**
   - Neovim gathers buffer/selection/diagnostics/git context.
   - Pi reads/writes/runs commands via its existing tools.
   - Do not duplicate Pi tools in Lua.

3. **Review before mutation**
   - Pi may edit files through its tools, but Neovim should expose changed files/diff after run.
   - No auto-apply overlay edits in v1.

4. **Small Lua surface**
   - `client.lua`: subprocess + JSONL + request IDs.
   - `context.lua`: buffer/selection/LSP/git context builders.
   - `ui.lua`: chat buffer/floats/status rendering.
   - `commands.lua`: user commands/keymaps.

5. **Graceful degradation**
   - If RPC fails, fall back to existing terminal wrapper.
   - If no project root, use current working directory.

## Proposed Module Layout

```text
lua/mlamkadm/pi/
  init.lua          -- setup(), public API
  client.lua        -- Pi RPC process, JSONL framing, send/request/event dispatch
  context.lua       -- buffer, selection, diagnostics, git, tree context builders
  ui.lua            -- chat buffer, floating prompt, streaming renderer, status
  commands.lua      -- :Pi*, keymaps
  sessions.lua      -- session registry per root, restart/stop/status
  extui.lua         -- Pi RPC extension_ui_request handling
  diff.lua          -- post-run changed-file detection + git diff picker
```

Keep `lua/mlamkadm/core/pi.lua` as compatibility shim:

```lua
return require("mlamkadm.pi")
```

## Core RPC Client

Start command:

```bash
pi --mode rpc --name nvim:<project> --session-dir ~/.pi/agent/sessions
```

Optional default flags:

```bash
--models "opencode-go/minimax-m3,openai-codex/gpt-5.5,deepseek/deepseek-v4-pro"
```

Client responsibilities:

- spawn process with cwd = project root
- write commands as strict JSONL
- parse stdout by `\n` only
- correlate `{id,type=response}` with callbacks
- route events to UI subscribers
- restart on crash with visible notification
- send `abort` on user cancel

Important RPC commands to support first:

- `prompt`
- `steer`
- `follow_up`
- `abort`
- `get_state`
- `get_last_assistant_text`
- `get_session_stats`
- `get_available_models`
- `set_model`
- `cycle_model`
- `cycle_thinking_level`
- `compact`
- `get_commands`

## Context Model

Context modes:

1. `selection`
   - visual selection + file path + line range

2. `buffer`
   - current buffer if below threshold
   - otherwise visible window range + symbol/function around cursor

3. `workspace-light`
   - current file
   - open buffers
   - diagnostics summary
   - git branch/status
   - nearby files from project root

4. `workspace-heavy`
   - explicitly requested only
   - runs local rg/find commands through Pi or Neovim before prompt

Prompt envelope example:

```md
<nvim_context>
project_root: /path
file: src/foo.c
cursor: 120:9
selection: 118-132
mode: selection
</nvim_context>

<user_request>
Refactor this for clearer ownership semantics.
</user_request>

<selected_code>
...
</selected_code>
```

## UI Surfaces

### 1. Quick Ask

Command:

```vim
:PiAsk [prompt]
```

Keymaps:

```text
<leader>pa   Pi ask with smart buffer context
<leader>pa   visual: Pi ask with selection
```

Behavior:

- prompt via `vim.ui.input` if no args
- opens/updates Pi chat buffer
- streams assistant text

### 2. Chat Buffer

Command:

```vim
:PiChat
```

Keymap:

```text
<leader>pc
```

Buffer type: `nofile`, filetype `markdown`.

Controls:

```text
i / a       edit prompt line
<CR>        send current prompt block
<C-c>       abort current run
q           close window
```

### 3. Selection Actions

Command:

```vim
:'<,'>PiSelection [prompt]
```

Keymaps:

```text
<leader>pe   explain selection
<leader>pr   refactor selection
<leader>pt   generate tests for selection
<leader>pf   fix selection / diagnostics
```

These are prompt-template wrappers over the same RPC client.

### 4. Session Controls

Commands:

```vim
:PiStatus
:PiAbort
:PiRestart
:PiCompact
:PiModel
:PiCommands
```

Keymaps:

```text
<leader>ps   status
<leader>px   abort
<leader>pm   cycle model
<leader>pM   pick model
<leader>pk   compact
```

### 5. Diff Review

Command:

```vim
:PiDiff
```

Keymap:

```text
<leader>pd
```

Behavior:

- show changed files from `git diff --name-only`
- open split diff for selected file
- no staging, no deletion, no blind apply

## Extension UI Handling

Pi RPC emits `extension_ui_request` for extension dialogs.

Handle minimally:

- `notify` -> `vim.notify`
- `setStatus` -> statusline/global state
- `select` -> `vim.ui.select`
- `confirm` -> `vim.ui.select({"Yes", "No"})`
- `input` -> `vim.ui.input`
- `editor` -> scratch floating buffer, send contents on close/submit

This makes existing Pi extensions usable from Neovim.

## Commands/API Sketch

```lua
require("mlamkadm.pi").setup({
  command = "pi",
  mode = "rpc",
  session = "project",
  context = {
    max_full_buffer_lines = 250,
    include_diagnostics = true,
    include_git = true,
    include_open_buffers = true,
  },
  ui = {
    layout = "right", -- right | bottom | float
    width = 0.38,
    height = 0.35,
  },
  fallback_terminal = true,
})
```

## Implementation Phases

### Phase 0 — Preserve Current Wrapper

- Move current `core/pi.lua` behavior behind `legacy_terminal.lua`.
- Keep existing commands working.
- Add health check: `pi --help` and `pi --mode rpc --no-session` smoke validation manually/offline where possible.

### Phase 1 — RPC Spine

Files:

- `lua/mlamkadm/pi/client.lua`
- `lua/mlamkadm/pi/sessions.lua`

Deliver:

- spawn Pi RPC
- send `get_state`
- send `prompt`
- stream `text_delta` to a callback
- abort support
- restart support

Verification:

- open Neovim
- `:PiStatus` returns state
- `:PiAsk hello` streams response
- `:PiAbort` cancels run

### Phase 2 — Context + Commands

Files:

- `context.lua`
- `commands.lua`
- `init.lua`

Deliver:

- smart context builder
- current buffer/selection support
- commands/keymaps
- prompt template actions

Verification:

- visual selection round trip
- large file uses visible range, not full dump
- no crash on unnamed/terminal buffers

### Phase 3 — Real UI

Files:

- `ui.lua`

Deliver:

- markdown chat buffer
- streaming text append
- tool execution status lines
- queue/status indicators

Verification:

- multiple prompts append correctly
- switching buffers does not corrupt stream
- process death is visible and recoverable

### Phase 4 — Extension UI + Diff Review

Files:

- `extui.lua`
- `diff.lua`

Deliver:

- `extension_ui_request` support
- `:PiDiff`
- changed-file picker

Verification:

- extension confirm/select/input roundtrip
- diff view opens after Pi edits
- no auto staging

### Phase 5 — Polish

- README / KEYMAPS.md update
- `:checkhealth pi_nvim`
- configurable model list
- session picker from Pi `get_tree` / sessions later

## Non-Goals for First Cut

- Inline completion.
- Replacing Copilot suggestions.
- Building a full Neovim clone of Pi TUI.
- Direct SDK embedding.
- Auto-applying generated patches from chat text.

## Minimal First Milestone

The smallest valuable version:

```text
:PiChat
:PiAsk
:PiSelection
:PiStatus
:PiAbort
```

Backed by:

```text
client.lua + context.lua + ui.lua + commands.lua
```

This gives real Pi sessions inside Neovim while keeping the system understandable and recoverable.



---

# Revision: Primitive-First Direction

The previous plan jumped too early to a Pi-specific RPC surface. Better architecture: build general Neovim primitives/helpers first, then Pi becomes a thin consumer. This lowers risk and creates reusable substrate for other agents/tools: Copilot CLI, Qwen, Gemini, local scripts, future MK3 clients, etc.

## New Priority

Before implementing `mlamkadm.pi`, create a reusable local framework under:

```text
lua/mlamkadm/lib/
```

Pi integration should only depend on these primitives, not reinvent them.

## Primitive Layers

### 1. Path + Project Primitives

File:

```text
lua/mlamkadm/lib/project.lua
```

Responsibilities:

- find project root from LSP/git/markers/CWD
- stable project ID/hash
- safe path normalization
- relative path helpers
- data/cache/temp paths per project

Useful consumers:

- terminal sessions
- Pi sessions
- prompt/context artifacts
- per-project state

### 2. Buffer + Range Primitives

File:

```text
lua/mlamkadm/lib/buffer.lua
```

Responsibilities:

- current buffer metadata
- unnamed/special buffer guards
- full buffer text with size caps
- visible range extraction
- visual selection extraction, including charwise/linewise/blockwise later
- cursor location
- save/modified state checks

### 3. Diagnostics + LSP Context

File:

```text
lua/mlamkadm/lib/diagnostics.lua
```

Responsibilities:

- collect diagnostics for current buffer/range/workspace
- format as compact text/markdown
- LSP client names/capabilities
- symbol/function around cursor if available

### 4. Git Primitives

File:

```text
lua/mlamkadm/lib/git.lua
```

Responsibilities:

- detect repo root/branch
- porcelain status
- changed files
- current file diff
- safe shell escaping through shared process layer

### 5. Process / Job Primitives

File:

```text
lua/mlamkadm/lib/process.lua
```

Responsibilities:

- async spawn wrapper around `vim.system` or `vim.uv`
- stdout/stderr streaming callbacks
- cancellation
- exit status handling
- cwd/env support
- process registry

This is the foundation for Pi RPC, terminal-adjacent tools, local scripts, and command runners.

### 6. JSONL / Framing Primitives

File:

```text
lua/mlamkadm/lib/jsonl.lua
```

Responsibilities:

- encode/decode JSON lines
- LF-only framing
- incremental parser for chunked stdout
- malformed line reporting

This directly supports Pi RPC but stays general.

### 7. Event Bus / PubSub

File:

```text
lua/mlamkadm/lib/events.lua
```

Responsibilities:

- subscribe/unsubscribe/emit
- once listeners
- namespaced events
- scheduled-safe event delivery

Useful for streaming UI, process updates, session changes, diagnostics refresh.

### 8. UI Primitives

Files:

```text
lua/mlamkadm/lib/ui/window.lua
lua/mlamkadm/lib/ui/scratch.lua
lua/mlamkadm/lib/ui/picker.lua
lua/mlamkadm/lib/ui/input.lua
lua/mlamkadm/lib/ui/notify.lua
```

Responsibilities:

- floating/split window helper
- scratch markdown/log buffers
- append/replace buffer text safely
- common keymap setup
- picker abstraction: snacks -> telescope -> vim.ui.select fallback
- input abstraction
- notify abstraction

This avoids every tool creating one-off UI code.

### 9. Command Registry

File:

```text
lua/mlamkadm/lib/commands.lua
```

Responsibilities:

- define user commands consistently
- define keymaps consistently
- group descriptions
- later: expose searchable command palette entries

### 10. Context Builder

File:

```text
lua/mlamkadm/lib/context.lua
```

Responsibilities:

- compose project/buffer/range/diagnostics/git into structured context
- output markdown/xml-ish envelopes
- enforce size budgets
- reusable by Pi, Gemini explain, future agents

## After Primitives: Pi Becomes Thin

Then `lua/mlamkadm/pi/` becomes mostly:

```text
client.lua    -- Pi-specific RPC commands/events
sessions.lua  -- project-scoped Pi clients using lib.project + lib.process
commands.lua  -- :PiAsk/:PiChat wrappers
ui.lua        -- mostly calls lib.ui.scratch/window
```

No Pi module should own generic range extraction, floating window code, JSONL parsing, git status formatting, or process management.

## Better Milestones

### Milestone A — Base Lib

Implement:

```text
lib/project.lua
lib/buffer.lua
lib/ui/window.lua
lib/ui/scratch.lua
lib/ui/picker.lua
lib/process.lua
lib/jsonl.lua
```

Verify with simple dev commands, not Pi.

### Milestone B — Context Lib

Implement:

```text
lib/diagnostics.lua
lib/git.lua
lib/context.lua
```

Verify by dumping context to a scratch buffer.

Example command:

```vim
:NvimContext
```

### Milestone C — Generic Stream UI

Implement scratch log/chat buffer that can consume any stream.

Example command:

```vim
:StreamCmd ping -c 4 archlinux.org
```

### Milestone D — Pi RPC MVP

Only now implement Pi:

```vim
:PiStatus
:PiAsk
:PiAbort
```

The MVP should mostly wire Pi RPC into already-tested primitives.

## Design Constraint

If a helper could be used by a non-Pi tool, it belongs in `mlamkadm.lib`, not `mlamkadm.pi`.



---

# Plan: Project-Scoped Pi Session Management (v0 Primitive)

This is the first concrete deliverable. It is intentionally narrow and ships before any chat UI, RPC commands, or context builders. Goal: Pi processes are managed the way your terminals are managed — tied to the nvim project session, surviving buffer/window churn, closable via picker, restorable on relaunch.

## Scope (v0)

- General "managed subprocess session" abstraction in `mlamkadm.lib.session`.
- Pi is the first consumer: `mlamkadm.pi.sessions`.
- Hooks into the existing `auto-session` lifecycle (you already have one Pi-free session layer; do not fork it).
- One nvim instance owns all sessions; no inter-process locking.
- Sessions outlive buffer switches, splits, file edits.
- Sessions die only on explicit close, session save (with intent to leave), or nvim exit.
- Picker for inspecting/closing sessions. No statusline HUD, no chat panel.

## Non-Goals (deferred)

- Chat UI, prompt input, streaming renderer.
- Context builders, JSONL parsing, RPC commands (all come after this lands).
- Multi-nvim attach, distributed registry, file locks.
- Inline completion, accept/reject of suggested edits.
- "Main session" semantics. (Decide later if needed; data model leaves room.)

## Mental Model

```text
nvim project session (auto-session, one per CWD)
  └── mlamkadm.lib.session registry
        ├── pi:work      (Pi RPC subprocess, project A)
        ├── pi:play      (Pi RPC subprocess, project B)
        └── future agent runtimes plug in here
```

Each `mlamkadm.lib.session` entry is one live subprocess bound to a logical name. In v0 the only logical names are Pi clients, keyed by project root hash.

## Module Layout

```text
lua/mlamkadm/lib/
  session.lua           -- registry, lifecycle, picker, hooks
  project.lua           -- project root detection, stable id
  process.lua           -- async spawn/stream/cancel (used by session.lua)
  events.lua            -- pub/sub for session state changes

lua/mlamkadm/pi/
  sessions.lua          -- thin Pi-specific adapter on lib.session
```

The two layers communicate via:

- `lib.session.register({ name, cmd, args, cwd, env, on_stdout, on_stderr, on_exit, on_error })`
- `lib.session.list()`
- `lib.session.get(name)`
- `lib.session.close(name)`
- `lib.session.attach(name)`  -- bring forward in some future UI; for v0 it just returns the handle

The session registry never knows it is talking to Pi. `pi.sessions` wraps these calls and supplies Pi-specific argv/env defaults.

## Lifecycle Hooks

The registry integrates with `auto-session` via the same `pre_save_cmds` / `post_restore_cmds` hook surface that `core.terminal` already uses.

```text
auto-session post_restore_cmds
  -> mlamkadm.lib.session.restore_for_cwd(cwd)
     -> for each session whose cwd == this project root, ensure subprocess is running
     -> if session was running pre-save, respawn with the saved argv

auto-session pre_save_cmds
  -> mlamkadm.lib.session.persist_for_cwd(cwd)
     -> capture argv/pid/uptime/state of every session under this project
     -> DO NOT kill the process; just snapshot

nvim VimLeavePre
  -> mlamkadm.lib.session.shutdown_all()
     -> graceful: send shutdown signal if available, else SIGTERM, then SIGKILL after grace
```

Key rule: **session save ≠ session close.** The process keeps running across buffer/session churn. Only nvim exit or explicit user close kills it.

## Session Record Shape

```lua
{
  id        = "pi:01HMR...",  -- internal uuid
  name      = "pi:clevercore",-- user-facing label
  kind      = "pi",           -- or future: "qwen", "gemini", "shell"
  pid       = 42311,
  cmd       = "pi",
  args      = { "--mode", "rpc", "--name", "nvim:clevercore" },
  cwd       = "/home/.../clevercore",
  env       = { PI_OFFLINE = "0" },
  state     = "running" | "starting" | "stopped" | "crashed" | "closing",
  started_at = 1730000000,
  last_event_at = 1730000123,
  meta      = { model = "openai-codex/gpt-5.5", thinking = "high" }, -- optional
}
```

`meta` is opaque to the registry. Pi uses it for display; future agents use their own fields.

## Project Binding

`lib.project`:

- `find_root(cwd)`: walk up looking for `.git`, `Cargo.toml`, `package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, fallback to CWD.
- `id(root)`: short stable hash, used to scope per-project resources.
- `paths(root)`: returns `{ root, data, cache, temp, log }` under `vim.fn.stdpath("data") .. "/mlamkadm/<id>"`.

This means every project has:

- one persistent data dir (Pi session artifacts later)
- one cache dir (git snapshots, diagnostic snapshots)
- one temp dir (context files, scratch)
- one log dir (per-session logs)

`data/` is the place `auto-session` already targets via `stdpath("data")`. No new top-level directory sprawl.

## Default Pi Session Per Project

On first nvim launch in a project CWD, the registry should ensure exactly one Pi session is alive for that project. Behavior:

- name: `pi:<project>` where `<project>` = `fnamemodify(root, ":t")` (cleaned).
- cwd: project root.
- args: `["--mode", "rpc", "--name", "nvim:<project>"]`.
- env: inherits nvim env, optionally injects `PI_OFFLINE=1` if `vim.g.pi_offline` set.

Re-entering the same project does not respawn; existing process is reused. If the process crashed, the registry marks it `crashed` and respawns on next `:PiStatus` or auto-restore.

## User-Facing Commands (v0 only)

```text
:PiSession list      -> opens picker with all live sessions
:PiSession status    -> echo one-line summary for the project Pi session
:PiSession start     -> ensure project Pi session is running
:PiSession stop      -> graceful stop of project Pi session (not unload nvim)
:PiSession restart   -> stop + start
:PiSession logs      -> open log file for the project Pi session
```

Also expose a generic:

```text
:Session list
:Session close <name>
:Session logs <name>
:Session kill <name>     -- SIGKILL, with type_confirm
```

Picker (Telescope or snacks, depending on what is loaded — `lib.ui.picker` handles the fallback):

```text
Session            State     PID    Uptime   CWD
pi:clevercore      running   42311  00:42:11 /home/.../clevercore
pi:playground      crashed   -      -        /home/.../playground
```

Actions from the picker:

- `Enter` — open logs.
- `dd` — close (graceful).
- `D` — kill (force).
- `r` — restart.

No chat, no prompts, no UI panel. Just process bookkeeping.

## UX Quality Bar

This is the part you care about. Concrete commitments:

- **No chrome fatigue.** No statusline line, no float, no buffer that opens on its own. Sessions are silent until you ask.
- **No surprise kills.** Buffer `bd` does not touch the process. `:q` does not touch the process. Only `:PiSession stop`, picker `dd`, or nvim exit do.
- **Restart on nvim relaunch is automatic.** If you exited with sessions alive, they come back when you `cd` into the project (via `auto-session` `post_restore_cmds`). No manual step.
- **Pickers are searchable, not modal walls.** Fuzzy filter on name, cwd, state.
- **Logs are first-class.** A crashed Pi with no easy log access is a workflow killer. `:PiSession logs` opens a tail-following buffer (no auto-follow if you scroll up; resumes on `G`).
- **No silent failures.** Spawn errors, premature exits, and non-zero exits notify via `vim.notify` once. Repeated crashes escalate with count and backoff.
- **Idempotent commands.** `:PiSession start` on a running session is a no-op (with a one-line notice if verbose).
- **Cancellation is real.** `:PiSession stop` waits up to N seconds for graceful shutdown, then forces. Configurable grace period, default 3s.
- **No race between auto-session restore and Pi spawn.** `post_restore_cmds` runs after buffers are restored; Pi spawn happens there, never in `BufRead`.

## Failure & Recovery

| Failure | Detection | Reaction |
|---|---|---|
| Pi binary missing | spawn ENOENT | `vim.notify` "pi not found" with install hint, do not retry. |
| Pi exits non-zero during run | on_exit callback | mark `crashed`, notify once, keep log path, do not auto-respawn mid-session. |
| Pi killed by signal | on_exit with signal | mark `crashed`, log signal, do not auto-respawn. |
| Stdin pipe breaks | write error from lib.process | send shutdown, mark `crashed`. |
| nvim crash | VimLeavePre does not run | sessions are leaked. Acceptable for v0; document it. |
| Multiple Pi sessions for same project | dedup on (kind, project_id) | refuse to register a second, log a warning. |
| Registry corruption on disk | json decode failure | start with empty registry, log warning, do not crash. |

## What This Plan Does Not Touch Yet

- `:PiAsk`, `:PiChat`, `:PiSelection`, streaming — Phase 5+ in the parent plan.
- Context builders, JSONL framing — Phase 4+ in the parent plan.
- Extension UI handling — Phase 4+ in the parent plan.
- Diff review — Phase 4+ in the parent plan.

This is deliberately the smallest useful thing: a process registry that respects your existing nvim session model, with Pi as the proving consumer.

## Acceptance Checklist (Definition of Done for v0)

1. `lib.session` is a generic registry with no Pi imports in it. Verified by reading the file.
2. `pi.sessions` is the only place that knows Pi's argv. Verified by reading the file.
3. Entering a project auto-starts exactly one Pi RPC subprocess for that project. Verified by `ps` after `cd`.
4. Switching to another project does not kill the first. Verified by `ps` after `:cd`.
5. Quitting and relaunching nvim in the same project restores the Pi session. Verified by `ps`.
6. `:PiSession stop` on a running Pi exits cleanly; `:PiSession start` brings it back. Verified by `ps`.
7. `:Session kill` with type_confirm "KILL" sends SIGKILL. Verified by `ps` showing the process is gone.
8. Picker lists all sessions with state, PID, uptime, cwd. Verified by hand.
9. `:PiSession logs` opens the log; `G` follows. Verified by hand.
10. Killing the Pi process externally (e.g. `kill`) flips state to `crashed` in the registry within 1s and shows a single notification. Verified by hand.
11. `pi --mode rpc` handshake is not required for this milestone. The subprocess is started; the RPC client (Phase 4+) is what actually uses it.
12. `auto-session` `post_restore_cmds` includes a call to `lib.session.restore_for_cwd`. Verified by reading the updated `plugs/session.lua`.

## Open Decisions That Can Wait

- "Main session" semantics: not modeled in v0. Can be added as a `current` pointer on the registry later without breaking the API.
- Cross-project session sharing: not supported, not modeled.
- Resource limits (memory/CPU caps per session): not modeled.
- Snapshots / checkpointing of session state: not modeled.

## What I Will Not Build Without Confirmation

- Any chat UI.
- Any RPC command surface beyond what session lifecycle needs (e.g. no `prompt`, no `set_model`).
- Any HUD or statusline component.
- Any auto-prompt on save, on test fail, on diagnostic change.
