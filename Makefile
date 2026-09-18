# nvim configuration - automation & hygiene
# Usage: make <target>   (default: help)
#
# VCS policy: this repo tracks config - sources + dotfiles only.
# Runtime state (.artifacts, .cortex, .pi, backups) is gitignored and staged
# away by `make commit`. Never `git add -A`. Commit units explicitly.

SHELL       := bash
NVIM         ?= nvim
STYLUA       ?= stylua
LUA_DIR      := lua

.DEFAULT_GOAL := help

## help        : show this help
.PHONY: help
help:
	@awk '/^## /{title=substr($$0,4)} /^[a-zA-Z0-9][a-zA-Z0-9-]* *:/{t=$$1; sub(/:.*/,"",t); if(t==$$1){t=$$1} sub(/^[^:]*:/,"",$$0); printf "  %-12s %s\n",t,title; title=""}' $(MAKEFILE_LIST)

## check       : stylua fmt-check + headless nvim load smoke test
.PHONY: check
check: fmt-check loadtest

## loadtest    : headless nvim must load with no errors
.PHONY: loadtest
loadtest:
	@LOG=$$(mktemp); timeout 60 $(NVIM) --headless -V1 -c 'qa' 2>$$LOG; \
	if grep -qiE "error|E[0-9]{3}|failed to load|lazy\.lua" $$LOG; then \
		echo "LOAD ERRORS:"; tail -40 $$LOG; rm -f $$LOG; exit 1; \
	else echo "loadtest OK: config starts clean"; fi; rm -f $$LOG

## fmt         : stylua format lua/ in place
.PHONY: fmt
fmt:
	@command -v $(STYLUA) >/dev/null || { echo "install stylua"; exit 2; }
	@$(STYLUA) $(LUA_DIR)

## fmt-check   : report unformatted files (no writes)
.PHONY: fmt-check
fmt-check:
	@command -v $(STYLUA) >/dev/null || { echo "stylua missing (optional)"; exit 0; }
	@$(STYLUA) --check $(LUA_DIR) || { echo ">>> run: make fmt"; exit 1; }

## lint        : luacheck/selene if present, else skip gracefully
.PHONY: lint
lint:
	@if command -v luacheck >/dev/null; then luacheck $(LUA_DIR); \
	elif command -v selene >/dev/null; then selene $(LUA_DIR); \
	else echo "no linter installed (optional)"; fi

## audit       : RSS (resident RAM) of nvim/kitty/langservers, top 25
.PHONY: audit
audit:
	@ps -eo rss,comm,args --width 160 | grep -Ei 'nvim|kitty|clangd|tsserver|lua-language|json-lsp|node' | \
	  grep -v grep | awk '{printf "  %6.1f MB  %s\n",$$1/1024,$$0}' | sort -rn | head -25

## status      : git short status + last 3 commits
.PHONY: status
status:
	@git -C . status --short; echo "..."; git -C . log --oneline -3

## commit[=MSG]: stage tracked edits + Makefile/.gitignore, commit. Usage:
##                make commit MSG="nvim: describe the change"
.PHONY: commit
commit:
	@test -n "$(MSG)" || { echo "use: make commit MSG=\"nvim: ...\""; exit 2; }
	@grep -q '^\.artifacts/' .gitignore && grep -q '^\.cortex/' .gitignore && \
	 grep -q '^\.pi/' .gitignore || { echo ".gitignore missing runtime-state entries"; exit 2; }
	@git -C . add -u && git -C . commit -m "$(MSG)"
	@echo "committed: $(MSG)"

## clean-check : assert no runtime state is tracked
.PHONY: clean-check
clean-check:
	@echo "tracked runtime-state paths (want: none):"
	@git -C . ls-files | grep -Ei '^\.(artifacts|cortex|pi)/' || echo "  none - good"

## sync        : push current branch to origin
.PHONY: sync
sync:
	@git -C . push origin HEAD

## tree        : config layout (top 2 levels)
.PHONY: tree
tree:
	@find . -maxdepth 2 -not -path './.git*' | sort

## log         : recent history
.PHONY: log
log:
	@git -C . log --oneline -12